#!/bin/bash
# Test script for Global Radio Docker setup

echo "🧪 Testing Global Radio Docker Setup"
echo "===================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected="$3"
    
    echo -n "Testing $name... "
    
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ "$response" == *"$expected"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "  Expected: $expected"
        echo "  Got: $response"
        return 1
    fi
}

echo
echo "📡 Testing Backend API Endpoints:"
echo "--------------------------------"

# Test basic health check
test_endpoint "Health Check" "http://localhost:8001/api/" '"message":"Hello World"'

# Test radio stations
test_endpoint "Popular Stations" "http://localhost:8001/api/radio/stations/popular?limit=1" '"stationuuid"'

# Test countries
test_endpoint "Countries List" "http://localhost:8001/api/radio/countries" '"name"'

# Test search
test_endpoint "Station Search" "http://localhost:8001/api/radio/stations/search?name=BBC&limit=1" '['

echo
echo "🌐 Testing Frontend:"
echo "-------------------"

# Test frontend accessibility
if curl -s "http://localhost:3000" >/dev/null 2>&1; then
    echo -e "Frontend Accessibility... ${GREEN}✓ PASS${NC}"
else
    echo -e "Frontend Accessibility... ${RED}✗ FAIL${NC}"
fi

echo
echo "🗄️ Testing Database:"
echo "-------------------"

# Test MongoDB connection (if docker is available)
if command -v docker >/dev/null 2>&1; then
    if docker ps --format "table {{.Names}}" | grep -q mongodb; then
        echo -e "MongoDB Container... ${GREEN}✓ RUNNING${NC}"
        
        # Test MongoDB ping
        if docker exec global-radio-mongodb-1 mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
            echo -e "MongoDB Connection... ${GREEN}✓ PASS${NC}"
        else
            echo -e "MongoDB Connection... ${RED}✗ FAIL${NC}"
        fi
    else
        echo -e "MongoDB Container... ${RED}✗ NOT RUNNING${NC}"
    fi
else
    echo -e "Docker not available for testing... ${YELLOW}⚠ SKIP${NC}"
fi

echo
echo "📊 Summary:"
echo "----------"

# Count services
backend_ok=0
frontend_ok=0
db_ok=0

if curl -s "http://localhost:8001/api/" >/dev/null 2>&1; then
    backend_ok=1
fi

if curl -s "http://localhost:3000" >/dev/null 2>&1; then
    frontend_ok=1
fi

if command -v docker >/dev/null 2>&1 && docker ps --format "table {{.Names}}" | grep -q mongodb; then
    db_ok=1
fi

total=$((backend_ok + frontend_ok + db_ok))

if [ $total -eq 3 ]; then
    echo -e "${GREEN}✓ All services are running properly!${NC}"
    echo
    echo "🚀 Access your application:"
    echo "   Frontend: http://localhost:3000"
    echo "   Backend:  http://localhost:8001"
    echo "   API Docs: http://localhost:8001/docs"
elif [ $total -gt 0 ]; then
    echo -e "${YELLOW}⚠ Some services are running ($total/3)${NC}"
    echo
    echo "🔧 Troubleshooting:"
    if [ $backend_ok -eq 0 ]; then
        echo "   - Backend: Run 'docker compose up backend' or check logs"
    fi
    if [ $frontend_ok -eq 0 ]; then
        echo "   - Frontend: Run 'docker compose up frontend' or check logs"
    fi
    if [ $db_ok -eq 0 ]; then
        echo "   - Database: Run 'docker compose up mongodb' or check logs"
    fi
else
    echo -e "${RED}✗ No services are running${NC}"
    echo
    echo "🚀 Quick start:"
    echo "   docker compose up -d"
fi

echo
echo "📚 For more help, see LOCAL_DEV.md"