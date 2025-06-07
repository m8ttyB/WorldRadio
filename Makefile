# Global Radio - Render.com Deployment Makefile
# Automation for deployment, monitoring, and maintenance

.PHONY: help deploy-all terraform-init terraform-plan terraform-apply terraform-destroy
.PHONY: setup check-env deploy status logs health-check test-api backup-db
.PHONY: scale-backend update-env rollback monitor clean

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

# Configuration
DEPLOY_DIR := deploy
TERRAFORM_DIR := $(DEPLOY_DIR)/terraform
SCRIPTS_DIR := $(DEPLOY_DIR)/scripts

# Load environment variables
ifneq (,$(wildcard $(DEPLOY_DIR)/.env))
    include $(DEPLOY_DIR)/.env
    export
endif

##@ Help
help: ## Display this help
	@echo "$(CYAN)Global Radio - Render.com Deployment$(RESET)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(CYAN)<target>$(RESET)\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(CYAN)%-15s$(RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Quick Start
deploy-all: check-env terraform-init terraform-apply health-check ## 🚀 Complete deployment from scratch
	@echo "$(GREEN)✅ Deployment completed successfully!$(RESET)"
	@echo "$(CYAN)Frontend URL:$(RESET) $$(cd $(TERRAFORM_DIR) && terraform output -raw frontend_url 2>/dev/null || echo 'Not available yet')"
	@echo "$(CYAN)Backend URL:$(RESET) $$(cd $(TERRAFORM_DIR) && terraform output -raw backend_url 2>/dev/null || echo 'Not available yet')"

setup: ## 🛠️ Initial project setup
	@echo "$(CYAN)Setting up Global Radio deployment...$(RESET)"
	@mkdir -p $(DEPLOY_DIR)/{terraform,scripts}
	@if [ ! -f "$(DEPLOY_DIR)/.env" ]; then \
		cp $(DEPLOY_DIR)/.env.example $(DEPLOY_DIR)/.env; \
		echo "$(YELLOW)⚠️  Please edit $(DEPLOY_DIR)/.env with your configuration$(RESET)"; \
	fi
	@echo "$(GREEN)✅ Setup completed$(RESET)"

##@ Environment
check-env: ## 🔍 Validate environment configuration
	@echo "$(CYAN)Checking environment configuration...$(RESET)"
	@if [ -z "$(RENDER_API_KEY)" ]; then echo "$(RED)❌ RENDER_API_KEY not set$(RESET)"; exit 1; fi
	@if [ -z "$(MONGODB_URI)" ]; then echo "$(RED)❌ MONGODB_URI not set$(RESET)"; exit 1; fi
	@if [ -z "$(GITHUB_REPO_URL)" ]; then echo "$(RED)❌ GITHUB_REPO_URL not set$(RESET)"; exit 1; fi
	@echo "$(GREEN)✅ Environment configuration valid$(RESET)"

env-status: ## 📊 Show environment variable status
	@echo "$(CYAN)Environment Status:$(RESET)"
	@echo "  RENDER_API_KEY: $(if $(RENDER_API_KEY),$(GREEN)✓ Set$(RESET),$(RED)✗ Missing$(RESET))"
	@echo "  MONGODB_URI: $(if $(MONGODB_URI),$(GREEN)✓ Set$(RESET),$(RED)✗ Missing$(RESET))"
	@echo "  GITHUB_REPO_URL: $(if $(GITHUB_REPO_URL),$(GREEN)✓ Set$(RESET),$(RED)✗ Missing$(RESET))"
	@echo "  APP_NAME: $(or $(APP_NAME),Not set)"
	@echo "  FRONTEND_DOMAIN: $(or $(FRONTEND_DOMAIN),Not set)"
	@echo "  BACKEND_DOMAIN: $(or $(BACKEND_DOMAIN),Not set)"

##@ Terraform
terraform-init: ## 🏗️ Initialize Terraform
	@echo "$(CYAN)Initializing Terraform...$(RESET)"
	@cd $(TERRAFORM_DIR) && terraform init
	@echo "$(GREEN)✅ Terraform initialized$(RESET)"

terraform-plan: check-env ## 📋 Plan Terraform deployment
	@echo "$(CYAN)Planning Terraform deployment...$(RESET)"
	@cd $(TERRAFORM_DIR) && terraform plan -var-file="terraform.tfvars"
	@echo "$(GREEN)✅ Terraform plan completed$(RESET)"

terraform-apply: check-env ## 🚀 Apply Terraform configuration
	@echo "$(CYAN)Applying Terraform configuration...$(RESET)"
	@cd $(TERRAFORM_DIR) && terraform apply -var-file="terraform.tfvars" -auto-approve
	@echo "$(GREEN)✅ Terraform applied successfully$(RESET)"

terraform-destroy: ## 🗑️ Destroy infrastructure
	@echo "$(RED)⚠️  This will destroy all infrastructure!$(RESET)"
	@read -p "Are you sure? [y/N]: " confirm && [ "$$confirm" = "y" ] || exit 1
	@cd $(TERRAFORM_DIR) && terraform destroy -var-file="terraform.tfvars" -auto-approve
	@echo "$(GREEN)✅ Infrastructure destroyed$(RESET)"

terraform-output: ## 📤 Show Terraform outputs
	@cd $(TERRAFORM_DIR) && terraform output

##@ Deployment
deploy: terraform-apply ## 🚀 Deploy application
	@echo "$(CYAN)Deploying Global Radio...$(RESET)"
	@sleep 30  # Wait for services to initialize
	@$(MAKE) health-check
	@echo "$(GREEN)✅ Deployment completed$(RESET)"

deploy-ci: ## 🤖 CI/CD deployment
	@echo "$(CYAN)CI/CD Deployment starting...$(RESET)"
	@$(MAKE) check-env terraform-init terraform-apply
	@echo "$(GREEN)✅ CI/CD Deployment completed$(RESET)"

rollback: ## ⏪ Rollback to previous deployment
	@echo "$(CYAN)Rolling back deployment...$(RESET)"
	@cd $(TERRAFORM_DIR) && terraform refresh && terraform apply -refresh=false
	@echo "$(GREEN)✅ Rollback completed$(RESET)"

##@ Monitoring
status: ## 📊 Check application status
	@echo "$(CYAN)Application Status:$(RESET)"
	@$(SCRIPTS_DIR)/status.sh

health-check: ## 🩺 Perform health check
	@echo "$(CYAN)Performing health check...$(RESET)"
	@$(SCRIPTS_DIR)/health-check.sh

test-api: ## 🧪 Test API endpoints
	@echo "$(CYAN)Testing API endpoints...$(RESET)"
	@$(SCRIPTS_DIR)/test-api.sh

logs-backend: ## 📋 View backend logs
	@echo "$(CYAN)Backend Logs (last 100 lines):$(RESET)"
	@$(SCRIPTS_DIR)/logs.sh backend

logs-frontend: ## 📋 View frontend logs
	@echo "$(CYAN)Frontend Logs (last 100 lines):$(RESET)"
	@$(SCRIPTS_DIR)/logs.sh frontend

logs-build: ## 📋 View build logs
	@echo "$(CYAN)Build Logs:$(RESET)"
	@$(SCRIPTS_DIR)/logs.sh build

##@ Scaling
scale-backend: ## ⚖️ Scale backend service (Usage: make scale-backend INSTANCES=2)
	@echo "$(CYAN)Scaling backend to $(or $(INSTANCES),1) instance(s)...$(RESET)"
	@$(SCRIPTS_DIR)/scale.sh backend $(or $(INSTANCES),1)
	@echo "$(GREEN)✅ Backend scaled$(RESET)"

##@ Database
test-db: ## 🗄️ Test database connection
	@echo "$(CYAN)Testing database connection...$(RESET)"
	@$(SCRIPTS_DIR)/test-db.sh

backup-db: ## 💾 Backup database
	@echo "$(CYAN)Creating database backup...$(RESET)"
	@$(SCRIPTS_DIR)/backup-db.sh
	@echo "$(GREEN)✅ Database backup completed$(RESET)"

db-status: ## 📊 Check database status
	@echo "$(CYAN)Database Status:$(RESET)"
	@$(SCRIPTS_DIR)/db-status.sh

##@ Configuration
update-env: ## 🔄 Update environment variables
	@echo "$(CYAN)Updating environment variables...$(RESET)"
	@$(SCRIPTS_DIR)/update-env.sh
	@echo "$(GREEN)✅ Environment variables updated$(RESET)"

config-check: ## ⚙️ Check service configuration
	@echo "$(CYAN)Checking service configuration...$(RESET)"
	@$(SCRIPTS_DIR)/config-check.sh

##@ Performance
monitor-performance: ## 📈 Monitor application performance
	@echo "$(CYAN)Monitoring performance...$(RESET)"
	@$(SCRIPTS_DIR)/monitor.sh

resource-status: ## 💻 Check resource usage
	@echo "$(CYAN)Resource Usage:$(RESET)"
	@$(SCRIPTS_DIR)/resource-status.sh

optimize: ## ⚡ Optimize application performance
	@echo "$(CYAN)Optimizing application...$(RESET)"
	@$(SCRIPTS_DIR)/optimize.sh
	@echo "$(GREEN)✅ Optimization completed$(RESET)"

##@ Security
security-check: ## 🔒 Run security checks
	@echo "$(CYAN)Running security checks...$(RESET)"
	@$(SCRIPTS_DIR)/security-check.sh

rotate-keys: ## 🔑 Rotate API keys
	@echo "$(CYAN)Rotating API keys...$(RESET)"
	@$(SCRIPTS_DIR)/rotate-keys.sh
	@echo "$(GREEN)✅ API keys rotated$(RESET)"

##@ Maintenance
clean: ## 🧹 Clean up temporary files
	@echo "$(CYAN)Cleaning up...$(RESET)"
	@rm -rf $(TERRAFORM_DIR)/.terraform.lock.hcl
	@rm -rf $(TERRAFORM_DIR)/terraform.tfstate.backup
	@rm -rf $(DEPLOY_DIR)/logs/*
	@echo "$(GREEN)✅ Cleanup completed$(RESET)"

debug-enable: ## 🐛 Enable debug mode
	@echo "$(CYAN)Enabling debug mode...$(RESET)"
	@$(SCRIPTS_DIR)/debug.sh enable

debug-disable: ## 🐛 Disable debug mode
	@echo "$(CYAN)Disabling debug mode...$(RESET)"
	@$(SCRIPTS_DIR)/debug.sh disable

##@ Cost Management
cost-analysis: ## 💰 Analyze deployment costs
	@echo "$(CYAN)Analyzing costs...$(RESET)"
	@$(SCRIPTS_DIR)/cost-analysis.sh

optimize-resources: ## 💡 Optimize resource allocation
	@echo "$(CYAN)Optimizing resources...$(RESET)"
	@$(SCRIPTS_DIR)/optimize-resources.sh

##@ Development
local-test: ## 🧪 Test deployment configuration locally
	@echo "$(CYAN)Testing deployment configuration...$(RESET)"
	@cd $(TERRAFORM_DIR) && terraform validate
	@$(MAKE) check-env
	@echo "$(GREEN)✅ Configuration is valid$(RESET)"

validate: ## ✅ Validate all configurations
	@echo "$(CYAN)Validating configurations...$(RESET)"
	@$(MAKE) check-env
	@cd $(TERRAFORM_DIR) && terraform validate
	@$(SCRIPTS_DIR)/validate.sh
	@echo "$(GREEN)✅ All validations passed$(RESET)"

##@ Information
info: ## ℹ️ Show deployment information
	@echo "$(CYAN)Global Radio Deployment Information:$(RESET)"
	@echo ""
	@echo "$(YELLOW)Services:$(RESET)"
	@echo "  Frontend: Static Site (React)"
	@echo "  Backend: Web Service (FastAPI)"
	@echo "  Database: MongoDB Atlas"
	@echo ""
	@echo "$(YELLOW)URLs:$(RESET)"
	@echo "  Frontend: $$(cd $(TERRAFORM_DIR) 2>/dev/null && terraform output -raw frontend_url 2>/dev/null || echo 'Not deployed')"
	@echo "  Backend: $$(cd $(TERRAFORM_DIR) 2>/dev/null && terraform output -raw backend_url 2>/dev/null || echo 'Not deployed')"
	@echo ""
	@echo "$(YELLOW)Environment:$(RESET) $(or $(ENVIRONMENT),development)"
	@echo "$(YELLOW)App Name:$(RESET) $(or $(APP_NAME),global-radio)"

urls: ## 🔗 Show application URLs
	@echo "$(CYAN)Application URLs:$(RESET)"
	@cd $(TERRAFORM_DIR) && terraform output -json | jq -r '
		"Frontend: " + (.frontend_url.value // "Not available"),
		"Backend: " + (.backend_url.value // "Not available"),
		"API Docs: " + (.backend_url.value // "Not available") + "/docs"
	' 2>/dev/null || echo "Terraform state not found. Run 'make deploy' first."

##@ Troubleshooting
logs-detailed: ## 📋 View detailed logs
	@echo "$(CYAN)Detailed Logs:$(RESET)"
	@$(SCRIPTS_DIR)/logs-detailed.sh

retry-deploy: ## 🔄 Retry failed deployment
	@echo "$(CYAN)Retrying deployment...$(RESET)"
	@$(MAKE) terraform-apply
	@$(MAKE) health-check

emergency-stop: ## 🛑 Emergency stop all services
	@echo "$(RED)Emergency stopping all services...$(RESET)"
	@$(SCRIPTS_DIR)/emergency-stop.sh
	@echo "$(GREEN)✅ All services stopped$(RESET)"

##@ Documentation
docs: ## 📚 Generate documentation
	@echo "$(CYAN)Generating documentation...$(RESET)"
	@$(SCRIPTS_DIR)/generate-docs.sh

##@ Version Info
version: ## 📊 Show version information
	@echo "$(CYAN)Version Information:$(RESET)"
	@echo "  Terraform: $$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || echo 'Not installed')"
	@echo "  Make: $$(make --version | head -1 2>/dev/null || echo 'Not available')"
	@echo "  Git: $$(git --version 2>/dev/null || echo 'Not installed')"
	@echo "  Node.js: $$(node --version 2>/dev/null || echo 'Not installed')"
	@echo "  Python: $$(python3 --version 2>/dev/null || echo 'Not installed')"