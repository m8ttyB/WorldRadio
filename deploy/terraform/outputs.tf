# Global Radio - Terraform Outputs

# Service URLs
output "frontend_url" {
  description = "Frontend application URL"
  value       = var.frontend_domain != "" ? "https://${var.frontend_domain}" : render_static_site.frontend.url
}

output "backend_url" {
  description = "Backend API URL"
  value       = var.backend_domain != "" ? "https://${var.backend_domain}" : render_web_service.backend.url
}

output "api_docs_url" {
  description = "API documentation URL"
  value       = "${var.backend_domain != "" ? "https://${var.backend_domain}" : render_web_service.backend.url}/docs"
}

# Service Information
output "backend_service_id" {
  description = "Backend service ID"
  value       = render_web_service.backend.id
}

output "frontend_service_id" {
  description = "Frontend service ID"
  value       = render_static_site.frontend.id
}

output "backend_service_name" {
  description = "Backend service name"
  value       = render_web_service.backend.name
}

output "frontend_service_name" {
  description = "Frontend service name"
  value       = render_static_site.frontend.name
}

# Environment Group
output "env_group_id" {
  description = "Environment group ID"
  value       = render_env_group.global_radio.id
}

# Redis (if enabled)
output "redis_url" {
  description = "Redis connection URL"
  value       = var.backend_plan != "free" ? render_redis.cache[0].redis_url : null
  sensitive   = true
}

# Deployment Information
output "deployment_info" {
  description = "Deployment information"
  value = {
    app_name          = var.app_name
    environment       = var.environment
    backend_plan      = var.backend_plan
    backend_region    = var.backend_region
    backend_instances = var.backend_instance_count
    github_repo       = var.github_repo_url
    github_branch     = var.github_branch
    deployed_at       = timestamp()
  }
}

# Custom Domains
output "custom_domains" {
  description = "Custom domain configuration"
  value = {
    frontend = var.frontend_domain
    backend  = var.backend_domain
  }
}

# Resource Summary
output "resource_summary" {
  description = "Summary of deployed resources"
  value = {
    web_services   = 1
    static_sites   = 1
    env_groups     = 1
    redis_instances = var.backend_plan != "free" ? 1 : 0
    custom_domains = (var.frontend_domain != "" ? 1 : 0) + (var.backend_domain != "" ? 1 : 0)
  }
}

# Health Check URLs
output "health_check_urls" {
  description = "Health check endpoints"
  value = {
    backend_health = "${var.backend_domain != "" ? "https://${var.backend_domain}" : render_web_service.backend.url}/api/"
    frontend_health = var.frontend_domain != "" ? "https://${var.frontend_domain}" : render_static_site.frontend.url
  }
}

# Monitoring Information
output "monitoring_info" {
  description = "Monitoring and alerting information"
  value = {
    monitoring_enabled = var.enable_monitoring
    notification_email = var.notification_email
    autoscaling_enabled = var.enable_autoscaling
    min_instances = var.min_instances
    max_instances = var.max_instances
  }
}

# Build Information
output "build_info" {
  description = "Build configuration information"
  value = {
    backend_build_command = var.backend_build_command
    backend_start_command = var.backend_start_command
    frontend_build_command = var.frontend_build_command
    frontend_publish_path = var.frontend_publish_path
  }
}