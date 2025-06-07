# Global Radio - Digital Ocean Infrastructure as Code
# This configuration deploys the Global Radio application to Digital Ocean App Platform

terraform {
  required_version = ">= 1.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# Data source for SSH key (if needed for droplets)
data "digitalocean_ssh_key" "main" {
  name = var.ssh_key_name
}

# Create MongoDB Database
resource "digitalocean_database_cluster" "mongodb" {
  name       = "${var.project_name}-mongodb"
  engine     = "mongodb"
  version    = "6"
  size       = var.database_size
  region     = var.region
  node_count = var.database_node_count

  tags = [
    "environment:${var.environment}",
    "project:${var.project_name}"
  ]
}

# Create database
resource "digitalocean_database_db" "app_db" {
  cluster_id = digitalocean_database_cluster.mongodb.id
  name       = var.database_name
}

# Create database user
resource "digitalocean_database_user" "app_user" {
  cluster_id = digitalocean_database_cluster.mongodb.id
  name       = var.database_user
}

# Create App Platform application
resource "digitalocean_app" "global_radio" {
  spec {
    name   = var.project_name
    region = var.region

    # Backend service
    service {
      name               = "backend"
      environment_slug   = "python"
      instance_count     = var.backend_instance_count
      instance_size_slug = var.backend_instance_size
      http_port          = 8001

      github {
        repo           = var.github_repo
        branch         = var.github_branch
        deploy_on_push = true
      }

      source_dir = "/backend"

      run_command = "uvicorn server:app --host 0.0.0.0 --port $PORT"

      env {
        key   = "MONGO_URL"
        value = "mongodb://${digitalocean_database_user.app_user.name}:${digitalocean_database_user.app_user.password}@${digitalocean_database_cluster.mongodb.private_host}:${digitalocean_database_cluster.mongodb.port}/${digitalocean_database_db.app_db.name}"
        scope = "RUN_AND_BUILD_TIME"
        type  = "SECRET"
      }

      env {
        key   = "DB_NAME"
        value = var.database_name
        scope = "RUN_AND_BUILD_TIME"
      }

      env {
        key   = "ENVIRONMENT"
        value = var.environment
        scope = "RUN_AND_BUILD_TIME"
      }

      env {
        key   = "LOG_LEVEL"
        value = "INFO"
        scope = "RUN_AND_BUILD_TIME"
      }

      health_check {
        http_path             = "/api/"
        initial_delay_seconds = 30
        period_seconds        = 10
        timeout_seconds       = 5
        success_threshold     = 1
        failure_threshold     = 3
      }
    }

    # Frontend static site
    static_site {
      name         = "frontend"
      build_command = "yarn install && yarn build"
      output_dir   = "build"

      github {
        repo           = var.github_repo
        branch         = var.github_branch
        deploy_on_push = true
      }

      source_dir = "/frontend"

      env {
        key   = "REACT_APP_BACKEND_URL"
        value = "https://${var.project_name}-backend.ondigitalocean.app"
        scope = "BUILD_TIME"
      }

      env {
        key   = "NODE_VERSION"
        value = "18"
        scope = "BUILD_TIME"
      }
    }

    # Database configuration
    database {
      name       = digitalocean_database_cluster.mongodb.name
      engine     = "MONGODB"
      production = var.environment == "production" ? true : false
    }
  }
}

# Create custom domain (optional)
resource "digitalocean_app_domain" "frontend_domain" {
  count  = var.custom_domain != "" ? 1 : 0
  app_id = digitalocean_app.global_radio.id
  name   = var.custom_domain
  type   = "PRIMARY"
}

resource "digitalocean_app_domain" "backend_domain" {
  count  = var.backend_domain != "" ? 1 : 0
  app_id = digitalocean_app.global_radio.id
  name   = var.backend_domain
  type   = "ALIAS"
}

# Create monitoring alerts
resource "digitalocean_monitor_alert" "cpu_alert" {
  alerts {
    email = [var.alert_email]
  }
  window      = "5m"
  type        = "v1/insights/droplet/cpu"
  compare     = "GreaterThan"
  value       = 80
  enabled     = true
  entities    = [digitalocean_app.global_radio.id]
  description = "CPU usage is above 80%"
}

resource "digitalocean_monitor_alert" "memory_alert" {
  alerts {
    email = [var.alert_email]
  }
  window      = "5m"
  type        = "v1/insights/droplet/memory_utilization_percent"
  compare     = "GreaterThan"
  value       = 85
  enabled     = true
  entities    = [digitalocean_app.global_radio.id]
  description = "Memory usage is above 85%"
}

# Create project to organize resources
resource "digitalocean_project" "global_radio" {
  name        = var.project_name
  description = "Global Radio streaming application"
  purpose     = "Web Application"
  environment = var.environment

  resources = [
    digitalocean_app.global_radio.urn,
    digitalocean_database_cluster.mongodb.urn
  ]
}

# Create firewall rules for database
resource "digitalocean_database_firewall" "mongodb_fw" {
  cluster_id = digitalocean_database_cluster.mongodb.id

  rule {
    type  = "app"
    value = digitalocean_app.global_radio.id
  }

  # Allow access from trusted IPs if specified
  dynamic "rule" {
    for_each = var.trusted_ips
    content {
      type  = "ip_addr"
      value = rule.value
    }
  }
}

# Create backup policy for database
resource "digitalocean_database_cluster" "mongodb_backup" {
  count = var.enable_backups ? 1 : 0

  name       = "${var.project_name}-mongodb-backup"
  engine     = "mongodb"
  version    = "6"
  size       = var.database_size
  region     = var.region
  node_count = 1

  backup_restore {
    database_name     = digitalocean_database_cluster.mongodb.database
    backup_created_at = "2024-01-01T00:00:00Z"
  }

  tags = [
    "environment:${var.environment}",
    "project:${var.project_name}",
    "type:backup"
  ]
}