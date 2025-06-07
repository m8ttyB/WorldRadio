#!/bin/bash

# Global Radio - Scaling Script
# Scale backend service instances

set -e

# Load environment variables
if [ -f "deploy/.env" ]; then
    source deploy/.env
fi

SERVICE_TYPE=${1:-"backend"}
INSTANCES=${2:-1}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}⚖️ Scaling $SERVICE_TYPE to $INSTANCES instance(s)${NC}"
echo "================================================="

# Validate instance count
if ! [[ "$INSTANCES" =~ ^[0-9]+$ ]] || [ "$INSTANCES" -lt 1 ] || [ "$INSTANCES" -gt 10 ]; then
    echo -e "${RED}❌ Invalid instance count: $INSTANCES${NC}"
    echo "Instance count must be between 1 and 10"
    exit 1
fi

# Check if render CLI is available
if ! command -v render &> /dev/null; then
    echo -e "${RED}❌ Render CLI not found${NC}"
    echo "Please install: https://render.com/docs/cli"
    exit 1
fi

# Authenticate if needed
if ! render auth whoami &>/dev/null; then
    echo -e "${YELLOW}🔐 Authenticating with Render...${NC}"
    render auth login --api-key="$RENDER_API_KEY"
fi

# Get service ID
if [ "$SERVICE_TYPE" = "backend" ]; then
    SERVICE_ID=$(cd deploy/terraform && terraform output -raw backend_service_id 2>/dev/null || echo "")
else
    echo -e "${RED}❌ Only backend scaling is supported${NC}"
    exit 1
fi

if [ -z "$SERVICE_ID" ]; then
    echo -e "${RED}❌ Unable to get service ID${NC}"
    exit 1
fi

echo -e "${GREEN}Service ID: $SERVICE_ID${NC}"
echo ""

# Scale the service
echo -e "${CYAN}Scaling service...${NC}"
if render services scale --service-id="$SERVICE_ID" --replicas="$INSTANCES"; then
    echo -e "${GREEN}✅ Service scaled successfully${NC}"
    echo ""
    
    # Wait for scaling to complete
    echo -e "${CYAN}Waiting for scaling to complete...${NC}"
    sleep 30
    
    # Check status
    echo -e "${CYAN}Checking service status...${NC}"
    render services get --service-id="$SERVICE_ID"
    
else
    echo -e "${RED}❌ Failed to scale service${NC}"
    exit 1
fi

echo ""
echo "================================================="
echo -e "${GREEN}✅ Scaling completed${NC}"