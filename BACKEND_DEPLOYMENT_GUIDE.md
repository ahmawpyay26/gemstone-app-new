# Backend Deployment Guide - Render.com

**Complete step-by-step guide to deploy Gemstone Management Backend to Render.com**

---

## Prerequisites

- GitHub account with backend code pushed
- Render.com account (free tier available)
- Frontend domain: `https://gemdash-ggyfjknd.manus.space`

---

## Step 1: Prepare GitHub Repository

### 1.1 Push Backend Code to GitHub

```bash
cd /home/ubuntu/gemstone-app
git init
git add .
git commit -m "Initial backend commit"
git remote add origin https://github.com/YOUR_USERNAME/gemstone-backend.git
git push -u origin main
```

### 1.2 Ensure .gitignore is Set

```bash
cat > .gitignore << 'EOF'
node_modules/
.env
.env.local
.env.*.local
*.log
dist/
build/
.DS_Store
EOF
```

---

## Step 2: Create Render.com Account and Connect GitHub

1. Go to https://render.com
2. Sign up with GitHub
3. Authorize Render to access your GitHub repositories
4. Click "New +" → "Web Service"
5. Select your `gemstone-backend` repository
6. Click "Connect"

---

## Step 3: Configure Web Service on Render

### 3.1 Basic Settings

| Field | Value |
|-------|-------|
| **Name** | gemstone-backend |
| **Environment** | Node |
| **Region** | Singapore (or closest to you) |
| **Branch** | main |
| **Build Command** | `npm install` |
| **Start Command** | `npm start` |

### 3.2 Environment Variables

Click "Advanced" and add these environment variables:

```
NODE_ENV=production
PORT=3001
JWT_SECRET=[Generate: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"]
JWT_REFRESH_SECRET=[Generate: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"]
CORS_ORIGIN=https://gemdash-ggyfjknd.manus.space
```

**Note:** Keep `DB_*` variables empty for now - we'll connect database next.

### 3.3 Plan Selection

- **Free Plan:** Suitable for development/testing
- **Paid Plan:** Recommended for production

Click "Create Web Service"

---

## Step 4: Create PostgreSQL Database on Render

1. In Render dashboard, click "New +" → "PostgreSQL"
2. Configure:

| Field | Value |
|-------|-------|
| **Name** | gemstone-postgres |
| **Database** | gemstone_production |
| **User** | gemstone_user |
| **Region** | Singapore |
| **Plan** | Free |

3. Click "Create Database"
4. Wait for database to be ready (5-10 minutes)

---

## Step 5: Connect Database to Web Service

### 5.1 Get Database Connection String

In Render dashboard:
1. Go to your PostgreSQL database
2. Copy the "Internal Database URL"
3. Format: `postgresql://user:password@host:5432/database`

### 5.2 Update Web Service Environment Variables

1. Go to your Web Service (gemstone-backend)
2. Click "Environment"
3. Add these variables:

```
DB_HOST=your-database-host.render.com
DB_PORT=5432
DB_NAME=gemstone_production
DB_USER=gemstone_user
DB_PASSWORD=your_database_password
DB_SSL=true
```

4. Click "Save Changes"

---

## Step 6: Deploy Backend

### 6.1 Trigger Deployment

1. Go to your Web Service
2. Click "Manual Deploy" → "Deploy latest commit"
3. Wait for deployment (2-5 minutes)

### 6.2 Monitor Deployment

Watch the logs:
```
Building...
npm install
npm start
🚀 Gemstone Management API Server running on port 3001
```

---

## Step 7: Get Your Backend URL

In Render dashboard:
1. Go to your Web Service
2. Copy the URL from "Service URL" section
3. Format: `https://gemstone-backend-xxxxx.onrender.com`

**Your Backend API URL:**
```
https://gemstone-backend-xxxxx.onrender.com/api
```

---

## Step 8: Test Backend Health

```bash
curl https://gemstone-backend-xxxxx.onrender.com/api/health
```

Expected response:
```json
{
  "status": "OK",
  "message": "Gemstone Management API is running"
}
```

---

## Step 9: Test Login Endpoint

```bash
curl -X POST https://gemstone-backend-xxxxx.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@gemstone.com",
    "password": "admin123"
  }'
```

Expected response:
```json
{
  "success": true,
  "user": {
    "id": "...",
    "email": "admin@gemstone.com",
    "role": "Owner"
  },
  "token": "eyJhbGc...",
  "refreshToken": "eyJhbGc..."
}
```

---

## Step 10: Update Frontend API Configuration

### 10.1 Update Environment Variables

In Manus dashboard:
1. Go to Settings → Secrets
2. Add/Update:
   ```
   VITE_FRONTEND_FORGE_API_URL=https://gemstone-backend-xxxxx.onrender.com/api
   ```

### 10.2 Redeploy Frontend

1. In Manus dashboard, click "Publish"
2. Wait for deployment
3. Frontend will now use production backend

---

## Step 11: Verify Frontend-Backend Connection

1. Open https://gemdash-ggyfjknd.manus.space/login
2. Enter credentials:
   - Email: `admin@gemstone.com`
   - Password: `admin123`
3. Click "Login"
4. Should redirect to dashboard

---

## Troubleshooting

### Issue: 502 Bad Gateway

**Cause:** Backend not running or database connection failed

**Solution:**
1. Check Render logs
2. Verify database connection string
3. Restart web service

### Issue: CORS Error

**Cause:** Frontend domain not in CORS_ORIGIN

**Solution:**
1. Update `CORS_ORIGIN` environment variable
2. Redeploy backend

### Issue: Login Returns 401

**Cause:** Admin user not created

**Solution:**
1. SSH to backend (if possible)
2. Run: `node scripts/seedAdminUser.js`
3. Or restart backend service

### Issue: Database Connection Timeout

**Cause:** Database not ready or credentials wrong

**Solution:**
1. Verify database is running
2. Check credentials in environment variables
3. Ensure DB_SSL=true

---

## Production Checklist

- [ ] Backend deployed to Render
- [ ] PostgreSQL database created
- [ ] Environment variables configured
- [ ] CORS_ORIGIN includes frontend domain
- [ ] Health endpoint responds
- [ ] Login endpoint works
- [ ] Admin user created
- [ ] Frontend API URL updated
- [ ] Frontend can login successfully
- [ ] SSL certificate working
- [ ] Logs being monitored

---

## Monitoring & Maintenance

### View Logs

```bash
# In Render dashboard, click "Logs" tab
# Or use Render CLI:
render logs gemstone-backend
```

### Restart Service

```bash
# In Render dashboard, click "Restart Service"
```

### Update Code

```bash
# Push to GitHub
git push origin main

# Render auto-deploys on push (if enabled)
# Or manually deploy in dashboard
```

---

## Next Steps

1. **Setup Custom Domain** (optional)
   - Add your custom domain in Render settings
   - Update CORS_ORIGIN accordingly

2. **Enable Auto-Deploy**
   - Render auto-deploys on GitHub push
   - Configure in "Deploy" settings

3. **Setup Monitoring**
   - Enable Render alerts
   - Monitor API performance
   - Track error rates

4. **Database Backups**
   - Enable automatic backups
   - Test restore procedures

5. **Security Hardening**
   - Rotate JWT secrets regularly
   - Enable rate limiting
   - Add API authentication

---

## Support

For issues:
1. Check Render documentation: https://render.com/docs
2. Check backend logs in Render dashboard
3. Verify environment variables
4. Test endpoints with curl

---

**Backend URL:** `https://gemstone-backend-xxxxx.onrender.com`  
**API Base URL:** `https://gemstone-backend-xxxxx.onrender.com/api`  
**Frontend Domain:** `https://gemdash-ggyfjknd.manus.space`

---

**Deployment Date:** ________________  
**Deployed By:** ________________  
**Status:** ✅ LIVE
