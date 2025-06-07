# Global Radio - Digital Ocean Droplets Infrastructure
# Alternative deployment using Droplets instead of App Platform

terraform {
  required_version = ">= 1.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.34"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# SSH Key
data "digitalocean_ssh_key" "main" {
  name = var.ssh_key_name
}

# Create VPC
resource "digitalocean_vpc" "main" {
  name     = "${var.project_name}-vpc"
  region   = var.region
  ip_range = "10.10.0.0/16"
}

# Create Load Balancer
resource "digitalocean_loadbalancer" "main" {
  name   = "${var.project_name}-lb"
  region = var.region
  vpc_uuid = digitalocean_vpc.main.id

  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 80
    target_protocol = "http"
    target_port     = 80
  }

  forwarding_rule {
    entry_protocol  = "https"
    entry_port      = 443
    target_protocol = "http"
    target_port     = 80
    tls_passthrough = false
  }

  healthcheck {
    protocol               = "http"
    port                   = 80
    path                   = "/api/"
    check_interval_seconds = 10
    response_timeout_seconds = 5
    unhealthy_threshold    = 3
    healthy_threshold      = 2
  }

  droplet_ids = digitalocean_droplet.app[*].id
}

# Create Droplets for the application
resource "digitalocean_droplet" "app" {
  count  = var.droplet_count
  image  = "ubuntu-20-04-x64"
  name   = "${var.project_name}-app-${count.index + 1}"
  region = var.region
  size   = var.droplet_size
  vpc_uuid = digitalocean_vpc.main.id
  ssh_keys = [data.digitalocean_ssh_key.main.id]

  user_data = templatefile("${path.module}/user_data.sh", {
    mongo_url     = "mongodb://${digitalocean_database_user.app_user.name}:${digitalocean_database_user.app_user.password}@${digitalocean_database_cluster.mongodb.private_host}:${digitalocean_database_cluster.mongodb.port}/${digitalocean_database_db.app_db.name}"
    db_name       = var.database_name
    github_repo   = var.github_repo
    github_branch = var.github_branch
    backend_url   = "https://${var.custom_domain != "" ? var.custom_domain : digitalocean_loadbalancer.main.ip}"
  })

  tags = [
    "environment:${var.environment}",
    "project:${var.project_name}",
    "role:app"
  ]
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

resource "digitalocean_database_db" "app_db" {
  cluster_id = digitalocean_database_cluster.mongodb.id
  name       = var.database_name
}

resource "digitalocean_database_user" "app_user" {
  cluster_id = digitalocean_database_cluster.mongodb.id
  name       = var.database_user
}

# Firewall for droplets
resource "digitalocean_firewall" "app" {
  name = "${var.project_name}-app-firewall"

  droplet_ids = digitalocean_droplet.app[*].id

  # SSH
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.trusted_ips
  }

  # HTTP
  inbound_rule {
    protocol                = "tcp"
    port_range             = "80"
    source_load_balancer_uids = [digitalocean_loadbalancer.main.id]
  }

  # HTTPS
  inbound_rule {
    protocol                = "tcp"
    port_range             = "443"
    source_load_balancer_uids = [digitalocean_loadbalancer.main.id]
  }

  # Backend API
  inbound_rule {
    protocol                = "tcp"
    port_range             = "8001"
    source_load_balancer_uids = [digitalocean_loadbalancer.main.id]
  }

  # Frontend
  inbound_rule {
    protocol                = "tcp"
    port_range             = "3000"
    source_load_balancer_uids = [digitalocean_loadbalancer.main.id]
  }

  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range           = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range           = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# Database firewall
resource "digitalocean_database_firewall" "mongodb_fw" {
  cluster_id = digitalocean_database_cluster.mongodb.id

  dynamic "rule" {
    for_each = digitalocean_droplet.app[*].ipv4_address_private
    content {
      type  = "ip_addr"
      value = rule.value
    }
  }

  dynamic "rule" {
    for_each = var.trusted_ips
    content {
      type  = "ip_addr"
      value = rule.value
    }
  }
}

# Create domain and DNS records
resource "digitalocean_domain" "main" {
  count = var.custom_domain != "" ? 1 : 0
  name  = var.custom_domain
}

resource "digitalocean_record" "main" {
  count  = var.custom_domain != "" ? 1 : 0
  domain = digitalocean_domain.main[0].name
  type   = "A"
  name   = "@"
  value  = digitalocean_loadbalancer.main.ip
  ttl    = 300
}

resource "digitalocean_record" "www" {
  count  = var.custom_domain != "" ? 1 : 0
  domain = digitalocean_domain.main[0].name
  type   = "CNAME"
  name   = "www"
  value  = var.custom_domain
  ttl    = 300
}

resource "digitalocean_record" "api" {
  count  = var.custom_domain != "" ? 1 : 0
  domain = digitalocean_domain.main[0].name
  type   = "CNAME"
  name   = "api"
  value  = var.custom_domain
  ttl    = 300
}

# Create project
resource "digitalocean_project" "main" {
  name        = var.project_name
  description = "Global Radio streaming application - Droplets deployment"
  purpose     = "Web Application"
  environment = var.environment

  resources = concat(
    digitalocean_droplet.app[*].urn,
    [
      digitalocean_database_cluster.mongodb.urn,
      digitalocean_loadbalancer.main.urn
    ]
  )
}

# Volume for persistent storage (optional)
resource "digitalocean_volume" "app_data" {
  count                   = var.enable_persistent_storage ? var.droplet_count : 0
  region                  = var.region
  name                    = "${var.project_name}-data-${count.index + 1}"
  size                    = var.volume_size
  initial_filesystem_type = "ext4"
  description            = "Persistent storage for Global Radio app"

  tags = [
    "environment:${var.environment}",
    "project:${var.project_name}"
  ]
}

resource "digitalocean_volume_attachment" "app_data" {
  count      = var.enable_persistent_storage ? var.droplet_count : 0
  droplet_id = digitalocean_droplet.app[count.index].id
  volume_id  = digitalocean_volume.app_data[count.index].id
}