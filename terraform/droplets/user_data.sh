#!/bin/bash

# Global Radio - Droplet User Data Script
# This script sets up the Global Radio application on a fresh Ubuntu 20.04 droplet

set -e

# Update system
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Install dependencies
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    unzip \
    nginx \
    certbot \
    python3-certbot-nginx

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install Yarn
npm install -g yarn

# Install Python 3.11
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update
apt-get install -y python3.11 python3.11-venv python3.11-dev python3-pip

# Create application user
useradd -m -s /bin/bash appuser
usermod -aG docker appuser

# Create application directory
mkdir -p /opt/global-radio
chown appuser:appuser /opt/global-radio

# Clone repository
cd /opt/global-radio
git clone https://github.com/${github_repo}.git .
git checkout ${github_branch}
chown -R appuser:appuser /opt/global-radio

# Create environment files
cat > /opt/global-radio/.env << EOF
MONGO_URL=${mongo_url}
DB_NAME=${db_name}
ENVIRONMENT=production
LOG_LEVEL=INFO
EOF

cat > /opt/global-radio/frontend/.env << EOF
REACT_APP_BACKEND_URL=${backend_url}
EOF

# Set up backend
cd /opt/global-radio/backend
sudo -u appuser python3.11 -m venv .venv
sudo -u appuser .venv/bin/pip install -r requirements.txt

# Set up frontend
cd /opt/global-radio/frontend
sudo -u appuser yarn install
sudo -u appuser yarn build

# Create systemd services
cat > /etc/systemd/system/global-radio-backend.service << EOF
[Unit]
Description=Global Radio Backend
After=network.target

[Service]
Type=simple
User=appuser
WorkingDirectory=/opt/global-radio/backend
Environment=PATH=/opt/global-radio/backend/.venv/bin
ExecStart=/opt/global-radio/backend/.venv/bin/uvicorn server:app --host 0.0.0.0 --port 8001
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx
cat > /etc/nginx/sites-available/global-radio << EOF
server {
    listen 80;
    server_name _;

    # Frontend
    location / {
        root /opt/global-radio/frontend/build;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Enable Nginx site
ln -sf /etc/nginx/sites-available/global-radio /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t

# Start services
systemctl daemon-reload
systemctl enable global-radio-backend
systemctl start global-radio-backend
systemctl enable nginx
systemctl restart nginx

# Set up log rotation
cat > /etc/logrotate.d/global-radio << EOF
/opt/global-radio/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 appuser appuser
    postrotate
        systemctl reload global-radio-backend
    endscript
}
EOF

# Create logs directory
mkdir -p /opt/global-radio/logs
chown appuser:appuser /opt/global-radio/logs

# Set up monitoring script
cat > /opt/global-radio/monitor.sh << 'EOF'
#!/bin/bash
# Simple monitoring script

BACKEND_URL="http://localhost:8001/api/"
LOG_FILE="/opt/global-radio/logs/monitor.log"

if curl -f $BACKEND_URL > /dev/null 2>&1; then
    echo "$(date): Backend is healthy" >> $LOG_FILE
else
    echo "$(date): Backend is down, restarting..." >> $LOG_FILE
    systemctl restart global-radio-backend
fi
EOF

chmod +x /opt/global-radio/monitor.sh

# Add monitoring to crontab
echo "*/5 * * * * /opt/global-radio/monitor.sh" | crontab -u appuser -

# Enable firewall
ufw --force enable
ufw allow ssh
ufw allow 'Nginx Full'

# Final setup
systemctl status global-radio-backend
systemctl status nginx

echo "Global Radio deployment completed successfully!"
echo "Application should be available at http://$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)"