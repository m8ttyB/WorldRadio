# Global Radio Droplets - Terraform Outputs

# Load Balancer
output "load_balancer_ip" {
  description = "Load balancer public IP"
  value       = digitalocean_loadbalancer.main.ip
}

output "load_balancer_status" {
  description = "Load balancer status"
  value       = digitalocean_loadbalancer.main.status
}

# Droplets
output "droplet_ips" {
  description = "Public IP addresses of app droplets"
  value       = digitalocean_droplet.app[*].ipv4_address
}

output "droplet_private_ips" {
  description = "Private IP addresses of app droplets"
  value       = digitalocean_droplet.app[*].ipv4_address_private
}

output "droplet_names" {
  description = "Names of app droplets"
  value       = digitalocean_droplet.app[*].name
}

# Database
output "database_host" {
  description = "Database host"
  value       = digitalocean_database_cluster.mongodb.host
  sensitive   = true
}

output "database_private_host" {
  description = "Database private host"
  value       = digitalocean_database_cluster.mongodb.private_host
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

# Domain
output "domain_name" {
  description = "Domain name (if configured)"
  value       = var.custom_domain != "" ? digitalocean_domain.main[0].name : null
}

output "app_url" {
  description = "Application URL"
  value       = var.custom_domain != "" ? "https://${var.custom_domain}" : "http://${digitalocean_loadbalancer.main.ip}"
}

output "api_url" {
  description = "API URL"
  value       = var.custom_domain != "" ? "https://api.${var.custom_domain}" : "http://${digitalocean_loadbalancer.main.ip}/api"
}

# Project
output "project_id" {
  description = "Project ID"
  value       = digitalocean_project.main.id
}

# SSH Commands
output "ssh_commands" {
  description = "SSH commands to connect to droplets"
  value = [
    for i, droplet in digitalocean_droplet.app : "ssh root@${droplet.ipv4_address}"
  ]
}

# Monitoring
output "health_check_urls" {
  description = "Health check URLs"
  value = {
    load_balancer = "http://${digitalocean_loadbalancer.main.ip}/health"
    api           = "http://${digitalocean_loadbalancer.main.ip}/api/"
  }
}

# Volume information (if enabled)
output "volume_info" {
  description = "Volume information"
  value = var.enable_persistent_storage ? {
    volume_ids   = digitalocean_volume.app_data[*].id
    volume_names = digitalocean_volume.app_data[*].name
    mount_points = [for i in range(var.droplet_count) : "/mnt/app-data-${i + 1}"]
  } : null
}