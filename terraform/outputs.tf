# Global Radio - Terraform Outputs

# App Platform URLs
output "app_url" {
  description = "URL of the deployed application"
  value       = digitalocean_app.global_radio.live_url
}

output "backend_url" {
  description = "URL of the backend service"
  value       = "${digitalocean_app.global_radio.live_url}/api"
}

# Database Information
output "database_host" {
  description = "Database host"
  value       = digitalocean_database_cluster.mongodb.host
  sensitive   = true
}

output "database_port" {
  description = "Database port"
  value       = digitalocean_database_cluster.mongodb.port
}

output "database_user" {
  description = "Database username"
  value       = digitalocean_database_user.app_user.name
  sensitive   = true
}

output "database_password" {
  description = "Database password"
  value       = digitalocean_database_user.app_user.password
  sensitive   = true
}

output "database_connection_string" {
  description = "MongoDB connection string"
  value       = "mongodb://${digitalocean_database_user.app_user.name}:${digitalocean_database_user.app_user.password}@${digitalocean_database_cluster.mongodb.private_host}:${digitalocean_database_cluster.mongodb.port}/${digitalocean_database_db.app_db.name}"
  sensitive   = true
}

# Project Information
output "project_id" {
  description = "Project ID"
  value       = digitalocean_project.global_radio.id
}

output "app_id" {
  description = "App Platform application ID"
  value       = digitalocean_app.global_radio.id
}

# Custom Domains (if configured)
output "frontend_domain" {
  description = "Frontend custom domain"
  value       = var.custom_domain != "" ? digitalocean_app_domain.frontend_domain[0].name : null
}

output "backend_domain" {
  description = "Backend custom domain"
  value       = var.backend_domain != "" ? digitalocean_app_domain.backend_domain[0].name : null
}

# Resource URNs (for reference)
output "database_urn" {
  description = "Database cluster URN"
  value       = digitalocean_database_cluster.mongodb.urn
}

output "app_urn" {
  description = "App Platform URN"
  value       = digitalocean_app.global_radio.urn
}

# Environment Information
output "deployment_info" {
  description = "Deployment information"
  value = {
    project_name = var.project_name
    environment  = var.environment
    region       = var.region
    deployed_at  = timestamp()
  }
}