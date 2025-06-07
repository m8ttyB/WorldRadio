#!/bin/bash

# Global Radio - API Testing Script
# Comprehensive API endpoint testing

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

echo -e "${CYAN}🧪 Global Radio API Testing${NC}"
echo "==============================="

# Get backend URL from Terraform
BACKEND_URL=$(cd deploy/terraform && terraform output -raw backend_url 2>/dev/null || echo "")

if [ -z "$BACKEND_URL" ]; then
    echo -e "${RED}❌ Unable to get backend URL. Make sure services are deployed.${NC}"
    exit 1
fi

echo -e "${CYAN}Testing API at: $BACKEND_URL${NC}"
echo ""

# Test functions
test_endpoint() {
    local endpoint=$1
    local description=$2
    local expected_status=${3:-200}
    
    echo -e "${CYAN}Testing: $description${NC}"
    echo "  URL: $BACKEND_URL$endpoint"
    
    # Make request and capture response
    response=$(curl -s -w "\n%{http_code}\n%{time_total}" "$BACKEND_URL$endpoint" || echo -e "\nERROR\n0")
    
    # Parse response
    http_code=$(echo "$response" | tail -n 2 | head -n 1)
    time_total=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | head -n -2)
    
    # Check status code
    if [ "$http_code" = "$expected_status" ]; then
        echo -e "  Status: ${GREEN}✅ $http_code${NC}"
    else
        echo -e "  Status: ${RED}❌ $http_code (expected $expected_status)${NC}"
        return 1
    fi
    
    # Check response time
    if (( $(echo "$time_total < 2.0" | bc -l) )); then
        echo -e "  Response time: ${GREEN}✅ ${time_total}s${NC}"
    else
        echo -e "  Response time: ${YELLOW}⚠️  ${time_total}s (slow)${NC}"
    fi
    
    # Validate JSON if expected
    if echo "$body" | jq . >/dev/null 2>&1; then
        echo -e "  JSON: ${GREEN}✅ Valid${NC}"
    else
        echo -e "  JSON: ${YELLOW}⚠️  Invalid or not JSON${NC}"
    fi
    
    echo ""
    return 0
}

test_radio_api() {
    local endpoint=$1
    local description=$2
    
    echo -e "${CYAN}Testing: $description${NC}"
    echo "  URL: $BACKEND_URL$endpoint"
    
    response=$(curl -s "$BACKEND_URL$endpoint" || echo "ERROR")
    
    if [ "$response" = "ERROR" ]; then
        echo -e "  Status: ${RED}❌ Request failed${NC}"
        echo ""
        return 1
    fi
    
    # Check if response is valid JSON array
    if echo "$response" | jq -e '. | type == "array"' >/dev/null 2>&1; then
        count=$(echo "$response" | jq '. | length')
        echo -e "  Status: ${GREEN}✅ Success${NC}"
        echo -e "  Results: ${GREEN}$count items${NC}"
        
        # Validate first item structure for stations
        if [[ "$endpoint" == *"stations"* ]]; then
            if echo "$response" | jq -e '.[0] | has("stationuuid") and has("name") and has("country")' >/dev/null 2>&1; then
                echo -e "  Structure: ${GREEN}✅ Valid station objects${NC}"
            else
                echo -e "  Structure: ${YELLOW}⚠️  Unexpected station structure${NC}"
            fi
        fi
    else
        echo -e "  Status: ${RED}❌ Invalid response format${NC}"
        echo "  Response: $response"
    fi
    
    echo ""
}

# Run API tests
FAILED_TESTS=0

# Basic health check
test_endpoint "/api/" "Health Check" || ((FAILED_TESTS++))

# Radio stations endpoints
test_radio_api "/api/radio/stations/popular?limit=10" "Popular Radio Stations" || ((FAILED_TESTS++))
test_radio_api "/api/radio/countries" "Countries List" || ((FAILED_TESTS++))
test_radio_api "/api/radio/stations/search?name=radio&limit=5" "Search Stations by Name" || ((FAILED_TESTS++))
test_radio_api "/api/radio/stations/search?country=United%20States&limit=5" "Search Stations by Country" || ((FAILED_TESTS++))

# API documentation
test_endpoint "/docs" "API Documentation" || ((FAILED_TESTS++))

# OpenAPI schema
test_endpoint "/openapi.json" "OpenAPI Schema" || ((FAILED_TESTS++))

# CORS test (if configured)
echo -e "${CYAN}Testing: CORS Headers${NC}"
cors_headers=$(curl -s -I -H "Origin: https://example.com" "$BACKEND_URL/api/" | grep -i "access-control" || echo "")
if [ -n "$cors_headers" ]; then
    echo -e "  CORS: ${GREEN}✅ Headers present${NC}"
    echo "  Headers: $cors_headers"
else
    echo -e "  CORS: ${YELLOW}⚠️  No CORS headers found${NC}"
fi
echo ""

# Performance test
echo -e "${CYAN}Testing: Performance${NC}"
echo "Making 5 concurrent requests to /api/..."

# Measure average response time
total_time=0
for i in {1..5}; do
    time=$(curl -s -o /dev/null -w "%{time_total}" "$BACKEND_URL/api/")
    total_time=$(echo "$total_time + $time" | bc -l)
done

avg_time=$(echo "scale=3; $total_time / 5" | bc -l)
echo -e "  Average response time: ${avg_time}s"

if (( $(echo "$avg_time < 1.0" | bc -l) )); then
    echo -e "  Performance: ${GREEN}✅ Excellent${NC}"
elif (( $(echo "$avg_time < 2.0" | bc -l) )); then
    echo -e "  Performance: ${GREEN}✅ Good${NC}"
else
    echo -e "  Performance: ${YELLOW}⚠️  Could be improved${NC}"
fi

echo ""
echo "==============================="

# Summary
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 All API tests passed!${NC}"
    echo -e "${GREEN}The API is functioning correctly.${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILED_TESTS test(s) failed.${NC}"
    echo -e "${YELLOW}Please check the issues above and resolve them.${NC}"
    exit 1
fi