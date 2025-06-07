#!/bin/bash

# Global Radio - Environment Variables Update Script
# Updates environment variables on deployed services

set -e

# Load environment variables
if [ -f "deploy/.env" ]; then
    source deploy/.env
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔄 Updating Environment Variables${NC}"
echo "=================================="

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

# Get service IDs
BACKEND_SERVICE_ID=$(cd deploy/terraform && terraform output -raw backend_service_id 2>/dev/null || echo "")
FRONTEND_SERVICE_ID=$(cd deploy/terraform && terraform output -raw frontend_service_id 2>/dev/null || echo "")

if [ -z "$BACKEND_SERVICE_ID" ]; then
    echo -e "${RED}❌ Unable to get backend service ID${NC}"
    exit 1
fi

echo -e "${GREEN}Backend Service ID: $BACKEND_SERVICE_ID${NC}"
echo -e "${GREEN}Frontend Service ID: $FRONTEND_SERVICE_ID${NC}"
echo ""

# Update backend environment variables
echo -e "${CYAN}Updating backend environment variables...${NC}"

# Create temporary env file for backend
cat > /tmp/backend-env.txt << EOF
MONGO_URL=$MONGODB_URI
DB_NAME=$DB_NAME
ENVIRONMENT=$ENVIRONMENT
LOG_LEVEL=INFO
DEBUG=false
EOF

# Add optional variables if set
if [ -n "$FRONTEND_DOMAIN" ]; then
    echo "CORS_ORIGINS=https://$FRONTEND_DOMAIN" >> /tmp/backend-env.txt
fi

# Apply environment variables
if render services env set --service-id="$BACKEND_SERVICE_ID" --env-file="/tmp/backend-env.txt"; then
    echo -e "${GREEN}✅ Backend environment variables updated${NC}"
else
    echo -e "${RED}❌ Failed to update backend environment variables${NC}"
    rm -f /tmp/backend-env.txt
    exit 1
fi

# Clean up
rm -f /tmp/backend-env.txt

# Update frontend environment variables (if needed)
if [ -n "$FRONTEND_SERVICE_ID" ]; then
    echo -e "${CYAN}Updating frontend environment variables...${NC}"
    
    # Create temporary env file for frontend
    cat > /tmp/frontend-env.txt << EOF
REACT_APP_BACKEND_URL=${BACKEND_DOMAIN:+https://$BACKEND_DOMAIN}
NODE_VERSION=18
YARN_VERSION=1.22.19
EOF
    
    # Use backend service URL if no custom domain
    if [ -z "$BACKEND_DOMAIN" ]; then
        BACKEND_URL=$(cd deploy/terraform && terraform output -raw backend_url 2>/dev/null || echo "")
        if [ -n "$BACKEND_URL" ]; then
            sed -i "s|REACT_APP_BACKEND_URL=|REACT_APP_BACKEND_URL=$BACKEND_URL|" /tmp/frontend-env.txt
        fi
    fi
    
    # Apply environment variables
    if render services env set --service-id="$FRONTEND_SERVICE_ID" --env-file="/tmp/frontend-env.txt"; then
        echo -e "${GREEN}✅ Frontend environment variables updated${NC}"
    else
        echo -e "${RED}❌ Failed to update frontend environment variables${NC}"
        rm -f /tmp/frontend-env.txt
        exit 1
    fi
    
    # Clean up
    rm -f /tmp/frontend-env.txt
fi

echo ""
echo "=================================="
echo -e "${GREEN}✅ Environment variables updated successfully${NC}"
echo -e "${YELLOW}⚠️  Services will restart automatically to apply changes${NC}"