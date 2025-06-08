# 🚀 Global Radio - Cloud Deployment Guide

This guide provides step-by-step instructions for deploying the Global Radio application to popular cloud platforms.

## 📋 Table of Contents

- [Render.com (Recommended)](#rendercom-recommended)
- [Digital Ocean](#digital-ocean)
- [Google Cloud Platform (GCP)](#google-cloud-platform-gcp)
- [Environment Variables Reference](#environment-variables-reference)
- [Post-Deployment Checklist](#post-deployment-checklist)

---

## 🎨 Render.com (Recommended)

Render.com is a modern cloud platform with automatic builds and deployments from Git. **This is the recommended deployment method** as we provide a complete `render.yaml` blueprint.

### Quick Deploy with Blueprint

1. **Fork Repository**: Fork this repository to your GitHub account
2. **Create MongoDB Atlas**: Set up a free MongoDB Atlas cluster (see instructions below)
3. **Deploy to Render**: 
   - Go to [Render Dashboard](https://dashboard.render.com)
   - Click "New" → "Blueprint"
   - Connect your GitHub repository
   - Render will automatically use the `render.yaml` configuration
4. **Set Environment Variables**: Add your MongoDB Atlas connection string
5. **Deploy**: Click "Apply" - Done! 🎉

### MongoDB Atlas Setup (Required)

Since Render doesn't offer managed MongoDB:

1. Go to [MongoDB Atlas](https://cloud.mongodb.com/)
2. Create a free cluster (512MB free tier)
3. Create a database user with read/write permissions
4. Whitelist IP addresses (use `0.0.0.0/0` for all IPs)
5. Get connection string: `mongodb+srv://username:password@cluster.mongodb.net/global_radio`

### Environment Variables for Render

**Backend Service:**
```
MONGO_URL=mongodb+srv://username:password@cluster.mongodb.net/global_radio
DB_NAME=global_radio
PYTHON_VERSION=3.11.0
```

**Frontend Service:**
```
REACT_APP_BACKEND_URL=https://your-backend-service.onrender.com
NODE_VERSION=18
```

### Services Configuration

The `render.yaml` blueprint creates:

- **Backend**: FastAPI service with Python 3.11
- **Frontend**: Static site with React build
- **Auto Deploy**: Enabled from main branch
- **Health Checks**: Configured for backend
- **Security Headers**: Configured for frontend

For detailed Render deployment instructions, see [RENDER_DEPLOY.md](RENDER_DEPLOY.md).

---

## 🌊 Digital Ocean

Digital Ocean offers multiple deployment options: App Platform, Droplets, and Kubernetes.

### Option A: App Platform (Recommended for DO)

#### Prerequisites
- Digital Ocean account
- GitHub repository

#### 1. Database Setup

Create a MongoDB database cluster:
- Go to Digital Ocean Dashboard → Databases
- Create MongoDB cluster (or use MongoDB Atlas)
- Note the connection details

#### 2. Deploy Application

1. **Create App**:
   - Go to Apps → Create App
   - Connect GitHub repository
   - Configure components:

**Backend Component:**
```yaml
Name: backend
Type: Web Service
Source Directory: /backend
Build Command: pip install -r requirements.txt
Run Command: uvicorn server:app --host 0.0.0.0 --port $PORT
```

**Frontend Component:**
```yaml
Name: frontend
Type: Static Site
Source Directory: /frontend
Build Command: yarn install && yarn build
Output Directory: build
```

2. **Environment Variables**:

**Backend:**
```
MONGO_URL=mongodb://username:password@your-db-host:27017/global_radio
DB_NAME=global_radio
```

**Frontend:**
```
REACT_APP_BACKEND_URL=https://your-app-name.ondigitalocean.app
```

### Option B: Droplets (VPS)

#### 1. Create Droplet

```bash
# Create Ubuntu 22.04 droplet (minimum $6/month)
# SSH into the server
ssh root@your-droplet-ip
```

#### 2. Server Setup

```bash
# Update system
apt update && apt upgrade -y

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Nginx
apt install nginx -y

# Clone your repository
git clone https://github.com/yourusername/global-radio.git /var/www/global-radio
cd /var/www/global-radio
```

#### 3. Configure Environment

```bash
# Create environment files
cp .env.example .env
cp frontend/.env.example frontend/.env

# Edit environment variables
nano .env
nano frontend/.env
```

#### 4. Deploy with Docker

```bash
# Start services
docker-compose up -d

# Check status
docker-compose ps
```

#### 5. Nginx Configuration

```bash
# Create site configuration
nano /etc/nginx/sites-available/global-radio
```

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:8001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable site
ln -s /etc/nginx/sites-available/global-radio /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# Install SSL certificate
apt install certbot python3-certbot-nginx -y
certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

---

## ☁️ Google Cloud Platform (GCP)

GCP offers multiple deployment options. We'll use Cloud Run for simplicity and cost-effectiveness.

### Prerequisites
- GCP account with billing enabled
- Google Cloud SDK installed locally

### 1. Setup GCP Project

```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Login and create project
gcloud auth login
gcloud projects create global-radio-app --name="Global Radio"
gcloud config set project global-radio-app

# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable sqladmin.googleapis.com
```

### 2. Database Setup

Since GCP doesn't offer managed MongoDB, use MongoDB Atlas (follow setup from Render section).

### 3. Backend Deployment (Cloud Run)

#### Prepare Dockerfile
Create `backend/Dockerfile.gcp`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Run on Cloud Run port
CMD exec uvicorn server:app --host 0.0.0.0 --port $PORT
```

#### Deploy Backend

```bash
# Build and deploy
cd backend
gcloud builds submit --tag gcr.io/global-radio-app/backend
gcloud run deploy global-radio-backend \
  --image gcr.io/global-radio-app/backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars MONGO_URL=your-mongodb-atlas-url,DB_NAME=global_radio

# Get backend URL
gcloud run services describe global-radio-backend --region us-central1 --format 'value(status.url)'
```

### 4. Frontend Deployment (Firebase Hosting)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize Firebase
cd frontend
firebase login
firebase init hosting

# Configure firebase.json
```

**firebase.json:**
```json
{
  "hosting": {
    "public": "build",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

```bash
# Set environment variable and build
echo "REACT_APP_BACKEND_URL=https://your-backend-url.run.app" > .env.production
yarn build

# Deploy
firebase deploy
```

### 5. Custom Domain (Optional)

#### Backend Domain (Cloud Run):
```bash
gcloud run domain-mappings create \
  --service global-radio-backend \
  --domain api.yourdomain.com \
  --region us-central1
```

#### Frontend Domain (Firebase):
```bash
firebase hosting:channel:deploy live --site yourdomain.com
```

### 6. Monitoring and Logging

```bash
# View backend logs
gcloud run services logs read global-radio-backend --region us-central1

# Set up monitoring
gcloud services enable monitoring.googleapis.com
```

---

## 🔧 Environment Variables Reference

### Backend Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `MONGO_URL` | MongoDB connection string | `mongodb+srv://user:pass@cluster.mongodb.net/` |
| `DB_NAME` | Database name | `global_radio` |
| `LOG_LEVEL` | Logging level | `INFO` |
| `DEBUG` | Debug mode | `false` |

### Frontend Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `REACT_APP_BACKEND_URL` | Backend API URL | `https://api.yourdomain.com` |

---

## ⚙️ Environment Configuration

### Backend Environment Variables
```env
# Database
MONGO_URL=mongodb+srv://user:pass@cluster.mongodb.net/global_radio
DB_NAME=global_radio

# Application
ENVIRONMENT=production
LOG_LEVEL=INFO
DEBUG=false

# API Configuration
API_KEY=your-optional-api-key
CORS_ORIGINS=https://yourapp.onrender.com
```

### Frontend Environment Variables
```env
# Backend API URL
REACT_APP_BACKEND_URL=https://yourapp-api.onrender.com

# Optional: Analytics
REACT_APP_ANALYTICS_ID=GA-XXXXXXXXXX
```

### Deployment Environment Variables
```env
# Render.com
RENDER_API_KEY=your-render-api-key

# Application
APP_NAME=global-radio
BACKEND_SERVICE_NAME=global-radio-api
FRONTEND_SERVICE_NAME=global-radio-web

# GitHub
GITHUB_REPO_URL=https://github.com/yourusername/global-radio
GITHUB_BRANCH=main

# Database
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/global_radio

# Domains (optional)
FRONTEND_DOMAIN=radio.yourdomain.com
BACKEND_DOMAIN=api.radio.yourdomain.com
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The deployment includes automated CI/CD:

```yaml
# .github/workflows/deploy.yml
name: Deploy to Render
on:
  push:
    branches: [main]
  
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy Infrastructure
        run: make deploy-ci
        env:
          RENDER_API_KEY: ${{ secrets.RENDER_API_KEY }}
          MONGODB_URI: ${{ secrets.MONGODB_URI }}
```

### Deployment Stages
1. **Code Push** → GitHub repository
2. **Auto-trigger** → Render.com build
3. **Backend Deploy** → API service update
4. **Frontend Deploy** → Static site update
5. **Health Check** → Verify deployment

---

## 📊 Monitoring & Maintenance

### Health Checks
```bash
# Check application status
make health-check

# View service logs
make logs-backend
make logs-frontend

# Monitor resource usage
make status
```

### Render.com Dashboard
- **Services**: Monitor backend and frontend services
- **Metrics**: CPU, memory, request rates
- **Logs**: Real-time application logs
- **Deployments**: Deployment history and rollbacks

### Automated Monitoring
```bash
# Setup monitoring alerts
make setup-monitoring

# Check service health every 5 minutes
*/5 * * * * /path/to/global-radio/deploy/scripts/health-check.sh
```

---

## 🔧 Maintenance Tasks

### Updates & Scaling
```bash
# Update application
git push origin main  # Auto-deploys

# Scale backend service
make scale-backend INSTANCES=2

# Update environment variables
make update-env

# Rollback deployment
make rollback
```

### Database Maintenance
```bash
# Backup database
make backup-db

# Monitor database metrics
make db-status

# Optimize database
make db-optimize
```

---

## 🚨 Troubleshooting

### Common Issues

1. **Deployment Fails**
   ```bash
   # Check build logs
   make logs-build
   
   # Verify environment variables
   make check-env
   
   # Retry deployment
   make retry-deploy
   ```

2. **Application Not Loading**
   ```bash
   # Check service status
   make status
   
   # Verify health endpoints
   curl https://yourapp-api.onrender.com/api/
   
   # Check environment variables
   make env-status
   ```

3. **Database Connection Issues**
   ```bash
   # Test database connection
   make test-db
   
   # Check MongoDB Atlas network access
   # Verify connection string format
   # Ensure IP whitelist includes 0.0.0.0/0
   ```

4. **Build Errors**
   ```bash
   # Check Node.js version (use 18.x)
   # Verify Python version (use 3.11)
   # Check dependencies in package.json/requirements.txt
   ```

### Debug Commands
```bash
# Enable debug mode
make debug-enable

# View detailed logs
make logs-detailed

# Check service configuration
make config-check

# Test API endpoints
make test-api
```

### Performance Issues
```bash
# Monitor response times
make monitor-performance

# Check resource usage
make resource-status

# Optimize application
make optimize
```

---

## 🔐 Security Best Practices

### Environment Variables
- Never commit secrets to Git
- Use Render's environment variable encryption
- Rotate API keys regularly
- Use different keys for staging/production

### Database Security
- Enable MongoDB Atlas IP whitelisting
- Use strong database passwords
- Enable database authentication
- Regular security updates

### Application Security
- Enable HTTPS (automatic on Render)
- Set proper CORS origins
- Use security headers
- Regular dependency updates

---

## 📈 Scaling & Performance

### Horizontal Scaling
```bash
# Scale backend instances
make scale-backend INSTANCES=3

# Auto-scaling configuration
make setup-autoscaling
```

### Performance Optimization
- Frontend: Automatic CDN and caching
- Backend: Connection pooling and caching
- Database: Indexes and query optimization

### Cost Optimization
```bash
# Monitor costs
make cost-analysis

# Optimize resource allocation
make optimize-resources

# Review scaling policies
make review-scaling
```

---

## 🆘 Support & Resources

### Documentation
- [Render.com Documentation](https://render.com/docs)
- [Terraform Render Provider](https://registry.terraform.io/providers/render-oss/render/latest/docs)
- [MongoDB Atlas Documentation](https://docs.atlas.mongodb.com/)

### Community
- [Render Community Forum](https://community.render.com/)
- [GitHub Issues](https://github.com/yourusername/global-radio/issues)

### Professional Support
- Render.com Pro/Business plans include support
- MongoDB Atlas support for paid tiers

---

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] MongoDB Atlas cluster created and configured
- [ ] GitHub repository accessible
- [ ] Environment variables configured
- [ ] Domain names configured (if using custom domains)
- [ ] Render.com account setup with billing
- [ ] API keys and secrets secured

### Deployment
- [ ] Terraform applied successfully
- [ ] Backend service deployed and healthy
- [ ] Frontend static site deployed
- [ ] Environment variables properly set
- [ ] Custom domains configured (if applicable)
- [ ] Health checks passing

### Post-Deployment
- [ ] Application accessible via URL
- [ ] All features working correctly
- [ ] Database connection verified
- [ ] Monitoring and alerts configured
- [ ] Documentation updated
- [ ] Team notified of deployment

---

**Ready to deploy your Global Radio application to Render.com! 🚀📻**