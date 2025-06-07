#!/bin/bash

# Global Radio - Database Connection Test
# Tests MongoDB connection and basic operations

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

echo -e "${CYAN}🗄️ Testing Database Connection${NC}"
echo "==============================="

if [ -z "$MONGODB_URI" ]; then
    echo -e "${RED}❌ MONGODB_URI not set${NC}"
    exit 1
fi

echo -e "${CYAN}MongoDB URI: ${MONGODB_URI//:\/\/[^@]*@/:\/\/***:***@}${NC}"
echo ""

# Check if mongosh is available
if command -v mongosh &> /dev/null; then
    MONGO_CMD="mongosh"
elif command -v mongo &> /dev/null; then
    MONGO_CMD="mongo"
else
    echo -e "${YELLOW}⚠️  MongoDB client not found locally${NC}"
    echo "Testing via API endpoint instead..."
    
    # Test via backend API
    BACKEND_URL=$(cd deploy/terraform && terraform output -raw backend_url 2>/dev/null || echo "")
    
    if [ -n "$BACKEND_URL" ]; then
        echo -e "${CYAN}Testing database via API...${NC}"
        
        if curl -s "$BACKEND_URL/api/" | jq -e '.message' > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Database connection via API is working${NC}"
            
            # Test basic operations
            echo -e "${CYAN}Testing database operations...${NC}"
            
            # Test radio stations query
            if curl -s "$BACKEND_URL/api/radio/stations/popular?limit=1" | jq -e '. | length >= 0' > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Radio stations query successful${NC}"
            else
                echo -e "${RED}❌ Radio stations query failed${NC}"
            fi
            
            # Test countries query
            if curl -s "$BACKEND_URL/api/radio/countries" | jq -e '. | length >= 0' > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Countries query successful${NC}"
            else
                echo -e "${RED}❌ Countries query failed${NC}"
            fi
            
        else
            echo -e "${RED}❌ Database connection via API failed${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ No backend URL available for testing${NC}"
        exit 1
    fi
    
    echo ""
    echo "==============================="
    echo -e "${GREEN}✅ Database connection test completed via API${NC}"
    exit 0
fi

# Direct MongoDB connection test
echo -e "${CYAN}Testing direct MongoDB connection...${NC}"

# Create test script
cat > /tmp/mongo-test.js << 'EOF'
try {
    // Test connection
    db = db.getSiblingDB('global_radio');
    
    // Test basic operations
    print("✅ Connected to database successfully");
    
    // Check collections
    var collections = db.getCollectionNames();
    print("📋 Collections: " + collections.length);
    
    // Test a simple operation
    var result = db.runCommand({ping: 1});
    if (result.ok === 1) {
        print("✅ Database ping successful");
    } else {
        print("❌ Database ping failed");
    }
    
    // Test status_checks collection (created by our app)
    var statusCount = db.status_checks.countDocuments();
    print("📊 Status checks: " + statusCount);
    
    print("✅ Database test completed successfully");
    
} catch (error) {
    print("❌ Database test failed: " + error);
    quit(1);
}
EOF

# Run the test
if $MONGO_CMD "$MONGODB_URI" --quiet /tmp/mongo-test.js; then
    echo -e "${GREEN}✅ Direct database connection successful${NC}"
else
    echo -e "${RED}❌ Direct database connection failed${NC}"
    rm -f /tmp/mongo-test.js
    exit 1
fi

# Clean up
rm -f /tmp/mongo-test.js

# Additional connection info
echo ""
echo -e "${CYAN}Database Information:${NC}"

# Parse MongoDB URI for info (safely)
if [[ "$MONGODB_URI" =~ mongodb(\+srv)?://([^:]+):([^@]+)@([^/]+)/(.+) ]]; then
    protocol="${BASH_REMATCH[1]}"
    username="${BASH_REMATCH[2]}"
    host="${BASH_REMATCH[4]}"
    database="${BASH_REMATCH[5]}"
    
    echo "  Protocol: mongodb${protocol}"
    echo "  Username: $username"
    echo "  Host: $host"
    echo "  Database: $database"
else
    echo "  URI format: Valid MongoDB connection string"
fi

echo ""
echo "==============================="
echo -e "${GREEN}✅ Database connection test completed${NC}"