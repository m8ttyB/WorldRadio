# 🚀 Global Radio - Cloud Deployment Guide

This guide provides step-by-step instructions for deploying the Global Radio application to popular cloud platforms.

## 📋 Table of Contents

- [Render.com](#rendercom)
- [Digital Ocean](#digital-ocean)
- [Google Cloud Platform (GCP)](#google-cloud-platform-gcp)
- [Environment Variables Reference](#environment-variables-reference)
- [Post-Deployment Checklist](#post-deployment-checklist)

---

## 🎨 Render.com

Render.com is a modern cloud platform with automatic builds and deployments from Git.

### Prerequisites
- GitHub/GitLab repository with your code
- Render.com account (free tier available)

### 1. Database Setup (MongoDB Atlas)

Since Render doesn't offer managed MongoDB, we'll use MongoDB Atlas:

1. Go to [MongoDB Atlas](https://cloud.mongodb.com/)
2. Create a free cluster
3. Create a database user
4. Whitelist IP addresses (0.0.0.0/0 for all IPs)
5. Get your connection string: `mongodb+srv://username:password@cluster.mongodb.net/global_radio`

### 2. Backend Deployment

1. **Create Web Service**:
   - Go to Render Dashboard → "New" → "Web Service"
   - Connect your GitHub repository
   - Configure the service:

```yaml
Name: global-radio-backend
Environment: Python 3
Region: Oregon (US West)
Branch: main
Root Directory: backend
Build Command: pip install -r requirements.txt
Start Command: uvicorn server:app --host 0.0.0.0 --port $PORT
```

2. **Environment Variables**:
   ```
   MONGO_URL=mongodb+srv://username:password@cluster.mongodb.net/global_radio
   DB_NAME=global_radio
   PYTHON_VERSION=3.11.0
   ```

3. **Advanced Settings**:
   - Auto-Deploy: Yes
   - Health Check Path: `/api/`

### 3. Frontend Deployment

1. **Create Static Site**:
   - Go to Render Dashboard → "New" → "Static Site"
   - Connect your GitHub repository
   - Configure:

```yaml
Name: global-radio-frontend
Root Directory: frontend
Build Command: yarn install && yarn build
Publish Directory: build
```

2. **Environment Variables**:
   ```
   REACT_APP_BACKEND_URL=https://your-backend-url.onrender.com
   NODE_VERSION=18
   ```

3. **Redirects/Rewrites** (for React Router):
   Create `frontend/public/_redirects`:
   ```
   /*    /index.html   200
   ```

### 4. Custom Domain (Optional)

1. Go to your static site settings
2. Add custom domain
3. Update DNS records as instructed
4. Update `REACT_APP_BACKEND_URL` if backend domain changes

---

## 🌊 Digital Ocean

Digital Ocean offers multiple deployment options: App Platform, Droplets, and Kubernetes.

### Option A: App Platform (Recommended)

#### Prerequisites
- Digital Ocean account
- GitHub repository

#### 1. Database Setup

1. **Create MongoDB Database**:
   - Go to Digital Ocean Dashboard → Databases
   - Create MongoDB cluster
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
# Create Ubuntu 20.04 droplet (minimum $6/month)
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
curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
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

**Backend .env:**
```env
MONGO_URL=mongodb://localhost:27017
DB_NAME=global_radio_prod
```

**Frontend .env:**
```env
REACT_APP_BACKEND_URL=https://yourdomain.com
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

### 2. Database Setup (Cloud SQL)

```bash
# Create MongoDB instance (alternative: use MongoDB Atlas)
# Note: GCP doesn't offer managed MongoDB, so we'll use MongoDB Atlas
# Follow the MongoDB Atlas setup from Render.com section
```

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
| `REACT_APP_ANALYTICS_ID` | Analytics tracking ID | `GA-XXXXXXXXX` |

---

## ✅ Post-Deployment Checklist

### 1. Health Checks

```bash
# Test backend API
curl https://your-backend-url/api/

# Test frontend
curl https://your-frontend-url/

# Test radio stations endpoint
curl https://your-backend-url/api/radio/stations/popular?limit=5
```

### 2. Performance Testing

- Test page load speeds
- Verify audio streaming works
- Check mobile responsiveness
- Test search functionality

### 3. Monitoring Setup

#### Render.com
- Enable deployment notifications
- Monitor resource usage in dashboard

#### Digital Ocean
- Set up monitoring alerts
- Configure log rotation
- Set up automated backups

#### GCP
- Configure Cloud Monitoring alerts
- Set up error reporting
- Enable Cloud Logging

### 4. Security Checklist

- [ ] HTTPS enabled
- [ ] Environment variables secured
- [ ] Database access restricted
- [ ] CORS properly configured
- [ ] API rate limiting (if needed)
- [ ] Security headers configured

### 5. DNS Configuration

If using custom domains:

```dns
# Example DNS records
A     @           your-server-ip
CNAME www         yourdomain.com
CNAME api         your-backend-url
```

### 6. Backup Strategy

- Database backups (MongoDB Atlas handles this automatically)
- Code repository backups (Git provides this)
- Environment configuration backups

---

## 🔍 Troubleshooting

### Common Issues

1. **CORS Errors**
   - Verify `REACT_APP_BACKEND_URL` is correct
   - Check backend CORS configuration

2. **Database Connection Failed**
   - Verify MongoDB connection string
   - Check network access rules
   - Confirm database user permissions

3. **Build Failures**
   - Check Node.js/Python versions
   - Verify all dependencies are listed
   - Check for syntax errors

4. **Audio Streaming Issues**
   - Test with different radio stations
   - Check browser console for errors
   - Verify HTTPS is enabled (required for audio)

### Platform-Specific Issues

#### Render.com
- Build timeouts: Optimize dependencies
- Memory limits: Upgrade plan if needed
- Cold starts: Consider paid plan for faster spin-up

#### Digital Ocean
- Droplet resources: Monitor CPU/memory usage
- Storage space: Set up log rotation
- Security: Configure firewall rules

#### GCP
- Quotas: Check service quotas and limits
- Billing: Monitor costs and set up alerts
- Regions: Choose closest region for better performance

---

## 📞 Support

For deployment-specific issues:

- **Render.com**: [Render Documentation](https://render.com/docs)
- **Digital Ocean**: [DO Community](https://www.digitalocean.com/community)
- **GCP**: [Google Cloud Documentation](https://cloud.google.com/docs)

For application issues, please create an issue in the GitHub repository.

---

**Happy Deploying! 🚀📻**