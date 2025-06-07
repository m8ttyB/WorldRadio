terraform {
  required_version = ">= 1.0"
  
  required_providers {
    render = {
      source  = "render-oss/render"
      version = "~> 1.0"
    }
  }

  # Optional: Configure remote state backend
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "global-radio/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "render" {
  api_key = var.render_api_key
}