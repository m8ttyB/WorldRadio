# Render.com Configuration
variable "render_api_key" {
  description = "Render.com API key"
  type        = string
  sensitive   = true
}

# Application Configuration
variable "app_name" {
  description = "Application name"
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

# GitHub Configuration
variable "github_repo_url" {
  description = "GitHub repository URL"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to deploy"
  type        = string
  default     = "main"
}

# Database Configuration
variable "mongodb_uri" {
  description = "MongoDB connection URI"
  type        = string
  sensitive   = true
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "global_radio"
}

# Backend Service Configuration
variable "backend_service_name" {
  description = "Backend service name"
  type        = string
  default     = "global-radio-api"
}

variable "backend_plan" {
  description = "Backend service plan"
  type        = string
  default     = "starter"

  validation {
    condition     = contains(["free", "starter", "standard", "pro"], var.backend_plan)
    error_message = "Backend plan must be free, starter, standard, or pro."
  }
}

variable "backend_region" {
  description = "Backend service region"
  type        = string
  default     = "oregon"

  validation {
    condition = contains([
      "oregon", "ohio", "virginia", "frankfurt", "singapore"
    ], var.backend_region)
    error_message = "Backend region must be a valid Render region."
  }
}

variable "backend_instance_count" {
  description = "Number of backend instances"
  type        = number
  default     = 1

  validation {
    condition     = var.backend_instance_count >= 1 && var.backend_instance_count <= 10
    error_message = "Backend instance count must be between 1 and 10."
  }
}

# Frontend Service Configuration
variable "frontend_service_name" {
  description = "Frontend service name"
  type        = string
  default     = "global-radio-web"
}

variable "frontend_publish_path" {
  description = "Frontend build output directory"
  type        = string
  default     = "frontend/build"
}

# Domain Configuration
variable "frontend_domain" {
  description = "Custom domain for frontend (optional)"
  type        = string
  default     = ""
}

variable "backend_domain" {
  description = "Custom domain for backend (optional)"
  type        = string
  default     = ""
}

# Environment Variables
variable "additional_env_vars" {
  description = "Additional environment variables for services"
  type        = map(string)
  default     = {}
  sensitive   = true
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}

variable "notification_email" {
  description = "Email for notifications and alerts"
  type        = string
  default     = ""
}

# Build Configuration
variable "backend_build_command" {
  description = "Backend build command"
  type        = string
  default     = "pip install -r requirements.txt"
}

variable "backend_start_command" {
  description = "Backend start command"
  type        = string
  default     = "uvicorn server:app --host 0.0.0.0 --port $PORT"
}

variable "frontend_build_command" {
  description = "Frontend build command"
  type        = string
  default     = "cd frontend && yarn install && yarn build"
}

# Auto-scaling Configuration
variable "enable_autoscaling" {
  description = "Enable auto-scaling for backend"
  type        = bool
  default     = false
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 3
}

# Health Check Configuration
variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = "/api/"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "Global Radio"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}