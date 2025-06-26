# 📻 Global Radio

A minimalist worldwide radio station streaming website that allows users to discover and listen to radio stations from around the globe.

![Global Radio](https://img.shields.io/badge/Status-Live-brightgreen)
![React](https://img.shields.io/badge/React-19.0.0-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.110.1-green)
![Python](https://img.shields.io/badge/Python-3.11-blue)

## ✨ Features

- 🌍 **Worldwide Stations**: Browse radio stations from countries around the world
- 🎵 **Live Streaming**: Click-to-play audio streaming with floating controls
- 🔍 **Real-Time Search**: Type-as-you-search with instant country filtering
- ❤️ **Personal Favorites**: Save and manage favorite stations with persistence
- 📱 **Responsive Design**: Clean, minimalist interface that works on all devices
- ⚡ **Fast Performance**: Optimized with debounced search and smart caching

## 🚀 Tech Stack

### Frontend
- **React 19** - Modern React with hooks and functional components
- **CSS3** - Custom minimalist styling with responsive design
- **HTML5 Audio API** - Native audio streaming capabilities
- **LocalStorage** - Persistent favorites management

### Backend
- **FastAPI** - High-performance Python web framework
- **HTTPX** - Async HTTP client for external API calls
- **Motor** - Async MongoDB driver
- **Uvicorn** - ASGI server

### External APIs
- **Radio Browser API** - Community-driven radio station database

## 📋 Prerequisites

- **Node.js** (v20+ required for React Router v7)
- **Python** (3.11+)
- **Yarn** package manager
- **MongoDB** (for backend data storage)

## 🛠️ Local Development Setup

### Option 1: Docker Compose (Recommended)

The fastest way to get Global Radio running locally:

```bash
# Clone the repository
git clone <repository-url>
cd global-radio

# Start all services
docker compose up -d

# Test the setup
./test-docker.sh

# Access the application
# Frontend: http://localhost:3000
# Backend:  http://localhost:8001
# API Docs: http://localhost:8001/docs
```

**Troubleshooting**: If stations don't load, see [LOCAL_DEV.md](LOCAL_DEV.md) for detailed troubleshooting.

### Option 2: Manual Setup

#### 1. Backend Setup

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

# Development Settings
DEBUG=true
LOG_LEVEL=INFO
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

## 🧪 Testing

### Manual Testing
1. Visit http://localhost:3000 in your browser
2. Verify stations load automatically
3. Test real-time search functionality
4. Test favorites feature
5. Test audio playback
6. Verify responsive design on mobile

### Debug Commands
```bash
# Check backend status
curl http://localhost:8001/api/

# Test API endpoints
curl http://localhost:8001/api/radio/stations/popular
```

## 🔧 Troubleshooting

### Common Issues

1. **CORS Errors**
   - Ensure backend is running on port 8001
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

5. **Frontend Build Issues**
   - Use `yarn` instead of `npm`
   - Clear node_modules and reinstall: `rm -rf node_modules && yarn install`

## 🎵 Using the Application

### Basic Usage
1. **Browse Stations**: View popular worldwide radio stations
2. **Search**: Type in the search box for real-time filtering
3. **Filter by Country**: Select a country from the dropdown
4. **Play Audio**: Click any station card to start streaming
5. **Add Favorites**: Click the heart icon (🤍) to save stations
6. **View Favorites**: Click the "❤️ Favorites" tab

### Features
- **Floating Controls**: Audio controls stay visible in the header while browsing
- **Real-Time Search**: No search button needed - results appear as you type
- **Persistent Favorites**: Your favorites are saved between sessions
- **Responsive Design**: Works on desktop, tablet, and mobile

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow existing code style
- Test changes locally before submitting
- Update documentation as needed
- Ensure responsive design principles

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Radio Browser](https://www.radio-browser.info/) - Community-driven radio station database
- [FastAPI](https://fastapi.tiangolo.com/) - Modern web framework for building APIs
- [React](https://reactjs.org/) - JavaScript library for building user interfaces

---

**Built with ❤️ for radio enthusiasts worldwide** 🌍📻
