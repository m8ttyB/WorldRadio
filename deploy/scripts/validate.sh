#!/bin/bash

# Global Radio - Configuration Validation Script
# Validates all deployment configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}✅ Validating Deployment Configuration${NC}"
echo "====================================="

VALIDATION_ERRORS=0

# Function to report validation error
validation_error() {
    echo -e "${RED}❌ $1${NC}"
    ((VALIDATION_ERRORS++))
}

# Function to report validation success
validation_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to report validation warning
validation_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if .env file exists
echo -e "${CYAN}Checking environment configuration...${NC}"
if [ -f "deploy/.env" ]; then
    validation_success "Environment file exists"
    source deploy/.env
else
    validation_error "Environment file (deploy/.env) not found"
    echo "  Create it by copying deploy/.env.example"
fi

# Validate required environment variables
echo -e "${CYAN}Validating environment variables...${NC}"

if [ -n "$RENDER_API_KEY" ]; then
    if [[ "$RENDER_API_KEY" == rnd_* ]]; then
        validation_success "RENDER_API_KEY format is correct"
    else
        validation_error "RENDER_API_KEY format is invalid (should start with 'rnd_')"
    fi
else
    validation_error "RENDER_API_KEY is not set"
fi

if [ -n "$MONGODB_URI" ]; then
    if [[ "$MONGODB_URI" == mongodb* ]]; then
        validation_success "MONGODB_URI format is correct"
    else
        validation_error "MONGODB_URI format is invalid (should start with 'mongodb')"
    fi
else
    validation_error "MONGODB_URI is not set"
fi

if [ -n "$GITHUB_REPO_URL" ]; then
    if [[ "$GITHUB_REPO_URL" == https://github.com/* ]]; then
        validation_success "GITHUB_REPO_URL format is correct"
    else
        validation_error "GITHUB_REPO_URL format is invalid (should be GitHub HTTPS URL)"
    fi
else
    validation_error "GITHUB_REPO_URL is not set"
fi

# Validate optional variables
if [ -n "$APP_NAME" ]; then
    validation_success "APP_NAME is set: $APP_NAME"
else
    validation_warning "APP_NAME is not set (will use default: global-radio)"
fi

if [ -n "$ENVIRONMENT" ]; then
    if [[ "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
        validation_success "ENVIRONMENT is valid: $ENVIRONMENT"
    else
        validation_error "ENVIRONMENT is invalid (must be: development, staging, or production)"
    fi
else
    validation_warning "ENVIRONMENT is not set (will use default: production)"
fi

# Check Terraform configuration
echo -e "${CYAN}Validating Terraform configuration...${NC}"
if [ -f "deploy/terraform/terraform.tfvars" ]; then
    validation_success "Terraform variables file exists"
    
    # Validate Terraform syntax
    if cd deploy/terraform && terraform validate > /dev/null 2>&1; then
        validation_success "Terraform configuration is valid"
    else
        validation_error "Terraform configuration is invalid"
        echo "  Run 'terraform validate' in deploy/terraform/ for details"
    fi
    cd - > /dev/null
else
    validation_error "Terraform variables file not found"
    echo "  Create it by copying deploy/terraform/terraform.tfvars.example"
fi

# Check if Terraform is initialized
echo -e "${CYAN}Checking Terraform initialization...${NC}"
if [ -d "deploy/terraform/.terraform" ]; then
    validation_success "Terraform is initialized"
else
    validation_warning "Terraform is not initialized"
    echo "  Run 'make terraform-init' to initialize"
fi

# Check required tools
echo -e "${CYAN}Checking required tools...${NC}"

if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version | head -n 1 | cut -d' ' -f2)
    validation_success "Terraform is installed: $TERRAFORM_VERSION"
else
    validation_error "Terraform is not installed"
fi

if command -v make &> /dev/null; then
    validation_success "Make is available"
else
    validation_error "Make is not installed"
fi

if command -v curl &> /dev/null; then
    validation_success "curl is available"
else
    validation_error "curl is not installed"
fi

if command -v jq &> /dev/null; then
    validation_success "jq is available"
else
    validation_warning "jq is not installed (recommended for JSON parsing)"
fi

# Check MongoDB connection (if URI is provided)
if [ -n "$MONGODB_URI" ]; then
    echo -e "${CYAN}Testing MongoDB connection...${NC}"
    
    # Try to test connection using a simple method
    if command -v mongosh &> /dev/null || command -v mongo &> /dev/null; then
        validation_success "MongoDB client is available for testing"
    else
        validation_warning "MongoDB client not available for connection testing"
    fi
fi

# Check GitHub repository accessibility
if [ -n "$GITHUB_REPO_URL" ]; then
    echo -e "${CYAN}Checking GitHub repository...${NC}"
    
    if curl -s -o /dev/null -w "%{http_code}" "$GITHUB_REPO_URL" | grep -q "200"; then
        validation_success "GitHub repository is accessible"
    else
        validation_error "GitHub repository is not accessible"
        echo "  Check if the repository URL is correct and public"
    fi
fi

# Check domain configuration (if provided)
if [ -n "$FRONTEND_DOMAIN" ]; then
    echo -e "${CYAN}Checking frontend domain...${NC}"
    validation_success "Frontend domain configured: $FRONTEND_DOMAIN"
fi

if [ -n "$BACKEND_DOMAIN" ]; then
    echo -e "${CYAN}Checking backend domain...${NC}"
    validation_success "Backend domain configured: $BACKEND_DOMAIN"
fi

# Check backend and frontend source files
echo -e "${CYAN}Checking source files...${NC}"

if [ -f "backend/server.py" ]; then
    validation_success "Backend main file exists"
else
    validation_error "Backend main file (backend/server.py) not found"
fi

if [ -f "backend/requirements.txt" ]; then
    validation_success "Backend requirements file exists"
else
    validation_error "Backend requirements file (backend/requirements.txt) not found"
fi

if [ -f "frontend/package.json" ]; then
    validation_success "Frontend package file exists"
else
    validation_error "Frontend package file (frontend/package.json) not found"
fi

if [ -d "frontend/src" ]; then
    validation_success "Frontend source directory exists"
else
    validation_error "Frontend source directory (frontend/src) not found"
fi

# Summary
echo ""
echo "====================================="
if [ $VALIDATION_ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 All validations passed!${NC}"
    echo -e "${GREEN}Configuration is ready for deployment.${NC}"
    exit 0
else
    echo -e "${RED}❌ $VALIDATION_ERRORS validation error(s) found.${NC}"
    echo -e "${YELLOW}Please fix the issues above before deploying.${NC}"
    exit 1
fi