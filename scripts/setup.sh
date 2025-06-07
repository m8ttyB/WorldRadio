#!/bin/bash

# Global Radio - Local Development Setup Script
# This script sets up the development environment for local use

set -e

echo "🚀 Setting up Global Radio for local development..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    echo "Visit: https://nodejs.org/"
    exit 1
fi

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.11+ first."
    echo "Visit: https://www.python.org/"
    exit 1
fi

# Check if Yarn is installed
if ! command -v yarn &> /dev/null; then
    echo "📦 Installing Yarn..."
    npm install -g yarn
fi

# Check if MongoDB is running
if ! command -v mongod &> /dev/null && ! docker ps | grep -q mongodb; then
    echo "⚠️  MongoDB not found. You'll need to start MongoDB:"
    echo "   Option 1: Install MongoDB locally"
    echo "   Option 2: Run with Docker: docker run -d -p 27017:27017 --name mongodb mongo:latest"
fi

# Setup backend
echo "🐍 Setting up backend..."
cd backend

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

# Install Python dependencies
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    cp ../.env.example .env
    echo "📝 Created backend .env file. Please update it with your configuration."
fi

cd ..

# Setup frontend
echo "⚛️ Setting up frontend..."
cd frontend

# Install Node.js dependencies
yarn install

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "📝 Created frontend .env file. Please update it with your configuration."
fi

cd ..

echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Start MongoDB:"
echo "   • Local: mongod --dbpath /path/to/your/db"
echo "   • Docker: docker run -d -p 27017:27017 --name mongodb mongo:latest"
echo ""
echo "2. Start backend (Terminal 1):"
echo "   cd backend && source .venv/bin/activate && uvicorn server:app --host 0.0.0.0 --port 8001 --reload"
echo ""
echo "3. Start frontend (Terminal 2):"
echo "   cd frontend && yarn start"
echo ""
echo "4. Visit http://localhost:3000"
echo ""
echo "🎉 Happy coding!"