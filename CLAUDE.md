# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Frontend (React)
```bash
cd frontend
yarn start                    # Development server on http://localhost:3000
yarn build                    # Production build
yarn test                     # Run tests
```

### Backend (FastAPI)
```bash
cd backend
source .venv/bin/activate     # Activate virtual environment
uvicorn server:app --host 0.0.0.0 --port 8001 --reload  # Development server
black .                       # Format Python code
pytest                        # Run tests (if configured)
```

### Docker Development
```bash
docker-compose up             # Start all services
docker-compose up --build     # Build and start services
docker-compose down           # Stop services
```

### Make Commands (Comprehensive)
```bash
make help                     # Display all available commands
make setup                    # Initial project setup
make deploy-all              # Complete deployment
make local-test              # Test deployment locally
make status                  # Check application status
make logs-backend            # View backend logs
make logs-frontend           # View frontend logs
```

### Quick Setup
```bash
./scripts/setup.sh           # Automated setup script
make setup                    # Alternative setup command
```

## Architecture Overview

**Application Type**: Full-stack worldwide radio streaming platform

**Technology Stack**:
- Frontend: React 19, Tailwind CSS, HTML5 Audio API
- Backend: FastAPI (Python 3.11+), HTTPX for external API calls
- External API: Radio Browser API for all station data
- Storage: Client-side LocalStorage for favorites

**Key Components**:
- `frontend/src/App.js` - Main React component with radio streaming logic
- `backend/server.py` - FastAPI application with radio API endpoints
- `docker-compose.yml` - Multi-container local development setup
- `deploy/terraform/` - Infrastructure as Code for Render.com deployment

## Development Environment Setup

**Prerequisites**: Node.js 20+, Python 3.11+, Yarn

**Environment Files**:
- `backend/.env` - Backend configuration (DEBUG, LOG_LEVEL)
- `frontend/.env` - Frontend configuration (REACT_APP_BACKEND_URL)

**Development Servers**:
- Frontend: http://localhost:3000 (React dev server)
- Backend: http://localhost:8001 (FastAPI with auto-reload)
- API Docs: http://localhost:8001/docs (FastAPI auto-generated docs)

## Key API Endpoints
- `GET /api/radio/stations/popular` - Popular radio stations
- `GET /api/radio/stations/search` - Search stations by name/country
- `GET /api/radio/countries` - Countries with station counts
- `POST /api/radio/stations/{uuid}/click` - Register station click

## Application Features
- Real-time search with debouncing
- Persistent favorites via LocalStorage
- HTML5 audio streaming with floating controls
- Responsive design with Tailwind CSS
- Country-based filtering
- Multi-server Radio Browser API fallback

## Project Structure Notes
- `frontend/` - React SPA with single main component pattern
- `backend/` - Stateless FastAPI proxy to Radio Browser API
- `deploy/` - Terraform configuration for cloud deployment
- `scripts/` - Automation scripts for development and deployment

## Testing
- Frontend: Uses Create React App test runner
- Backend: pytest framework available
- API Testing: `./deploy/scripts/test-api.sh`
- Manual testing checklist available in README.md

## Deployment
- **Local**: Docker Compose for full-stack development
- **Production**: Render.com via Terraform infrastructure
- **Configuration**: `render.yaml` blueprint with multi-service deployment