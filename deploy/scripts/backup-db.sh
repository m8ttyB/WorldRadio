#!/bin/bash

# Global Radio - Database Backup Script
# Creates a backup of the MongoDB database

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

echo -e "${CYAN}💾 Creating Database Backup${NC}"
echo "============================"

if [ -z "$MONGODB_URI" ]; then
    echo -e "${RED}❌ MONGODB_URI not set${NC}"
    exit 1
fi

# Create backup directory
BACKUP_DIR="deploy/backups"
mkdir -p "$BACKUP_DIR"

# Generate backup filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="global_radio_backup_${TIMESTAMP}"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

echo -e "${CYAN}Backup location: $BACKUP_PATH${NC}"
echo ""

# Check if mongodump is available
if ! command -v mongodump &> /dev/null; then
    echo -e "${YELLOW}⚠️  mongodump not found${NC}"
    echo "Please install MongoDB Database Tools:"
    echo "  macOS: brew install mongodb/brew/mongodb-database-tools"
    echo "  Ubuntu: sudo apt install mongodb-database-tools"
    echo "  Or download from: https://www.mongodb.com/try/download/database-tools"
    echo ""
    echo "Attempting alternative backup method..."
    
    # Alternative: Use mongoexport for collections
    if command -v mongoexport &> /dev/null; then
        echo -e "${CYAN}Using mongoexport for backup...${NC}"
        
        mkdir -p "$BACKUP_PATH"
        
        # Export status_checks collection
        echo -e "${CYAN}Exporting status_checks collection...${NC}"
        mongoexport --uri="$MONGODB_URI" --collection=status_checks --out="$BACKUP_PATH/status_checks.json"
        
        # Create backup info
        cat > "$BACKUP_PATH/backup_info.json" << EOF
{
  "backup_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "database": "$DB_NAME",
  "method": "mongoexport",
  "collections": ["status_checks"]
}
EOF
        
        echo -e "${GREEN}✅ Backup completed using mongoexport${NC}"
    else
        echo -e "${RED}❌ No MongoDB tools available for backup${NC}"
        exit 1
    fi
else
    # Use mongodump for full backup
    echo -e "${CYAN}Creating backup with mongodump...${NC}"
    
    if mongodump --uri="$MONGODB_URI" --out="$BACKUP_PATH"; then
        echo -e "${GREEN}✅ Backup completed successfully${NC}"
    else
        echo -e "${RED}❌ Backup failed${NC}"
        exit 1
    fi
fi

# Compress backup
echo -e "${CYAN}Compressing backup...${NC}"
cd "$BACKUP_DIR"
tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"

BACKUP_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)
echo -e "${GREEN}✅ Backup compressed: ${BACKUP_NAME}.tar.gz (${BACKUP_SIZE})${NC}"

# Clean up old backups (keep last 7 days)
echo -e "${CYAN}Cleaning up old backups...${NC}"
find . -name "global_radio_backup_*.tar.gz" -mtime +7 -delete 2>/dev/null || true

BACKUP_COUNT=$(ls -1 global_radio_backup_*.tar.gz 2>/dev/null | wc -l)
echo -e "${GREEN}✅ Total backups: $BACKUP_COUNT${NC}"

cd - > /dev/null

echo ""
echo "============================"
echo -e "${GREEN}✅ Database backup completed${NC}"
echo -e "${CYAN}Backup file: $BACKUP_DIR/${BACKUP_NAME}.tar.gz${NC}"
echo ""
echo -e "${YELLOW}To restore backup:${NC}"
echo "  1. Extract: tar -xzf ${BACKUP_NAME}.tar.gz"
echo "  2. Restore: mongorestore --uri=\"\$MONGODB_URI\" ${BACKUP_NAME}/"