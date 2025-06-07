#!/bin/bash

# Global Radio - Logs Script
# Retrieves and displays service logs from Render.com

set -e

# Load environment variables
if [ -f "deploy/.env" ]; then
    source deploy/.env
fi

SERVICE_TYPE=${1:-"backend"}
LINES=${2:-100}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}📋 Global Radio Logs - $SERVICE_TYPE${NC}"
echo "=================================="

# Check if render CLI is available
if ! command -v render &> /dev/null; then
    echo -e "${YELLOW}⚠️  Render CLI not found. Installing...${NC}"
    
    # Install Render CLI
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install render-oss/render/render
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -fsSL https://cli.render.com/install | sh
    else
        echo -e "${RED}❌ Unable to install Render CLI automatically${NC}"
        echo "Please install manually: https://render.com/docs/cli"
        exit 1
    fi
fi

# Authenticate with Render CLI if not already done
if ! render auth whoami &>/dev/null; then
    echo -e "${YELLOW}🔐 Authenticating with Render...${NC}"
    render auth login --api-key="$RENDER_API_KEY"
fi

# Get service ID based on type
if [ "$SERVICE_TYPE" = "backend" ]; then
    SERVICE_ID=$(cd deploy/terraform && terraform output -raw backend_service_id 2>/dev/null || echo "")
    SERVICE_NAME="Backend API"
elif [ "$SERVICE_TYPE" = "frontend" ]; then
    SERVICE_ID=$(cd deploy/terraform && terraform output -raw frontend_service_id 2>/dev/null || echo "")
    SERVICE_NAME="Frontend"
elif [ "$SERVICE_TYPE" = "build" ]; then
    # For build logs, we'll use the backend service
    SERVICE_ID=$(cd deploy/terraform && terraform output -raw backend_service_id 2>/dev/null || echo "")
    SERVICE_NAME="Build"
else
    echo -e "${RED}❌ Invalid service type: $SERVICE_TYPE${NC}"
    echo "Valid options: backend, frontend, build"
    exit 1
fi

if [ -z "$SERVICE_ID" ]; then
    echo -e "${RED}❌ Unable to get service ID for $SERVICE_TYPE${NC}"
    echo "Make sure the service is deployed with Terraform."
    exit 1
fi

echo -e "${GREEN}Service: $SERVICE_NAME${NC}"
echo -e "${GREEN}Service ID: $SERVICE_ID${NC}"
echo -e "${GREEN}Lines: $LINES${NC}"
echo ""

# Fetch logs based on service type
if [ "$SERVICE_TYPE" = "build" ]; then
    echo -e "${CYAN}Fetching build logs...${NC}"
    render services logs --service-id="$SERVICE_ID" --type=build --tail=$LINES
else
    echo -e "${CYAN}Fetching runtime logs...${NC}"
    render services logs --service-id="$SERVICE_ID" --type=app --tail=$LINES
fi

echo ""
echo "=================================="
echo -e "${CYAN}Tip: Use 'make logs-$SERVICE_TYPE' for continuous tail${NC}"