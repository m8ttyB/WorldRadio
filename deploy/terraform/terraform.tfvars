# Global Radio - Terraform Variables
# Copy this file to terraform.tfvars and update with your values

# Render.com Configuration
render_api_key = ""

# Application Configuration
app_name    = "global-radio"
environment = "production"

# GitHub Configuration
github_repo_url = "https://github.com/m8ttyB/WorldRadio.git"
github_branch   = "main"

# Database Configuration (MongoDB Atlas)
mongodb_uri   = "mongodb+srv://username:password@cluster.mongodb.net/global_radio"
database_name = "global_radio"

# Backend Service Configuration
backend_service_name  = "global-radio-api"
backend_plan         = "starter"  # free, starter, standard, pro
backend_region       = "oregon"   # oregon, ohio, virginia, frankfurt, singapore
backend_instance_count = 1

# Frontend Service Configuration
frontend_service_name = "global-radio-web"
frontend_publish_path = "frontend/build"

# Custom Domains (optional)
frontend_domain = ""  # e.g., "radio.yourdomain.com"
backend_domain  = ""  # e.g., "api.radio.yourdomain.com"

# Build Configuration
backend_build_command  = "pip install -r requirements.txt"
backend_start_command  = "uvicorn server:app --host 0.0.0.0 --port $PORT"
frontend_build_command = "cd frontend && yarn install && yarn build"

# Monitoring Configuration
enable_monitoring  = true
notification_email = "admin@yourdomain.com"

# Auto-scaling Configuration (requires paid plan)
enable_autoscaling = false
min_instances     = 1
max_instances     = 3

# Health Check Configuration
health_check_path     = "/api/"
health_check_interval = 30

# Additional Environment Variables
additional_env_vars = {
  # Add any additional environment variables here
  # API_KEY = "your-api-key"
  # FEATURE_FLAG = "enabled"
}

# Tags
tags = {
  Project     = "Global Radio"
  Environment = "Production"
  Owner       = "Your Name"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}