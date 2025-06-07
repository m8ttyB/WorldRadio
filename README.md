# 📻 Global Radio

A minimalist worldwide radio station streaming website that allows users to discover and listen to radio stations from around the globe.

![Global Radio](https://img.shields.io/badge/Status-Live-brightgreen)
![React](https://img.shields.io/badge/React-19.0.0-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.110.1-green)
![Python](https://img.shields.io/badge/Python-3.11-blue)

## ✨ Features

- 🌍 **Worldwide Stations**: Browse radio stations from countries around the world
- 🎵 **Live Streaming**: Click-to-play audio streaming with built-in controls
- 🔍 **Smart Search**: Search stations by name or filter by country
- 📱 **Responsive Design**: Clean, minimalist interface that works on all devices
- ⚡ **Fast Loading**: Optimized API with multiple server fallbacks
- 🎛️ **Audio Controls**: Play, pause, stop, and switch between stations seamlessly

## 🚀 Tech Stack

### Frontend
- **React 19** - Modern React with hooks and functional components
- **CSS3** - Custom minimalist styling with responsive design
- **HTML5 Audio API** - Native audio streaming capabilities

### Backend
- **FastAPI** - High-performance Python web framework
- **HTTPX** - Async HTTP client for external API calls
- **Motor** - Async MongoDB driver
- **Uvicorn** - ASGI server for production

### External APIs
- **Radio Browser API** - Community-driven radio station database
- Multiple server endpoints for reliability

## 📋 Prerequisites

- **Node.js** (v18+ recommended)
- **Python** (3.11+)
- **Yarn** package manager
- **MongoDB** (for backend data storage)

## 🛠️ Local Development Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd global-radio
```

### 2. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create environment file
cp .env.example .env

# Edit .env file with your configurations
# Required variables:
# MONGO_URL=mongodb://localhost:27017
# DB_NAME=global_radio
```

#### Environment Variables (.env)
```env
# MongoDB Configuration
MONGO_URL=mongodb://localhost:27017
DB_NAME=global_radio

# Optional: API Keys (if needed)
# RADIO_API_KEY=your_api_key_here
```

### 3. Frontend Setup

```bash
# Navigate to frontend directory
cd ../frontend

# Install dependencies
yarn install

# Create environment file
cp .env.example .env

# Edit .env file:
# REACT_APP_BACKEND_URL=http://localhost:8001
```

#### Frontend Environment Variables (.env)
```env
# Backend API URL
REACT_APP_BACKEND_URL=http://localhost:8001

# WebSocket Configuration
WDS_SOCKET_PORT=443
```

### 4. Database Setup

```bash
# Start MongoDB (if not running)
# Using Docker:
docker run -d -p 27017:27017 --name mongodb mongo:latest

# Or using local MongoDB installation:
mongod --dbpath /path/to/your/db
```

### 5. Start Development Servers

#### Terminal 1 - Backend
```bash
cd backend
source .venv/bin/activate
uvicorn server:app --host 0.0.0.0 --port 8001 --reload
```

#### Terminal 2 - Frontend
```bash
cd frontend
yarn start
```

### 6. Access the Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8001
- **API Documentation**: http://localhost:8001/docs

## 📁 Project Structure

```
global-radio/
├── frontend/                # React frontend application
│   ├── public/             # Static assets
│   ├── src/
│   │   ├── App.js          # Main React component
│   │   ├── App.css         # Component styles
│   │   ├── index.js        # Entry point
│   │   └── index.css       # Global styles
│   ├── package.json        # Frontend dependencies
│   ├── tailwind.config.js  # Tailwind configuration
│   └── .env               # Frontend environment variables
│
├── backend/                # FastAPI backend application
│   ├── server.py          # Main FastAPI application
│   ├── requirements.txt   # Python dependencies
│   └── .env              # Backend environment variables
│
├── tests/                 # Test files
├── scripts/              # Utility scripts
└── README.md             # This file
```

## 🔗 API Endpoints

### Radio Stations
- `GET /api/radio/stations/popular` - Get popular radio stations
- `GET /api/radio/stations/search` - Search stations by name/country
- `GET /api/radio/countries` - Get list of countries with station counts
- `POST /api/radio/stations/{uuid}/click` - Register station click

### System
- `GET /api/` - Health check
- `GET /api/status` - Get system status
- `POST /api/status` - Create status check

### Example API Usage

```bash
# Get popular stations
curl "http://localhost:8001/api/radio/stations/popular?limit=10"

# Search for BBC stations
curl "http://localhost:8001/api/radio/stations/search?name=BBC"

# Filter by country
curl "http://localhost:8001/api/radio/stations/search?country=United%20Kingdom"

# Get countries list
curl "http://localhost:8001/api/radio/countries"
```

## 🚀 Deployment

### Using Docker (Recommended)

#### 1. Create Docker Files

**Dockerfile.backend**
```dockerfile
FROM python:3.11-slim

WORKDIR /app
COPY backend/requirements.txt .
RUN pip install -r requirements.txt

COPY backend/ .
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8001"]
```

**Dockerfile.frontend**
```dockerfile
FROM node:18-alpine as builder

WORKDIR /app
COPY frontend/package.json frontend/yarn.lock ./
RUN yarn install

COPY frontend/ .
RUN yarn build

FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
```

#### 2. Docker Compose

**docker-compose.yml**
```yaml
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile.backend
    ports:
      - "8001:8001"
    environment:
      - MONGO_URL=mongodb://mongodb:27017
      - DB_NAME=global_radio
    depends_on:
      - mongodb

  frontend:
    build:
      context: .
      dockerfile: Dockerfile.frontend
    ports:
      - "3000:80"
    environment:
      - REACT_APP_BACKEND_URL=http://localhost:8001

  mongodb:
    image: mongo:latest
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db

volumes:
  mongodb_data:
```

#### 3. Deploy

```bash
# Build and start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Manual Deployment

#### 1. Server Setup
```bash
# Install dependencies
sudo apt update
sudo apt install python3 python3-pip nodejs npm nginx mongodb

# Install yarn
npm install -g yarn

# Install PM2 for process management
npm install -g pm2
```

#### 2. Application Deployment
```bash
# Clone and setup
git clone <repository-url> /var/www/global-radio
cd /var/www/global-radio

# Backend setup
cd backend
pip install -r requirements.txt

# Frontend build
cd ../frontend
yarn install
yarn build

# Start services with PM2
pm2 start ecosystem.config.js
```

#### 3. Nginx Configuration

**nginx.conf**
```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Frontend
    location / {
        root /var/www/global-radio/frontend/build;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Environment Variables for Production

**Backend (.env)**
```env
MONGO_URL=mongodb://localhost:27017
DB_NAME=global_radio_prod
```

**Frontend (.env.production)**
```env
REACT_APP_BACKEND_URL=https://your-domain.com
```

## 🧪 Testing

### Run Tests
```bash
# Backend tests
cd backend
python -m pytest

# Frontend tests  
cd frontend
yarn test
```

### Manual Testing
1. Visit the application in your browser
2. Verify stations load automatically
3. Test search functionality
4. Test audio playback
5. Verify responsive design on mobile

## 🔧 Troubleshooting

### Common Issues

1. **CORS Errors**
   - Ensure backend is running on correct port
   - Check REACT_APP_BACKEND_URL configuration

2. **No Stations Loading**
   - Verify backend API endpoints are responding
   - Check network connectivity
   - Review backend logs for errors

3. **Audio Not Playing**
   - Some radio streams may be offline (normal)
   - Check browser audio permissions
   - Try different stations

4. **MongoDB Connection Failed**
   - Ensure MongoDB is running
   - Check MONGO_URL configuration
   - Verify database permissions

### Debug Commands
```bash
# Check backend status
curl http://localhost:8001/api/

# View backend logs
tail -f backend/logs/app.log

# Check frontend build
cd frontend && yarn build

# Test API endpoints
curl http://localhost:8001/api/radio/stations/popular
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow existing code style
- Add tests for new features
- Update documentation as needed
- Ensure responsive design principles

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Radio Browser](https://www.radio-browser.info/) - Community-driven radio station database
- [FastAPI](https://fastapi.tiangolo.com/) - Modern web framework for building APIs
- [React](https://reactjs.org/) - JavaScript library for building user interfaces

## 📞 Support

For support, please open an issue on GitHub or contact the development team.

---

**Built with ❤️ for radio enthusiasts worldwide** 🌍📻
