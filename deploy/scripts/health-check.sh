#!/bin/bash

# Global Radio - Health Check Script
# Performs comprehensive health checks on deployed services

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

echo -e "${CYAN}🩺 Global Radio Health Check${NC}"
echo "==============================="

# Get service URLs from Terraform output
FRONTEND_URL=$(cd deploy/terraform && terraform output -raw frontend_url 2>/dev/null || echo "")
BACKEND_URL=$(cd deploy/terraform && terraform output -raw backend_url 2>/dev/null || echo "")

if [ -z "$FRONTEND_URL" ] || [ -z "$BACKEND_URL" ]; then
    echo -e "${RED}❌ Unable to get service URLs. Make sure Terraform has been applied.${NC}"
    exit 1
fi

echo -e "${CYAN}Testing Services:${NC}"
echo "Frontend: $FRONTEND_URL"
echo "Backend: $BACKEND_URL"
echo ""

# Health check functions
check_frontend() {
    echo -e "${CYAN}Checking Frontend...${NC}"
    
    # Test frontend accessibility
    if curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL" | grep -q "200"; then
        echo -e "${GREEN}✅ Frontend is accessible${NC}"
        
        # Check if it's serving the correct content
        if curl -s "$FRONTEND_URL" | grep -q "Global Radio"; then
            echo -e "${GREEN}✅ Frontend content is correct${NC}"
        else
            echo -e "${YELLOW}⚠️  Frontend accessible but content may be incorrect${NC}"
        fi
    else
        echo -e "${RED}❌ Frontend is not accessible${NC}"
        return 1
    fi
}

check_backend() {
    echo -e "${CYAN}Checking Backend...${NC}"
    
    # Test backend health endpoint
    if curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/api/" | grep -q "200"; then
        echo -e "${GREEN}✅ Backend health endpoint is responding${NC}"
    else
        echo -e "${RED}❌ Backend health endpoint is not responding${NC}"
        return 1
    fi
    
    # Test radio stations endpoint
    if curl -s "$BACKEND_URL/api/radio/stations/popular?limit=5" | jq -e '. | length > 0' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Radio stations API is working${NC}"
    else
        echo -e "${YELLOW}⚠️  Radio stations API may have issues${NC}"
    fi
    
    # Test countries endpoint
    if curl -s "$BACKEND_URL/api/radio/countries" | jq -e '. | length > 0' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Countries API is working${NC}"
    else
        echo -e "${YELLOW}⚠️  Countries API may have issues${NC}"
    fi
}

check_database() {
    echo -e "${CYAN}Checking Database Connection...${NC}"
    
    # Test database via backend endpoint
    if curl -s "$BACKEND_URL/api/" | jq -e '.message' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Database connection is working${NC}"
    else
        echo -e "${RED}❌ Database connection may have issues${NC}"
        return 1
    fi
}

check_response_times() {
    echo -e "${CYAN}Checking Response Times...${NC}"
    
    # Frontend response time
    FRONTEND_TIME=$(curl -s -o /dev/null -w "%{time_total}" "$FRONTEND_URL")
    if (( $(echo "$FRONTEND_TIME < 3.0" | bc -l) )); then
        echo -e "${GREEN}✅ Frontend response time: ${FRONTEND_TIME}s${NC}"
    else
        echo -e "${YELLOW}⚠️  Frontend response time: ${FRONTEND_TIME}s (slow)${NC}"
    fi
    
    # Backend response time
    BACKEND_TIME=$(curl -s -o /dev/null -w "%{time_total}" "$BACKEND_URL/api/")
    if (( $(echo "$BACKEND_TIME < 2.0" | bc -l) )); then
        echo -e "${GREEN}✅ Backend response time: ${BACKEND_TIME}s${NC}"
    else
        echo -e "${YELLOW}⚠️  Backend response time: ${BACKEND_TIME}s (slow)${NC}"
    fi
}

check_ssl() {
    echo -e "${CYAN}Checking SSL Certificates...${NC}"
    
    # Check frontend SSL
    if echo | openssl s_client -servername "${FRONTEND_URL#https://}" -connect "${FRONTEND_URL#https://}:443" 2>/dev/null | grep -q "Verify return code: 0"; then
        echo -e "${GREEN}✅ Frontend SSL certificate is valid${NC}"
    else
        echo -e "${YELLOW}⚠️  Frontend SSL certificate may have issues${NC}"
    fi
    
    # Check backend SSL
    if echo | openssl s_client -servername "${BACKEND_URL#https://}" -connect "${BACKEND_URL#https://}:443" 2>/dev/null | grep -q "Verify return code: 0"; then
        echo -e "${GREEN}✅ Backend SSL certificate is valid${NC}"
    else
        echo -e "${YELLOW}⚠️  Backend SSL certificate may have issues${NC}"
    fi
}

# Run all health checks
FAILED_CHECKS=0

echo ""
check_frontend || ((FAILED_CHECKS++))
echo ""
check_backend || ((FAILED_CHECKS++))
echo ""
check_database || ((FAILED_CHECKS++))
echo ""
check_response_times
echo ""
check_ssl

echo ""
echo "==============================="
if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}🎉 All health checks passed!${NC}"
    echo -e "${GREEN}Global Radio is running properly.${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILED_CHECKS health check(s) failed.${NC}"
    echo -e "${YELLOW}Please check the issues above and resolve them.${NC}"
    exit 1
fi