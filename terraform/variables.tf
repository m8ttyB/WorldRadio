# Global Radio - Terraform Variables

# Digital Ocean Configuration
variable "do_token" {
  description = "Digital Ocean API token"
  type        = string
  sensitive   = true
}

variable "ssh_key_name" {
  description = "Name of the SSH key in Digital Ocean"
  type        = string
  default     = "default"
}

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "global-radio"
}

variable "environment" {
  description = "Environment (development, staging, production)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "region" {
  description = "Digital Ocean region"
  type        = string
  default     = "nyc1"

  validation {
    condition = contains([
      "nyc1", "nyc3", "ams3", "sfo3", "sgp1", "lon1",
      "fra1", "tor1", "blr1", "syd1"
    ], var.region)
    error_message = "Region must be a valid Digital Ocean region."
  }
}

# GitHub Configuration
variable "github_repo" {
  description = "GitHub repository (username/repo-name)"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to deploy"
  type        = string
  default     = "main"
}

# Database Configuration
variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "global_radio"
}

variable "database_user" {
  description = "Database username"
  type        = string
  default     = "app_user"
}

variable "database_size" {
  description = "Size of the database cluster"
  type        = string
  default     = "db-s-1vcpu-1gb"

  validation {
    condition = contains([
      "db-s-1vcpu-1gb", "db-s-1vcpu-2gb", "db-s-2vcpu-4gb",
      "db-s-4vcpu-8gb", "db-s-6vcpu-16gb"
    ], var.database_size)
    error_message = "Database size must be a valid Digital Ocean database size."
  }
}

variable "database_node_count" {
  description = "Number of database nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.database_node_count >= 1 && var.database_node_count <= 3
    error_message = "Database node count must be between 1 and 3."
  }
}

# Backend Configuration
variable "backend_instance_count" {
  description = "Number of backend instances"
  type        = number
  default     = 1

  validation {
    condition     = var.backend_instance_count >= 1 && var.backend_instance_count <= 10
    error_message = "Backend instance count must be between 1 and 10."
  }
}

variable "backend_instance_size" {
  description = "Size of backend instances"
  type        = string
  default     = "basic-xxs"

  validation {
    condition = contains([
      "basic-xxs", "basic-xs", "basic-s", "basic-m",
      "professional-xs", "professional-s", "professional-m"
    ], var.backend_instance_size)
    error_message = "Backend instance size must be a valid Digital Ocean App Platform size."
  }
}

# Domain Configuration
variable "custom_domain" {
  description = "Custom domain for the frontend (optional)"
  type        = string
  default     = ""
}

variable "backend_domain" {
  description = "Custom domain for the backend API (optional)"
  type        = string
  default     = ""
}

# Monitoring Configuration
variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string
}

variable "trusted_ips" {
  description = "List of trusted IP addresses for database access"
  type        = list(string)
  default     = []
}

# Backup Configuration
variable "enable_backups" {
  description = "Enable database backups"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}