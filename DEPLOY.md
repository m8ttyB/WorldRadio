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

## 🏗️ Architecture Overview

### Render.com Services
```
┌─────────────────────────────────────────────────┐
│                 Render.com                      │
├─────────────────────────────────────────────────┤
│  Frontend (Static Site)                        │
│  ├─ React Build                                │
│  ├─ CDN Distribution                           │
│  └─ Custom Domain Support                      │
├─────────────────────────────────────────────────┤
│  Backend (Web Service)                         │
│  ├─ FastAPI Application                        │
│  ├─ Auto-scaling                               │
│  ├─ Health Checks                              │
│  └─ Environment Variables                      │
├─────────────────────────────────────────────────┤
│  External Services                             │
│  ├─ MongoDB Atlas (Database)                   │
│  ├─ Radio Browser API                          │
│  └─ GitHub (Source Code)                       │
└─────────────────────────────────────────────────┘
```

### Cost Estimation
- **Frontend (Static Site)**: $0/month (free tier)
- **Backend (Web Service)**: $7/month (Starter plan)
- **MongoDB Atlas**: $0/month (free tier, 512MB)
- **Total**: ~$7/month

---

## ⚡ Quick Deployment

### One-Command Deployment
```bash
# Clone and deploy in one go
make deploy-all
```

### Step-by-Step Quick Deploy
```bash
# 1. Clone repository
git clone https://github.com/yourusername/global-radio
cd global-radio

# 2. Setup environment
cp deploy/.env.example deploy/.env
# Edit deploy/.env with your values

# 3. Deploy infrastructure
make terraform-deploy

# 4. Wait for deployment
make status
```

---

## 📋 Manual Setup

### 1. MongoDB Atlas Setup

1. **Create MongoDB Atlas Account**
   - Go to [MongoDB Atlas](https://cloud.mongodb.com/)
   - Create a free account and cluster

2. **Configure Database**
   ```bash
   # Create database user
   # Whitelist IP addresses (0.0.0.0/0 for Render)
   # Get connection string
   ```

3. **Connection String Format**
   ```
   mongodb+srv://username:password@cluster.mongodb.net/global_radio
   ```

### 2. GitHub Repository Setup

1. **Fork/Clone Repository**
   ```bash
   git clone https://github.com/yourusername/global-radio
   cd global-radio
   ```

2. **Create Environment Files**
   ```bash
   # Backend environment
   cp backend/.env.example backend/.env
   
   # Frontend environment  
   cp frontend/.env.example frontend/.env
   
   # Deployment environment
   cp deploy/.env.example deploy/.env
   ```

### 3. Render.com Account Setup

1. **Create Account**
   - Register at [Render.com](https://render.com/register)
   - Connect your GitHub account

2. **Generate API Key**
   - Go to Account Settings → API Keys
   - Create new API key
   - Save securely

---

## 🏗️ Infrastructure as Code

### Terraform Configuration

Our Terraform setup includes:
- Backend Web Service
- Frontend Static Site
- Environment Variables
- Custom Domains (optional)

### File Structure
```
deploy/
├── terraform/
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Variable definitions
│   ├── outputs.tf           # Output values
│   ├── providers.tf         # Provider configuration
│   └── terraform.tfvars     # Variable values
├── .env.example             # Environment template
├── Makefile                 # Automation commands
└── scripts/
    ├── deploy.sh            # Deployment script
    ├── destroy.sh           # Cleanup script
    └── health-check.sh      # Health verification
```

### Terraform Commands
```bash
# Initialize Terraform
make terraform-init

# Plan deployment
make terraform-plan

# Deploy infrastructure
make terraform-apply

# Destroy infrastructure
make terraform-destroy
```

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