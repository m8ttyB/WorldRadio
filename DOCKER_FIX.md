# Docker Compose Node.js Version Fix

## Issue
Docker Compose build was failing with this error:
```
error react-router-dom@7.5.1: The engine "node" is incompatible with this module. Expected version ">=20.0.0". Got "18.20.8"
```

## Root Cause
React Router DOM v7.5.1 requires Node.js version 20 or higher, but the Docker configuration was using Node.js 18.

## Files Updated

### 1. Dockerfile.frontend
**Changed:** `FROM node:18-alpine as builder`
**To:** `FROM node:20-alpine as builder`

### 2. scripts/setup.sh
- Updated Node.js requirement message from "18+" to "20+"
- Added Node.js version check to ensure v20 or higher

### 3. README.md
- Updated prerequisites to specify Node.js v20+ requirement
- Added note about React Router v7 compatibility

### 4. terraform/main.tf
- Updated NODE_VERSION from "18" to "20" in deployment configuration

## Quick Fix
Run this command to rebuild with the correct Node.js version:

```bash
# Clear Docker cache and rebuild
docker-compose down
docker system prune -f
docker-compose up --build
```

## For Local Development
If you're developing locally, ensure you have Node.js 20+:

```bash
# Check your Node.js version
node --version

# If you need to upgrade (using nvm)
nvm install 20
nvm use 20

# Or install directly
# macOS: brew install node@20
# Ubuntu: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs
```

The application should now build successfully with Docker Compose! 🚀