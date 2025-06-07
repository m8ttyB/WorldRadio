# 🚀 Global Radio - Terraform Infrastructure as Code

This directory contains Terraform configurations for deploying the Global Radio application to Digital Ocean using Infrastructure as Code (IaC).

## 📁 Directory Structure

```
terraform/
├── main.tf                    # App Platform deployment (main)
├── variables.tf              # Variable definitions
├── outputs.tf               # Output definitions
├── versions.tf              # Provider version constraints
├── terraform.tfvars.example # Example configuration file
├── deploy.sh               # Deployment script
├── destroy.sh              # Destruction script
├── droplets/               # Alternative Droplets deployment
│   ├── main.tf            # Droplets infrastructure
│   ├── variables.tf       # Droplets-specific variables
│   ├── outputs.tf         # Droplets outputs
│   └── user_data.sh       # Droplet initialization script
└── README.md              # This file
```

## 🎯 Deployment Options

### Option 1: App Platform (Recommended)
- **Managed service** - Digital Ocean handles infrastructure
- **Auto-scaling** - Scales based on demand
- **Zero maintenance** - Fully managed
- **Cost-effective** - Pay for what you use

### Option 2: Droplets (VPS)
- **Full control** - Complete server access
- **Customizable** - Custom configurations
- **Load balanced** - Multiple droplets with load balancer
- **Persistent storage** - Optional volume attachments

## 🛠️ Prerequisites

1. **Digital Ocean Account** with billing enabled
2. **Digital Ocean API Token** with read/write permissions
3. **Terraform** installed (>= 1.0)
4. **SSH Key** uploaded to Digital Ocean
5. **GitHub Repository** with your code

### Install Terraform

```bash
# macOS (using Homebrew)
brew install terraform

# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify installation
terraform version
```

## ⚙️ Configuration

### 1. Create Configuration File

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

### 2. Required Configuration

**Essential Variables:**
```hcl
# Digital Ocean API token
do_token = "dop_v1_your_token_here"

# SSH key name (must exist in Digital Ocean)
ssh_key_name = "your-ssh-key"

# GitHub repository
github_repo = "yourusername/global-radio"

# Alert email
alert_email = "admin@yourdomain.com"
```

**Optional Variables:**
```hcl
# Custom domains
custom_domain = "radio.yourdomain.com"
backend_domain = "api.radio.yourdomain.com"

# Environment
environment = "production"  # or "staging", "development"

# Region
region = "nyc1"  # or "ams3", "sfo3", etc.

# Instance sizes (App Platform only)
backend_instance_size = "basic-xxs"  # or "basic-xs", "basic-s"
backend_instance_count = 1

# Database configuration
database_size = "db-s-1vcpu-1gb"
database_node_count = 1

# Security
trusted_ips = [
  "203.0.113.0/24",  # Your office network
  "198.51.100.1/32"  # Your home IP
]
```

## 🚀 Deployment

### Quick Start (App Platform)

```bash
# Deploy using the automated script
./deploy.sh

# Or deploy manually
terraform init
terraform plan
terraform apply
```

### Droplets Deployment

```bash
# Deploy to Droplets instead of App Platform
./deploy.sh droplets

# Or manually
cd droplets
cp ../terraform.tfvars .
terraform init
terraform plan
terraform apply
```

### Manual Deployment Steps

```bash
# 1. Initialize Terraform
terraform init

# 2. Validate configuration
terraform validate

# 3. Plan deployment
terraform plan -out=tfplan

# 4. Review the plan and apply
terraform apply tfplan

# 5. View outputs
terraform output
```

## 📊 Monitoring Deployment

### Check Deployment Status

```bash
# View all outputs
terraform output

# Check specific outputs
terraform output app_url
terraform output database_host

# View current state
terraform show

# Check resource status in Digital Ocean dashboard
```

### Health Checks

```bash
# App Platform deployment
curl $(terraform output -raw app_url)/api/

# Droplets deployment
curl $(terraform output -raw load_balancer_ip)/health
```

## 🔧 Configuration Options

### Environment-Specific Configurations

Create separate `.tfvars` files for different environments:

```bash
# terraform.prod.tfvars
environment = "production"
backend_instance_count = 2
database_node_count = 2

# terraform.staging.tfvars
environment = "staging"
backend_instance_count = 1
database_node_count = 1

# Deploy to specific environment
terraform apply -var-file="terraform.staging.tfvars"
```

### Scaling Configuration

**App Platform Scaling:**
```hcl
backend_instance_count = 3  # Scale to 3 instances
backend_instance_size = "basic-s"  # Upgrade instance size
```

**Droplets Scaling:**
```hcl
droplet_count = 3  # Scale to 3 droplets
droplet_size = "s-2vcpu-4gb"  # Upgrade droplet size
```

### Security Configuration

```hcl
# Restrict database access
trusted_ips = [
  "10.0.0.0/8",      # Private networks only
  "192.168.1.0/24"   # Specific subnet
]

# Enable additional security features
enable_backups = true
```

## 🗂️ State Management

### Local State (Default)
State is stored locally in `terraform.tfstate`. **Not recommended for production.**

### Remote State (Recommended)
Configure remote state for team collaboration:

```hcl
# In versions.tf
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "global-radio/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## 📈 Outputs Reference

### App Platform Outputs
- `app_url` - Main application URL
- `backend_url` - Backend API URL
- `database_host` - Database connection host
- `database_connection_string` - Full MongoDB connection string

### Droplets Outputs
- `load_balancer_ip` - Load balancer public IP
- `droplet_ips` - Individual droplet IPs
- `app_url` - Application URL (load balancer)
- `ssh_commands` - SSH commands for each droplet

## 🔄 Updates and Maintenance

### Updating Infrastructure

```bash
# Pull latest Terraform configuration
git pull

# Plan updates
terraform plan

# Apply updates
terraform apply
```

### Updating Application Code

**App Platform:** Automatic deployment when you push to the configured branch.

**Droplets:** Manual deployment required:
```bash
# SSH to droplets and pull updates
ssh root@$(terraform output -raw droplet_ips | jq -r '.[0]')
cd /opt/global-radio
git pull
systemctl restart global-radio-backend
```

### Database Maintenance

```bash
# View database information
terraform output database_host
terraform output database_connection_string

# Connect to database (requires whitelisted IP)
mongo $(terraform output -raw database_connection_string)
```

## 🗑️ Cleanup

### Destroy Infrastructure

```bash
# Using the destroy script (recommended)
./destroy.sh

# Or manually
terraform destroy
```

**⚠️ Warning:** This permanently deletes all resources and data!

### Partial Cleanup

```bash
# Remove specific resources
terraform destroy -target=digitalocean_droplet.app

# Remove and recreate specific resources
terraform taint digitalocean_app.global_radio
terraform apply
```

## 🔍 Troubleshooting

### Common Issues

1. **Authentication Errors**
   ```bash
   # Check API token
   export DIGITALOCEAN_TOKEN="your_token_here"
   doctl auth init
   ```

2. **SSH Key Not Found**
   ```bash
   # List available SSH keys
   doctl compute ssh-key list
   
   # Update ssh_key_name in terraform.tfvars
   ```

3. **Resource Already Exists**
   ```bash
   # Import existing resource
   terraform import digitalocean_domain.main yourdomain.com
   ```

4. **State Lock Issues**
   ```bash
   # Force unlock (use with caution)
   terraform force-unlock LOCK_ID
   ```

### Debug Mode

```bash
# Enable detailed logging
export TF_LOG=DEBUG
terraform apply

# Or for specific operations
TF_LOG=INFO terraform plan
```

### Validation

```bash
# Validate configuration
terraform validate

# Format configuration
terraform fmt -recursive

# Check for security issues (if using tfsec)
tfsec .
```

## 📚 Advanced Usage

### Custom Modules

Create reusable modules:

```hcl
# modules/global-radio/main.tf
module "global_radio" {
  source = "./modules/global-radio"
  
  project_name = var.project_name
  environment  = var.environment
  # ... other variables
}
```

### Multiple Environments

```bash
# Workspace-based environments
terraform workspace new production
terraform workspace new staging

# Deploy to specific workspace
terraform workspace select production
terraform apply
```

### Automated Deployment

Integrate with CI/CD:

```yaml
# .github/workflows/deploy.yml
name: Deploy Infrastructure
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: hashicorp/setup-terraform@v1
      - name: Deploy
        run: |
          cd terraform
          terraform init
          terraform apply -auto-approve
        env:
          DIGITALOCEAN_TOKEN: ${{ secrets.DO_TOKEN }}
```

## 📞 Support

- **Terraform Issues**: [Terraform Documentation](https://www.terraform.io/docs)
- **Digital Ocean Provider**: [DO Terraform Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
- **Digital Ocean API**: [DO API Documentation](https://docs.digitalocean.com/reference/api/)

---

**Happy Infrastructure Coding! 🚀🏗️**