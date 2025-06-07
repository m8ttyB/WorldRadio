# Global Radio Droplets - Terraform Variables

# Digital Ocean Configuration
variable "do_token" {
  description = "Digital Ocean API token"
  type        = string
  sensitive   = true
}

variable "ssh_key_name" {
  description = "Name of the SSH key in Digital Ocean"
  type        = string
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
}

variable "region" {
  description = "Digital Ocean region"
  type        = string
  default     = "nyc1"
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

# Droplet Configuration
variable "droplet_count" {
  description = "Number of app droplets"
  type        = number
  default     = 2

  validation {
    condition     = var.droplet_count >= 1 && var.droplet_count <= 10
    error_message = "Droplet count must be between 1 and 10."
  }
}

variable "droplet_size" {
  description = "Size of the droplets"
  type        = string
  default     = "s-2vcpu-2gb"

  validation {
    condition = contains([
      "s-1vcpu-1gb", "s-1vcpu-2gb", "s-2vcpu-2gb", "s-2vcpu-4gb",
      "s-4vcpu-8gb", "s-6vcpu-16gb", "s-8vcpu-32gb"
    ], var.droplet_size)
    error_message = "Droplet size must be a valid Digital Ocean size."
  }
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
}

variable "database_node_count" {
  description = "Number of database nodes"
  type        = number
  default     = 1
}

# Domain Configuration
variable "custom_domain" {
  description = "Custom domain for the application"
  type        = string
  default     = ""
}

# Security Configuration
variable "trusted_ips" {
  description = "List of trusted IP addresses for SSH and database access"
  type        = list(string)
  default     = []
}

# Storage Configuration
variable "enable_persistent_storage" {
  description = "Enable persistent volume storage"
  type        = bool
  default     = false
}

variable "volume_size" {
  description = "Size of persistent volumes in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.volume_size >= 1 && var.volume_size <= 16384
    error_message = "Volume size must be between 1 and 16384 GB."
  }
}