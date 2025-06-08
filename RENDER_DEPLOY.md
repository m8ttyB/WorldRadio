# Global Radio - Render.com Deployment Guide

This guide provides step-by-step instructions for deploying Global Radio to Render.com using the provided `render.yaml` blueprint.

## 🚀 Quick Deploy

### Option 1: One-Click Deploy (Recommended)

1. Fork this repository to your GitHub account
2. Create a [Render.com](https://render.com) account
3. Click "New" → "Blueprint" in your Render dashboard
4. Connect your GitHub repository
5. Render will automatically detect the `render.yaml` file and deploy both services

### Option 2: Manual Setup

1. Create backend service manually
2. Create frontend service manually  
3. Configure environment variables

## 📋 Prerequisites

### 1. MongoDB Atlas Setup (Required)

Since Render doesn't offer managed MongoDB, you'll need MongoDB Atlas:

1. Go to [MongoDB Atlas](https://cloud.mongodb.com/)
2. Create a free account and cluster
3. Create a database user with read/write permissions
4. Get your connection string (format: `mongodb+srv://username:password@cluster.mongodb.net/`)
5. Whitelist Render's IP ranges or use `0.0.0.0/0` (all IPs)

### 2. GitHub Repository

- Ensure your code is in a GitHub repository
- The repository should have the `render.yaml` file in the root

## 🔧 Environment Variables

### Backend Environment Variables

Set these in your Render backend service:

| Variable | Value | Description |
|----------|--------|-------------|
| `MONGO_URL` | `mongodb+srv://user:pass@cluster.mongodb.net/global_radio` | MongoDB Atlas connection string |
| `DB_NAME` | `global_radio` | Database name |
| `PYTHON_VERSION` | `3.11.0` | Python runtime version |
| `LOG_LEVEL` | `INFO` | Logging level |
| `DEBUG` | `false` | Debug mode (production) |

### Frontend Environment Variables

Set these in your Render frontend service:

| Variable | Value | Description |
|----------|--------|-------------|
| `REACT_APP_BACKEND_URL` | Auto-configured | Backend service URL |
| `NODE_VERSION` | `18` | Node.js version |
| `GENERATE_SOURCEMAP` | `false` | Disable sourcemaps for production |
| `CI` | `false` | Disable CI warnings |

## 📁 Deployment Structure

```
render.yaml defines:
├── global-radio-backend (Web Service)
│   ├── Python environment
│   ├── FastAPI application
│   └── Health check at /api/
│
└── global-radio-frontend (Static Site)
    ├── React build
    ├── SPA routing
    └── Security headers
```

## 🚀 Deployment Steps

### Step 1: Prepare MongoDB Atlas

1. **Create Cluster**:
   ```
   - Go to MongoDB Atlas
   - Create new project: "Global Radio"
   - Build cluster (free tier)
   - Choose region closest to your users
   ```

2. **Create Database User**:
   ```
   - Go to Database Access
   - Add new user
   - Username: global_radio_user
   - Auto-generate password
   - Grant read/write access
   ```

3. **Configure Network Access**:
   ```
   - Go to Network Access
   - Add IP: 0.0.0.0/0 (allow from anywhere)
   - Or use Render's specific IP ranges
   ```

4. **Get Connection String**:
   ```
   - Go to Clusters → Connect
   - Choose "Connect your application"
   - Copy connection string
   - Replace <password> with your actual password
   ```

### Step 2: Deploy to Render

1. **Login to Render**:
   - Go to [render.com](https://render.com)
   - Sign up/login with GitHub

2. **Create New Blueprint**:
   ```
   - Click "New" → "Blueprint"
   - Connect GitHub repository
   - Select your Global Radio repository
   - Render detects render.yaml automatically
   ```

3. **Configure Services**:
   ```
   - Review service configuration
   - Both frontend and backend should be detected
   - Verify build commands and start commands
   ```

4. **Set Environment Variables**:
   ```
   Backend:
   - MONGO_URL: <your-mongodb-atlas-connection-string>
   - DB_NAME: global_radio
   
   Frontend:
   - REACT_APP_BACKEND_URL: (auto-configured from backend service)
   ```

5. **Deploy**:
   ```
   - Click "Apply"
   - Render will build and deploy both services
   - Monitor build logs for any issues
   ```

### Step 3: Verify Deployment

1. **Check Backend**:
   ```bash
   curl https://your-backend-url.onrender.com/api/
   # Should return: {"message": "Hello World"}
   
   curl https://your-backend-url.onrender.com/api/radio/stations/popular?limit=3
   # Should return array of radio stations
   ```

2. **Check Frontend**:
   ```
   - Visit your frontend URL
   - Verify radio stations load
   - Test search functionality
   - Test favorites system
   ```

## 🔧 Troubleshooting

### Common Issues

1. **Backend Health Check Fails**:
   ```
   - Check MONGO_URL is correctly set
   - Verify MongoDB Atlas network access
   - Check build logs for Python errors
   ```

2. **Frontend Shows API Errors**:
   ```
   - Verify REACT_APP_BACKEND_URL is set
   - Check CORS configuration in backend
   - Ensure backend service is running
   ```

3. **Build Failures**:
   ```
   Backend:
   - Check requirements.txt has all dependencies
   - Verify Python version compatibility
   
   Frontend:
   - Check package.json dependencies
   - Verify Node.js version
   - Check for yarn.lock file
   ```

4. **MongoDB Connection Issues**:
   ```
   - Verify connection string format
   - Check database user permissions
   - Confirm network access settings
   - Test connection from MongoDB Compass
   ```

### Debug Commands

```bash
# Check backend health
curl -v https://your-backend-url.onrender.com/api/

# Check frontend routing
curl -v https://your-frontend-url.onrender.com/

# Test API endpoints
curl https://your-backend-url.onrender.com/api/radio/countries
curl https://your-backend-url.onrender.com/api/radio/stations/popular?limit=5
```

## 📊 Service Configuration

### Backend Service (FastAPI)

```yaml
Type: Web Service
Environment: Python 3.11
Build: pip install -r requirements.txt
Start: uvicorn server:app --host 0.0.0.0 --port $PORT
Health Check: /api/
Auto Deploy: Yes
```

### Frontend Service (React)

```yaml
Type: Static Site
Environment: Node.js 18
Build: yarn install && yarn build
Publish: ./build
Routing: SPA (/* → /index.html)
Auto Deploy: Yes
```

## 🌐 Custom Domains (Optional)

1. **Add Custom Domain**:
   ```
   - Go to service settings
   - Add custom domain
   - Configure DNS records as instructed
   ```

2. **SSL Certificate**:
   ```
   - Render provides automatic SSL
   - Certificate auto-renews
   ```

## 📈 Monitoring

### Render Dashboard

- Monitor service status
- View build and deployment logs
- Check resource usage
- Set up notifications

### Application Monitoring

- Backend health check: `/api/`
- Frontend accessibility test
- API response times
- Error tracking

## 💰 Cost Optimization

### Free Tier Limits

- Backend: 750 hours/month (free tier)
- Frontend: Unlimited (static hosting)
- Database: MongoDB Atlas free tier (512MB)

### Scaling Considerations

- Upgrade to paid plans for production
- Consider CDN for global distribution
- Monitor usage and costs

## 🔄 CI/CD

The render.yaml enables automatic deployments:

- **Auto Deploy**: Enabled for main branch
- **Pull Request Previews**: Enabled for frontend
- **Build Notifications**: Available in dashboard
- **Rollback**: Available in deployment history

## 📞 Support

- **Render Support**: [Render Documentation](https://render.com/docs)
- **MongoDB Atlas**: [Atlas Documentation](https://docs.atlas.mongodb.com/)
- **Application Issues**: GitHub repository issues

---

**Deployment Status**: Ready for production deployment with render.yaml blueprint! 🚀