#!/bin/bash

# Global Radio - Terraform Deployment Script
# This script deploys the Global Radio application to Digital Ocean using Terraform

set -e

# Configuration
TERRAFORM_DIR="$(dirname "$0")"
DEPLOYMENT_TYPE=${1:-"app-platform"}  # app-platform or droplets
ENVIRONMENT=${2:-"production"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if jq is installed (for parsing JSON output)
    if ! command -v jq &> /dev/null; then
        log_warning "jq is not installed. Some features may not work properly."
    fi
    
    # Check if terraform.tfvars exists
    if [[ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]]; then
        log_error "terraform.tfvars not found. Please copy terraform.tfvars.example and configure it."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

validate_config() {
    log_info "Validating configuration..."
    
    cd "$TERRAFORM_DIR"
    
    if [[ "$DEPLOYMENT_TYPE" == "droplets" ]]; then
        cd droplets
    fi
    
    terraform validate
    
    if [[ $? -eq 0 ]]; then
        log_success "Configuration validation passed"
    else
        log_error "Configuration validation failed"
        exit 1
    fi
}

plan_deployment() {
    log_info "Planning deployment..."
    
    cd "$TERRAFORM_DIR"
    
    if [[ "$DEPLOYMENT_TYPE" == "droplets" ]]; then
        cd droplets
        cp ../terraform.tfvars .
    fi
    
    terraform init
    terraform plan -out=tfplan
    
    log_info "Terraform plan completed. Review the changes above."
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deployment cancelled"
        exit 0
    fi
}

deploy() {
    log_info "Starting deployment..."
    
    terraform apply tfplan
    
    if [[ $? -eq 0 ]]; then
        log_success "Deployment completed successfully!"
    else
        log_error "Deployment failed"
        exit 1
    fi
}

show_outputs() {
    log_info "Deployment outputs:"
    terraform output
    
    # Save outputs to file
    terraform output -json > outputs.json
    log_info "Outputs saved to outputs.json"
    
    # Extract and display key information
    if command -v jq &> /dev/null; then
        echo
        log_info "Quick access information:"
        
        if [[ "$DEPLOYMENT_TYPE" == "app-platform" ]]; then
            APP_URL=$(terraform output -json | jq -r '.app_url.value // empty')
            BACKEND_URL=$(terraform output -json | jq -r '.backend_url.value // empty')
            
            if [[ -n "$APP_URL" ]]; then
                echo "🌐 Application URL: $APP_URL"
            fi
            if [[ -n "$BACKEND_URL" ]]; then
                echo "🔌 Backend API URL: $BACKEND_URL"
            fi
        else
            LOAD_BALANCER_IP=$(terraform output -json | jq -r '.load_balancer_ip.value // empty')
            APP_URL=$(terraform output -json | jq -r '.app_url.value // empty')
            
            if [[ -n "$LOAD_BALANCER_IP" ]]; then
                echo "🔗 Load Balancer IP: $LOAD_BALANCER_IP"
            fi
            if [[ -n "$APP_URL" ]]; then
                echo "🌐 Application URL: $APP_URL"
            fi
        fi
    fi
}

perform_health_check() {
    log_info "Performing health check..."
    
    if [[ "$DEPLOYMENT_TYPE" == "app-platform" ]]; then
        BACKEND_URL=$(terraform output -json | jq -r '.backend_url.value // empty')
        if [[ -n "$BACKEND_URL" ]]; then
            if curl -f "$BACKEND_URL" > /dev/null 2>&1; then
                log_success "Backend health check passed"
            else
                log_warning "Backend health check failed - this may be normal if the app is still starting"
            fi
        fi
    else
        LOAD_BALANCER_IP=$(terraform output -json | jq -r '.load_balancer_ip.value // empty')
        if [[ -n "$LOAD_BALANCER_IP" ]]; then
            if curl -f "http://$LOAD_BALANCER_IP/health" > /dev/null 2>&1; then
                log_success "Load balancer health check passed"
            else
                log_warning "Load balancer health check failed - this may be normal if the app is still starting"
            fi
        fi
    fi
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f tfplan
    if [[ "$DEPLOYMENT_TYPE" == "droplets" ]]; then
        cd "$TERRAFORM_DIR/droplets"
        rm -f terraform.tfvars
    fi
}

show_next_steps() {
    echo
    log_info "Next steps:"
    echo "1. Wait a few minutes for the application to fully start"
    echo "2. Visit your application URL to test it"
    echo "3. Configure DNS if using a custom domain"
    echo "4. Set up monitoring and alerting"
    echo "5. Configure SSL certificates if needed"
    echo
    echo "To destroy the infrastructure: terraform destroy"
    echo "To view outputs again: terraform output"
}

main() {
    echo "🚀 Global Radio Terraform Deployment Script"
    echo "Deployment type: $DEPLOYMENT_TYPE"
    echo "Environment: $ENVIRONMENT"
    echo

    check_prerequisites
    validate_config
    plan_deployment
    deploy
    show_outputs
    perform_health_check
    cleanup
    show_next_steps
    
    log_success "Deployment script completed!"
}

# Handle script interruption
trap cleanup EXIT

# Show usage if invalid arguments
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: $0 [deployment-type] [environment]"
    echo
    echo "Deployment types:"
    echo "  app-platform  Deploy using Digital Ocean App Platform (default)"
    echo "  droplets      Deploy using Digital Ocean Droplets"
    echo
    echo "Environments:"
    echo "  production    Production environment (default)"
    echo "  staging       Staging environment"
    echo "  development   Development environment"
    echo
    echo "Examples:"
    echo "  $0                          # Deploy to App Platform (production)"
    echo "  $0 app-platform staging     # Deploy to App Platform (staging)"
    echo "  $0 droplets production      # Deploy to Droplets (production)"
    exit 0
fi

# Validate deployment type
if [[ "$DEPLOYMENT_TYPE" != "app-platform" && "$DEPLOYMENT_TYPE" != "droplets" ]]; then
    log_error "Invalid deployment type: $DEPLOYMENT_TYPE"
    log_info "Valid options: app-platform, droplets"
    exit 1
fi

# Run main function
main