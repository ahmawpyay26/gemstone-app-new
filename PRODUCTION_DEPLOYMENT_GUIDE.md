# Gemstone Management System - Production Deployment & Release Guide

**Version:** 1.0.0  
**Last Updated:** May 31, 2026  
**Status:** PRODUCTION READY

---

## Table of Contents

1. [Pre-Deployment Requirements](#pre-deployment-requirements)
2. [Mobile App Release (Flutter)](#mobile-app-release-flutter)
3. [Web Dashboard Deployment](#web-dashboard-deployment)
4. [Backend Node.js Deployment](#backend-nodejs-deployment)
5. [Database Deployment](#database-deployment)
6. [Cloud & Infrastructure Setup](#cloud--infrastructure-setup)
7. [CI/CD Pipeline Configuration](#cicd-pipeline-configuration)
8. [Complete Deployment Checklist](#complete-deployment-checklist)
9. [Go-Live Procedures](#go-live-procedures)
10. [Troubleshooting & Common Errors](#troubleshooting--common-errors)

---

## Pre-Deployment Requirements

### Required Tools & Accounts

| Tool | Purpose | Account Required |
|------|---------|------------------|
| Flutter SDK | Mobile app development | No |
| Node.js 18+ | Backend runtime | No |
| PostgreSQL 12+ | Database | Yes (server) |
| Git | Version control | Yes (GitHub/GitLab) |
| Docker | Containerization | No (optional) |
| PM2 | Process management | No |
| Nginx | Reverse proxy | No |
| SSL Certificate | HTTPS | Yes (Let's Encrypt free) |
| Firebase | Cloud services | Yes (Google account) |
| AWS S3 / Equivalent | File storage | Yes (AWS account) |
| GitHub Actions | CI/CD | Yes (GitHub account) |

### System Requirements

**Development Machine:**
- OS: Linux/macOS/Windows
- RAM: 8GB minimum
- Storage: 50GB available
- Internet: 10Mbps minimum

**Production Server:**
- OS: Ubuntu 20.04 LTS or later
- RAM: 8GB minimum
- Storage: 100GB SSD
- CPU: 2+ cores
- Internet: 100Mbps minimum
- Uptime: 99.5%+

### Estimated Setup Time

| Component | Time |
|-----------|------|
| Mobile App Build & Release | 2-3 hours |
| Web Dashboard Deployment | 1-2 hours |
| Backend Deployment | 2-3 hours |
| Database Setup | 1-2 hours |
| Cloud Infrastructure | 1-2 hours |
| CI/CD Pipeline | 1-2 hours |
| Testing & Verification | 2-3 hours |
| **Total** | **10-17 hours** |

---

## Mobile App Release (Flutter)

### 1. Flutter Project Setup

```bash
# Clone the repository
git clone <mobile-app-repo-url>
cd gemstone-mobile-app

# Get dependencies
flutter pub get

# Verify Flutter setup
flutter doctor
```

### 2. App Signing Configuration

#### Generate Keystore (First Time Only)

```bash
# Generate keystore file
keytool -genkey -v -keystore ~/gemstone_release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias gemstone_key

# Output: gemstone_release.keystore (save securely)
```

#### Configure Signing in Flutter

Create `android/key.properties`:

```properties
storePassword=<your_store_password>
keyPassword=<your_key_password>
keyAlias=gemstone_key
storeFile=<path_to_keystore>/gemstone_release.keystore
```

Update `android/app/build.gradle`:

```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile file(keystoreProperties['storeFile'])
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

### 3. Version Management

Update `pubspec.yaml`:

```yaml
version: 1.0.0+1  # Format: major.minor.patch+buildNumber
```

### 4. Production Build

```bash
# Build APK for release
flutter build apk --release

# Build App Bundle for Play Store (recommended)
flutter build appbundle --release

# Output locations:
# APK: build/app/outputs/apk/release/app-release.apk
# Bundle: build/app/outputs/bundle/release/app-release.aab
```

### 5. Play Store Deployment

#### Create Google Play Developer Account

1. Visit https://play.google.com/console
2. Create developer account ($25 one-time fee)
3. Accept agreements and policies

#### Upload App

1. Create new app in Play Console
2. Fill app details (name, description, screenshots)
3. Upload app bundle (AAB file)
4. Configure pricing and distribution
5. Add content rating
6. Submit for review

#### Review Process

- **Initial Review:** 1-3 hours
- **Full Review:** 24-48 hours
- **Status:** Monitor in Play Console

### 6. App Store Deployment (iOS - if applicable)

```bash
# Build iOS release
flutter build ios --release

# Upload to App Store using Xcode or fastlane
# (Requires Apple Developer account - $99/year)
```

---

## Web Dashboard Deployment

### 1. Build Optimization

```bash
cd gemstone-admin-dashboard

# Install dependencies
pnpm install

# Production build
pnpm run build

# Verify build output
ls -lh dist/
```

### 2. Deployment Options

#### Option A: Manus Platform (Recommended)

```bash
# Already configured - just publish
# Click "Publish" button in Management UI
```

#### Option B: Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod

# Configure domain in Vercel dashboard
```

#### Option C: Netlify

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod --dir=dist

# Configure domain in Netlify dashboard
```

#### Option D: VPS (Self-Hosted)

```bash
# Copy build files to server
scp -r dist/* user@server:/var/www/gemstone-dashboard/

# Configure Nginx (see below)
```

### 3. Domain Configuration

#### Point Domain to Server

1. Update DNS A record to server IP
2. Wait for DNS propagation (up to 48 hours)
3. Verify with `nslookup your-domain.com`

### 4. SSL Certificate Setup

#### Using Let's Encrypt (Free)

```bash
# Install Certbot
sudo apt-get install certbot python3-certbot-nginx

# Generate certificate
sudo certbot certonly --nginx -d your-domain.com

# Auto-renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

#### Nginx Configuration

Create `/etc/nginx/sites-available/gemstone-dashboard`:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /var/www/gemstone-dashboard;
    index index.html;

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy
    location /api/ {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
}
```

Enable site:

```bash
sudo ln -s /etc/nginx/sites-available/gemstone-dashboard /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Backend Node.js Deployment

### 1. Server Setup (Ubuntu 20.04 LTS)

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2 globally
sudo npm install -g pm2

# Install Nginx
sudo apt-get install -y nginx

# Install PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib
```

### 2. Application Setup

```bash
# Clone repository
git clone <backend-repo-url> /home/ubuntu/gemstone-backend
cd /home/ubuntu/gemstone-backend

# Install dependencies
npm install --production

# Create .env file
cp .env.example .env
# Edit .env with production values
```

### 3. Environment Configuration

Create `.env`:

```env
# Server
NODE_ENV=production
PORT=3001
HOST=localhost

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=gemstone_production
DB_USER=gemstone_user
DB_PASSWORD=<secure_password>

# JWT
JWT_SECRET=<secure_jwt_secret>
JWT_EXPIRY=1h
JWT_REFRESH_EXPIRY=7d

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=<app_password>

# AWS S3
AWS_ACCESS_KEY_ID=<your_key>
AWS_SECRET_ACCESS_KEY=<your_secret>
AWS_REGION=us-east-1
AWS_S3_BUCKET=gemstone-backups

# Firebase
FIREBASE_PROJECT_ID=<your_project_id>
FIREBASE_PRIVATE_KEY=<your_private_key>
FIREBASE_CLIENT_EMAIL=<your_email>

# Logging
LOG_LEVEL=info
LOG_FILE=/var/log/gemstone/app.log

# Security
CORS_ORIGIN=https://your-domain.com
RATE_LIMIT_WINDOW=15m
RATE_LIMIT_MAX_REQUESTS=100
```

### 4. PM2 Process Management

Create `ecosystem.config.js`:

```javascript
module.exports = {
  apps: [{
    name: 'gemstone-backend',
    script: './server/index.ts',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production'
    },
    error_file: '/var/log/gemstone/error.log',
    out_file: '/var/log/gemstone/out.log',
    log_file: '/var/log/gemstone/combined.log',
    time_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    watch: false,
    ignore_watch: ['node_modules', 'logs'],
    max_memory_restart: '1G',
    autorestart: true,
    max_restarts: 10,
    min_uptime: '10s'
  }]
};
```

Start application:

```bash
# Start with PM2
pm2 start ecosystem.config.js

# Save PM2 config
pm2 save

# Setup PM2 startup
pm2 startup
# Copy and run the command output

# Monitor
pm2 monit
pm2 logs
```

### 5. Nginx Reverse Proxy

Create `/etc/nginx/sites-available/gemstone-api`:

```nginx
upstream gemstone_backend {
    server localhost:3001;
    keepalive 64;
}

server {
    listen 80;
    server_name api.your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.your-domain.com;

    ssl_certificate /etc/letsencrypt/live/api.your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.your-domain.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Logging
    access_log /var/log/nginx/gemstone_api_access.log;
    error_log /var/log/nginx/gemstone_api_error.log;

    # Proxy settings
    location / {
        proxy_pass http://gemstone_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
```

Enable and test:

```bash
sudo ln -s /etc/nginx/sites-available/gemstone-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Database Deployment

### 1. PostgreSQL Setup

```bash
# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql

# In PostgreSQL prompt:
CREATE USER gemstone_user WITH PASSWORD '<secure_password>';
CREATE DATABASE gemstone_production OWNER gemstone_user;
GRANT ALL PRIVILEGES ON DATABASE gemstone_production TO gemstone_user;
\q
```

### 2. Database Initialization

```bash
# Run migrations
npm run migrate:prod

# Seed initial data (if applicable)
npm run seed:prod

# Verify
psql -U gemstone_user -d gemstone_production -c "SELECT version();"
```

### 3. Backup Automation

Create backup script `/usr/local/bin/backup-gemstone-db.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/var/backups/gemstone"
DB_NAME="gemstone_production"
DB_USER="gemstone_user"
BACKUP_FILE="$BACKUP_DIR/gemstone_$(date +%Y%m%d_%H%M%S).sql.gz"

mkdir -p $BACKUP_DIR

# Backup
pg_dump -U $DB_USER $DB_NAME | gzip > $BACKUP_FILE

# Keep only last 30 days
find $BACKUP_DIR -name "gemstone_*.sql.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_FILE"
```

Setup cron job:

```bash
# Make executable
sudo chmod +x /usr/local/bin/backup-gemstone-db.sh

# Add to crontab (daily at 2 AM)
sudo crontab -e

# Add line:
0 2 * * * /usr/local/bin/backup-gemstone-db.sh
```

### 4. Performance Tuning

Edit `/etc/postgresql/12/main/postgresql.conf`:

```conf
# Memory
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 16MB

# WAL
wal_buffers = 16MB
default_statistics_target = 100

# Connections
max_connections = 200
```

Restart PostgreSQL:

```bash
sudo systemctl restart postgresql
```

### 5. Security Configuration

```bash
# Edit pg_hba.conf
sudo nano /etc/postgresql/12/main/pg_hba.conf

# Change authentication method to md5
# local   all             all                                     md5
# host    all             all             127.0.0.1/32            md5
# host    all             all             ::1/128                 md5

# Restart
sudo systemctl restart postgresql
```

---

## Cloud & Infrastructure Setup

### 1. Firebase Configuration

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize project
firebase init

# Configure services:
# - Firestore (if using)
# - Cloud Storage
# - Cloud Functions
# - Authentication
```

### 2. AWS S3 Setup

```bash
# Create S3 bucket
aws s3 mb s3://gemstone-backups --region us-east-1

# Configure bucket policy
aws s3api put-bucket-versioning \
  --bucket gemstone-backups \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket gemstone-backups \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

### 3. Environment Variables Management

Create `.env.production`:

```env
# All production secrets
# Never commit to Git
```

Use secret management:

```bash
# Using GitHub Secrets (for CI/CD)
gh secret set DB_PASSWORD -b "<password>"
gh secret set JWT_SECRET -b "<secret>"
gh secret set AWS_ACCESS_KEY_ID -b "<key>"
```

---

## CI/CD Pipeline Configuration

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:12
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Build
        run: npm run build

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to production
        env:
          DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
          DEPLOY_HOST: ${{ secrets.DEPLOY_HOST }}
          DEPLOY_USER: ${{ secrets.DEPLOY_USER }}
        run: |
          mkdir -p ~/.ssh
          echo "$DEPLOY_KEY" > ~/.ssh/deploy_key
          chmod 600 ~/.ssh/deploy_key
          ssh-keyscan -H $DEPLOY_HOST >> ~/.ssh/known_hosts
          
          ssh -i ~/.ssh/deploy_key $DEPLOY_USER@$DEPLOY_HOST << 'EOF'
            cd /home/ubuntu/gemstone-backend
            git pull origin main
            npm install --production
            npm run migrate:prod
            pm2 restart gemstone-backend
          EOF
```

---

## Complete Deployment Checklist

### Pre-Deployment (1-2 days before)

- [ ] All code committed and pushed
- [ ] Tests passing (100% pass rate)
- [ ] Security audit completed
- [ ] Performance testing completed
- [ ] Database backups verified
- [ ] Rollback plan documented
- [ ] Team notified of deployment
- [ ] Maintenance window scheduled

### Deployment Day

- [ ] Backup current production database
- [ ] Backup current production code
- [ ] Deploy backend code
- [ ] Run database migrations
- [ ] Deploy frontend code
- [ ] Deploy mobile app (if applicable)
- [ ] Verify all services running
- [ ] Test critical workflows
- [ ] Monitor error logs
- [ ] Check performance metrics

### Post-Deployment

- [ ] Verify all features working
- [ ] Check user reports
- [ ] Monitor error rates
- [ ] Monitor performance
- [ ] Review logs for issues
- [ ] Update status page
- [ ] Notify stakeholders
- [ ] Schedule post-deployment review

---

## Go-Live Procedures

### 1. Pre-Go-Live Checklist (48 hours before)

- [ ] All systems tested in staging
- [ ] Database backups automated
- [ ] Monitoring configured
- [ ] Alerting configured
- [ ] Support team trained
- [ ] Rollback plan ready
- [ ] Communication plan ready

### 2. Go-Live Day

**Morning (6 hours before):**
- [ ] Final database backup
- [ ] Final code review
- [ ] Team standup
- [ ] Monitoring dashboard open

**1 Hour Before:**
- [ ] Stop accepting new transactions
- [ ] Final backup
- [ ] Notify users of maintenance

**During Deployment:**
- [ ] Deploy backend
- [ ] Deploy frontend
- [ ] Deploy mobile app
- [ ] Run smoke tests
- [ ] Verify critical paths

**After Deployment:**
- [ ] Monitor for 1 hour
- [ ] Verify all features
- [ ] Check error logs
- [ ] Announce go-live complete

### 3. Post-Go-Live (First 24 hours)

- [ ] Monitor error rates closely
- [ ] Monitor performance metrics
- [ ] Check user feedback
- [ ] Be ready to rollback
- [ ] Document any issues
- [ ] Prepare hotfix if needed

---

## Troubleshooting & Common Errors

### Database Connection Errors

**Error:** `ECONNREFUSED 127.0.0.1:5432`

**Solution:**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Start if stopped
sudo systemctl start postgresql

# Check connection
psql -U gemstone_user -d gemstone_production
```

### PM2 Process Not Starting

**Error:** `App crashed - exit code 1`

**Solution:**
```bash
# Check logs
pm2 logs gemstone-backend

# Verify environment variables
env | grep DB_

# Restart
pm2 restart gemstone-backend
```

### Nginx 502 Bad Gateway

**Error:** `502 Bad Gateway`

**Solution:**
```bash
# Check backend running
pm2 status

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log

# Verify proxy settings
sudo nginx -t
```

### SSL Certificate Issues

**Error:** `SSL_ERROR_BAD_CERT_DOMAIN`

**Solution:**
```bash
# Renew certificate
sudo certbot renew --force-renewal

# Verify certificate
sudo certbot certificates

# Restart Nginx
sudo systemctl restart nginx
```

### Out of Memory

**Error:** `FATAL: out of memory`

**Solution:**
```bash
# Check memory usage
free -h

# Increase swap
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## Support & Escalation

### Support Contacts

| Issue | Contact | Response Time |
|-------|---------|----------------|
| Critical (Down) | On-call engineer | 15 minutes |
| High (Degraded) | Team lead | 1 hour |
| Medium (Bug) | Support team | 4 hours |
| Low (Enhancement) | Product team | 24 hours |

### Escalation Path

1. **Level 1:** Support team (troubleshooting)
2. **Level 2:** Development team (bug fixes)
3. **Level 3:** Tech lead (architecture issues)
4. **Level 4:** CTO (critical decisions)

---

## Sign-Off & Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| DevOps Lead | _________________ | _________________ | _________ |
| Backend Lead | _________________ | _________________ | _________ |
| Frontend Lead | _________________ | _________________ | _________ |
| Mobile Lead | _________________ | _________________ | _________ |
| CTO | _________________ | _________________ | _________ |

---

**Document Version:** 1.0.0  
**Last Updated:** May 31, 2026  
**Next Review:** June 30, 2026
