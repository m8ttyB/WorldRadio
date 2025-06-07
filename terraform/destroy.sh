#!/bin/bash

# Global Radio - Terraform Destroy Script
# This script safely destroys the Global Radio infrastructure

set -e

# Configuration
TERRAFORM_DIR="$(dirname "$0")"
DEPLOYMENT_TYPE=${1:-"app-platform"}  # app-platform or droplets

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

show_current_resources() {
    log_info "Current infrastructure resources:"
    
    cd "$TERRAFORM_DIR"
    
    if [[ "$DEPLOYMENT_TYPE" == "droplets" ]]; then
        cd droplets
        cp ../terraform.tfvars . 2>/dev/null || true
    fi
    
    terraform init -input=false
    terraform show -no-color
}

confirm_destruction() {
    echo
    log_warning "⚠️  WARNING: This will PERMANENTLY DESTROY all infrastructure resources!"
    log_warning "This action cannot be undone!"
    echo
    
    # Show what will be destroyed
    log_info "Planning destruction..."
    terraform plan -destroy -no-color
    
    echo
    log_warning "Are you absolutely sure you want to destroy all resources?"
    read -p "Type 'yes' to confirm destruction: " -r
    echo
    
    if [[ "$REPLY" != "yes" ]]; then
        log_info "Destruction cancelled"
        exit 0
    fi
    
    # Double confirmation for production
    if grep -q "environment.*production" terraform.tfvars 2>/dev/null; then
        log_warning "🚨 PRODUCTION ENVIRONMENT DETECTED! 🚨"
        log_warning "You are about to destroy production infrastructure!"
        read -p "Type 'destroy-production' to confirm: " -r
        echo
        
        if [[ "$REPLY" != "destroy-production" ]]; then
            log_info "Destruction cancelled"
            exit 0
        fi
    fi
}

backup_state() {
    log_info "Creating state backup..."
    
    if [[ -f "terraform.tfstate" ]]; then
        cp terraform.tfstate "terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)"
        log_success "State backup created"
    fi
}

destroy_infrastructure() {
    log_info "Destroying infrastructure..."
    
    terraform destroy -auto-approve
    
    if [[ $? -eq 0 ]]; then
        log_success "Infrastructure destroyed successfully!"
    else
        log_error "Destruction failed"
        exit 1
    fi
}

cleanup() {
    log_info "Cleaning up..."
    
    if [[ "$DEPLOYMENT_TYPE" == "droplets" ]]; then
        cd "$TERRAFORM_DIR/droplets"
        rm -f terraform.tfvars
    fi
    
    # Remove any temporary files
    rm -f tfplan
}

show_post_destruction_info() {
    echo
    log_info "Post-destruction information:"
    echo "✅ All infrastructure resources have been destroyed"
    echo "✅ You will no longer be charged for these resources"
    echo "⚠️  Any data stored in the infrastructure has been permanently lost"
    echo
    log_info "If you need to recreate the infrastructure:"
    echo "1. Run the deploy.sh script again"
    echo "2. All data will need to be restored from backups"
}

main() {
    echo "🗑️  Global Radio Infrastructure Destruction Script"
    echo "Deployment type: $DEPLOYMENT_TYPE"
    echo

    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        exit 1
    fi
    
    # Check if terraform.tfvars exists
    if [[ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]]; then
        log_error "terraform.tfvars not found"
        exit 1
    fi
    
    show_current_resources
    confirm_destruction
    backup_state
    destroy_infrastructure
    cleanup
    show_post_destruction_info
    
    log_success "Destruction completed!"
}

# Handle script interruption
trap cleanup EXIT

# Show usage if invalid arguments
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: $0 [deployment-type]"
    echo
    echo "Deployment types:"
    echo "  app-platform  Destroy App Platform deployment (default)"
    echo "  droplets      Destroy Droplets deployment"
    echo
    echo "Examples:"
    echo "  $0                 # Destroy App Platform deployment"
    echo "  $0 droplets        # Destroy Droplets deployment"
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