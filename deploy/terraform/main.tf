# Global Radio - Render.com Infrastructure

# Backend Web Service
resource "render_web_service" "backend" {
  name         = var.backend_service_name
  plan         = var.backend_plan
  region       = var.backend_region
  runtime      = "python"
  num_replicas = var.backend_instance_count

  repo_url = var.github_repo_url
  branch   = var.github_branch

  root_directory   = "backend"
  build_command    = var.backend_build_command
  start_command    = var.backend_start_command

  # Environment variables
  env_vars = merge({
    ENVIRONMENT  = var.environment
    LOG_LEVEL    = "INFO"
    DEBUG        = "false"
    CORS_ORIGINS = var.frontend_domain != "" ? "https://${var.frontend_domain}" : ""
  }, var.additional_env_vars)

  # Health check
  health_check_path = var.health_check_path

  # Auto-scaling (if enabled and plan supports it)
  dynamic "auto_scaling" {
    for_each = var.enable_autoscaling && var.backend_plan != "free" ? [1] : []
    content {
      min = var.min_instances
      max = var.max_instances
    }
  }

  # Custom domains
  dynamic "custom_domain" {
    for_each = var.backend_domain != "" ? [var.backend_domain] : []
    content {
      name = custom_domain.value
    }
  }
}

# Frontend Static Site
resource "render_static_site" "frontend" {
  name = var.frontend_service_name

  repo_url = var.github_repo_url
  branch   = var.github_branch

  root_directory = "."
  build_command  = var.frontend_build_command
  publish_path   = var.frontend_publish_path

  # Environment variables for build
  env_vars = {
    REACT_APP_BACKEND_URL = var.backend_domain != "" ? "https://${var.backend_domain}" : render_web_service.backend.url
    NODE_VERSION          = "20"
    YARN_VERSION          = "1.22.19"
  }

  # Custom domains
  dynamic "custom_domain" {
    for_each = var.frontend_domain != "" ? [var.frontend_domain] : []
    content {
      name = custom_domain.value
    }
  }

  # Build settings
  pull_request_previews_enabled = var.environment != "production"
}

# Notification settings (if monitoring enabled)
resource "render_notification_setting" "email" {
  count = var.enable_monitoring && var.notification_email != "" ? 1 : 0

  email = var.notification_email
  
  # Notification events
  events = [
    "deploy_started",
    "deploy_succeeded", 
    "deploy_failed",
    "service_suspended",
    "service_resumed"
  ]
}

# Environment Groups for shared configuration
resource "render_env_group" "global_radio" {
  name = "${var.app_name}-config"

  env_vars = {
    APP_NAME    = var.app_name
    ENVIRONMENT = var.environment
    LOG_LEVEL   = "INFO"
  }
}

# Link environment group to backend service
resource "render_env_group_service_link" "backend_env" {
  env_group_id = render_env_group.global_radio.id
  service_id   = render_web_service.backend.id
}

# Redis cache (optional, for advanced caching)
resource "render_redis" "cache" {
  count = var.backend_plan != "free" ? 1 : 0

  name   = "${var.app_name}-cache"
  plan   = "starter"
  region = var.backend_region
}

# Add Redis URL to backend if Redis is enabled
resource "render_env_var" "redis_url" {
  count = var.backend_plan != "free" ? 1 : 0

  service_id = render_web_service.backend.id
  key        = "REDIS_URL"
  value      = render_redis.cache[0].redis_url
}