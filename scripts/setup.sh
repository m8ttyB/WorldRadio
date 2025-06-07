#!/bin/bash

# Global Radio Setup Script
# This script sets up the development environment

set -e

echo "🚀 Setting up Global Radio development environment..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.11+ first."
    exit 1
fi

# Check if Yarn is installed
if ! command -v yarn &> /dev/null; then
    echo "📦 Installing Yarn..."
    npm install -g yarn
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
echo "1. Start MongoDB (docker run -d -p 27017:27017 --name mongodb mongo:latest)"
echo "2. Update .env files with your configuration"
echo "3. Start backend: cd backend && source .venv/bin/activate && uvicorn server:app --reload"
echo "4. Start frontend: cd frontend && yarn start"
echo "5. Visit http://localhost:3000"