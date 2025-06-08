# 🐳 Global Radio - Local Docker Development Guide

This guide provides instructions for running Global Radio locally using Docker Compose.

## 🚀 Quick Start

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/) (>= 20.0)
- [Docker Compose](https://docs.docker.com/compose/install/) (>= 2.0)
- Git

### 1. Clone Repository
```bash
git clone <repository-url>
cd global-radio
```

### 2. Start Services
```bash
# Start all services in detached mode
docker compose up -d

# Or start with logs visible
docker compose up
```

### 3. Access Application
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8001
- **API Documentation**: http://localhost:8001/docs
- **MongoDB**: localhost:27017

## 📋 Available Commands

### Basic Operations
```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# View logs for specific service
docker compose logs -f frontend
docker compose logs -f backend
docker compose logs -f mongodb
```

### Development Commands
```bash
# Rebuild and start (after code changes)
docker compose up --build

# Rebuild specific service
docker compose build frontend
docker compose build backend

# Restart specific service
docker compose restart frontend
docker compose restart backend

# Check service status
docker compose ps

# Execute commands in running containers
docker compose exec backend bash
docker compose exec frontend sh
docker compose exec mongodb mongosh
```

### Database Operations
```bash
# Access MongoDB shell
docker compose exec mongodb mongosh

# View database contents
docker compose exec mongodb mongosh --eval "use global_radio; db.status_checks.find()"

# Reset database
docker compose down -v  # This removes volumes (data will be lost)
docker compose up -d
```

## 🔧 Troubleshooting

### Frontend Not Loading Stations

**Symptoms**: Frontend loads but shows "Loading stations..." or "No stations found"

**Solutions**:

1. **Check Backend Health**:
   ```bash
   curl http://localhost:8001/api/
   # Should return: {"message": "Hello World"}
   
   curl http://localhost:8001/api/radio/stations/popular?limit=3
   # Should return JSON array of stations
   ```

2. **Check Frontend Environment**:
   ```bash
   # Verify REACT_APP_BACKEND_URL is correct
   docker compose exec frontend env | grep REACT_APP_BACKEND_URL
   ```

3. **Check Network Connectivity**:
   ```bash
   # Test from frontend container to backend
   docker compose exec frontend curl -f http://backend:8001/api/
   ```

4. **Restart Services**:
   ```bash
   docker compose restart frontend backend
   ```

### Backend API Errors

**Symptoms**: 500 errors, MongoDB connection issues

**Solutions**:

1. **Check MongoDB Connection**:
   ```bash
   # Test MongoDB connectivity
   docker compose exec backend python -c "
   import motor.motor_asyncio
   import asyncio
   async def test():
       client = motor.motor_asyncio.AsyncIOMotorClient('mongodb://mongodb:27017')
       await client.admin.command('ping')
       print('MongoDB connected successfully')
   asyncio.run(test())
   "
   ```

2. **Check Backend Logs**:
   ```bash
   docker compose logs backend
   ```

3. **Reset Backend**:
   ```bash
   docker compose restart backend mongodb
   ```

### Build Issues

**Symptoms**: Docker build failures, dependency issues

**Solutions**:

1. **Clean Build**:
   ```bash
   # Remove all containers and rebuild
   docker compose down
   docker compose build --no-cache
   docker compose up -d
   ```

2. **Clear Docker Cache**:
   ```bash
   docker system prune -a
   docker volume prune
   ```

3. **Check Dockerfile Issues**:
   ```bash
   # Build individual services for better error visibility
   docker build -f Dockerfile.backend -t global-radio-backend .
   docker build -f Dockerfile.frontend.dev -t global-radio-frontend .
   ```

### Port Conflicts

**Symptoms**: "Port already in use" errors

**Solutions**:

1. **Check Running Services**:
   ```bash
   # Check what's using the ports
   netstat -tulpn | grep -E "(3000|8001|27017)"
   ```

2. **Stop Conflicting Services**:
   ```bash
   # Stop local development servers
   sudo supervisorctl stop frontend backend mongodb
   ```

3. **Use Different Ports**:
   ```bash
   # Edit docker-compose.yml to use different ports
   # Change "3000:3000" to "3001:3000" for frontend
   # Change "8001:8001" to "8002:8001" for backend
   ```

## 📁 File Structure

### Development Files
```
global-radio/
├── docker-compose.yml          # Main Docker Compose configuration
├── docker-compose.dev.yml      # Development-specific configuration
├── Dockerfile.backend          # Backend production Dockerfile
├── Dockerfile.frontend.dev     # Frontend development Dockerfile
├── Dockerfile.frontend         # Frontend production Dockerfile
└── LOCAL_DEV.md                # This file
```

### Configuration Files
```
├── frontend/.env.local         # Frontend development environment
├── frontend/.env              # Frontend production environment
├── backend/.env               # Backend environment (create from .env.example)
└── .env.example               # Environment template
```

## ⚙️ Configuration

### Environment Variables

**Backend** (set in docker-compose.yml):
```env
MONGO_URL=mongodb://mongodb:27017
DB_NAME=global_radio
```

**Frontend** (set in frontend/.env.local):
```env
REACT_APP_BACKEND_URL=http://localhost:3000
GENERATE_SOURCEMAP=true
CI=false
```

### Development vs Production

| Aspect | Development | Production |
|--------|-------------|------------|
| Frontend Dockerfile | `Dockerfile.frontend.dev` | `Dockerfile.frontend` |
| Frontend Server | React Dev Server (3000) | Nginx (80) |
| Hot Reload | ✅ Enabled | ❌ Disabled |
| Source Maps | ✅ Generated | ❌ Disabled |
| Volume Mounting | ✅ Code mounted | ❌ Code copied |

## 🔄 Development Workflow

### Making Code Changes

1. **Frontend Changes**:
   ```bash
   # Frontend has hot reload - changes appear automatically
   # Edit files in frontend/src/
   ```

2. **Backend Changes**:
   ```bash
   # Backend auto-reloads on file changes
   # Edit files in backend/
   ```

3. **Dependency Changes**:
   ```bash
   # Rebuild after adding new dependencies
   docker compose build frontend  # if package.json changed
   docker compose build backend   # if requirements.txt changed
   docker compose up -d
   ```

### Testing API Endpoints

```bash
# Health check
curl http://localhost:8001/api/

# Get popular stations
curl http://localhost:8001/api/radio/stations/popular?limit=5

# Search stations
curl "http://localhost:8001/api/radio/stations/search?name=BBC"

# Get countries
curl http://localhost:8001/api/radio/countries
```

### Database Management

```bash
# View collections
docker compose exec mongodb mongosh --eval "use global_radio; show collections"

# View status checks
docker compose exec mongodb mongosh --eval "use global_radio; db.status_checks.find().pretty()"

# Clear status checks
docker compose exec mongodb mongosh --eval "use global_radio; db.status_checks.deleteMany({})"
```

## 🚨 Common Issues & Solutions

### Issue: "CORS Error"
**Solution**: Ensure `REACT_APP_BACKEND_URL=http://localhost:8001` in frontend environment

### Issue: "Cannot connect to MongoDB"
**Solution**: Check if MongoDB container is running: `docker compose ps mongodb`

### Issue: "Module not found"
**Solution**: Rebuild containers: `docker compose build --no-cache`

### Issue: "Port 3000 already in use"
**Solution**: Stop other services: `sudo supervisorctl stop frontend`

### Issue: "No stations loading"
**Solution**: Check backend API: `curl http://localhost:8001/api/radio/stations/popular`

## 📞 Getting Help

1. **Check Logs**: `docker compose logs -f`
2. **Verify Health**: `curl http://localhost:8001/api/`
3. **Restart Services**: `docker compose restart`
4. **Clean Rebuild**: `docker compose down && docker compose up --build`

---

**Happy Developing! 🎉📻**