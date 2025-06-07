#!/bin/bash

# Global Radio - Local Development Helper
# Quick start script for local development

set -e

echo "🚀 Starting Global Radio locally..."

# Check if MongoDB is running
if ! pgrep -x "mongod" > /dev/null && ! docker ps | grep -q mongodb; then
    echo "📦 Starting MongoDB with Docker..."
    docker run -d -p 27017:27017 --name mongodb mongo:latest
    echo "⏳ Waiting for MongoDB to start..."
    sleep 3
fi

echo "✅ MongoDB is running"

echo "📋 To start the application:"
echo ""
echo "Terminal 1 - Backend:"
echo "cd backend && source .venv/bin/activate && uvicorn server:app --host 0.0.0.0 --port 8001 --reload"
echo ""
echo "Terminal 2 - Frontend:"
echo "cd frontend && yarn start"
echo ""
echo "Then visit: http://localhost:3000"