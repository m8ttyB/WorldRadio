#!/bin/bash

# Global Radio - Service Status Script
# Shows comprehensive status of all deployed services

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
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${CYAN}📊 Global Radio Service Status${NC}"
echo "================================"

# Check if Terraform state exists
if [ ! -f "deploy/terraform/terraform.tfstate" ]; then
    echo -e "${RED}❌ No Terraform state found. Services may not be deployed.${NC}"
    echo "Run 'make deploy' to deploy the application."
    exit 1
fi

# Get service information from Terraform
cd deploy/terraform
FRONTEND_URL=$(terraform output -raw frontend_url 2>/dev/null || echo "Not available")
BACKEND_URL=$(terraform output -raw backend_url 2>/dev/null || echo "Not available")
BACKEND_SERVICE_ID=$(terraform output -raw backend_service_id 2>/dev/null || echo "Not available")
FRONTEND_SERVICE_ID=$(terraform output -raw frontend_service_id 2>/dev/null || echo "Not available")
cd ../..

echo -e "${BLUE}Service URLs:${NC}"
echo "  Frontend: $FRONTEND_URL"
echo "  Backend:  $BACKEND_URL"
echo "  API Docs: ${BACKEND_URL}/docs"
echo ""

echo -e "${BLUE}Service IDs:${NC}"
echo "  Backend Service:  $BACKEND_SERVICE_ID"
echo "  Frontend Service: $FRONTEND_SERVICE_ID"
echo ""

# Check service availability
echo -e "${BLUE}Service Availability:${NC}"

# Frontend status
if curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL" | grep -q "200"; then
    echo -e "  Frontend: ${GREEN}🟢 Online${NC}"
    FRONTEND_SIZE=$(curl -s "$FRONTEND_URL" | wc -c)
    echo "    Response size: ${FRONTEND_SIZE} bytes"
else
    echo -e "  Frontend: ${RED}🔴 Offline${NC}"
fi

# Backend status
if curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/api/" | grep -q "200"; then
    echo -e "  Backend:  ${GREEN}🟢 Online${NC}"
    
    # Get backend info
    BACKEND_INFO=$(curl -s "$BACKEND_URL/api/" | jq -r '.message' 2>/dev/null || echo "API responding")
    echo "    Status: $BACKEND_INFO"
    
    # Check radio stations
    STATIONS_COUNT=$(curl -s "$BACKEND_URL/api/radio/stations/popular?limit=100" | jq '. | length' 2>/dev/null || echo "Unknown")
    echo "    Radio stations: $STATIONS_COUNT"
    
    # Check countries
    COUNTRIES_COUNT=$(curl -s "$BACKEND_URL/api/radio/countries" | jq '. | length' 2>/dev/null || echo "Unknown")
    echo "    Countries: $COUNTRIES_COUNT"
else
    echo -e "  Backend:  ${RED}🔴 Offline${NC}"
fi

echo ""

# Performance metrics
echo -e "${BLUE}Performance Metrics:${NC}"

# Frontend performance
FRONTEND_TIME=$(curl -s -o /dev/null -w "%{time_total}" "$FRONTEND_URL" 2>/dev/null || echo "N/A")
if [ "$FRONTEND_TIME" != "N/A" ]; then
    echo "  Frontend response time: ${FRONTEND_TIME}s"
else
    echo "  Frontend response time: N/A"
fi

# Backend performance
BACKEND_TIME=$(curl -s -o /dev/null -w "%{time_total}" "$BACKEND_URL/api/" 2>/dev/null || echo "N/A")
if [ "$BACKEND_TIME" != "N/A" ]; then
    echo "  Backend response time:  ${BACKEND_TIME}s"
else
    echo "  Backend response time:  N/A"
fi

echo ""

# Environment information
echo -e "${BLUE}Environment Information:${NC}"
echo "  App Name:     ${APP_NAME:-Not set}"
echo "  Environment:  ${ENVIRONMENT:-Not set}"
echo "  Backend Plan: ${BACKEND_PLAN:-Not set}"
echo "  Region:       ${BACKEND_REGION:-Not set}"
echo "  Instances:    ${BACKEND_INSTANCES:-Not set}"

echo ""

# Custom domains
echo -e "${BLUE}Custom Domains:${NC}"
if [ -n "$FRONTEND_DOMAIN" ]; then
    echo "  Frontend: $FRONTEND_DOMAIN"
else
    echo "  Frontend: Not configured"
fi

if [ -n "$BACKEND_DOMAIN" ]; then
    echo "  Backend:  $BACKEND_DOMAIN"
else
    echo "  Backend:  Not configured"
fi

echo ""

# Quick health summary
echo -e "${BLUE}Quick Health Summary:${NC}"

HEALTH_STATUS="Healthy"
ISSUES=0

# Check frontend
if ! curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL" | grep -q "200"; then
    HEALTH_STATUS="Issues Detected"
    ((ISSUES++))
fi

# Check backend
if ! curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/api/" | grep -q "200"; then
    HEALTH_STATUS="Issues Detected"
    ((ISSUES++))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "  Overall Status: ${GREEN}✅ $HEALTH_STATUS${NC}"
else
    echo -e "  Overall Status: ${RED}❌ $HEALTH_STATUS ($ISSUES issue(s))${NC}"
fi

echo ""
echo "================================"
echo -e "${CYAN}Use 'make health-check' for detailed health information${NC}"
echo -e "${CYAN}Use 'make logs-backend' or 'make logs-frontend' for service logs${NC}"