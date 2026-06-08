# Railway.app Deployment Guide - Gemstone Backend

**Complete automated deployment to Railway.app**

---

## Overview

This guide deploys the Gemstone Backend to Railway.app with:
- ✅ Node.js server
- ✅ PostgreSQL database
- ✅ Automatic admin user creation
- ✅ Environment variables auto-configured
- ✅ CORS enabled for frontend

---

## Prerequisites

1. **Railway.app Account**
   - Sign up at https://railway.app
   - Link your GitHub account

2. **Railway CLI**
   - Already installed in sandbox
   - Version: 4.66.0+

---

## Quick Deployment (3 Steps)

### Step 1: Login to Railway

```bash
railway login
```

This opens a browser to authenticate with Railway.

### Step 2: Initialize and Deploy

```bash
cd /home/ubuntu/gemstone-app
railway init --name gemstone-backend
```

Follow prompts to create a new project.

### Step 3: Add PostgreSQL Database

```bash
railway add --service postgres
```

Railway automatically creates and connects the database.

---

## Automatic Configuration

Railway automatically:

1. **Creates PostgreSQL Database**
   - Database name: `railway`
   - User: `postgres`
   - Password: auto-generated
   - Connection string: `DATABASE_URL` env var

2. **Sets Environment Variables**
   ```
   DATABASE_URL=postgresql://...
   PORT=auto-assigned
   NODE_ENV=production
   ```

3. **Deploys Node.js Server**
   - Reads `Procfile`: `web: npm start`
   - Installs dependencies: `npm install`
   - Starts server: `npm start`

4. **Runs Initialization**
   - Creates database tables
   - Creates indexes
   - Seeds admin user
   - Ready for login

---

## Manual Environment Variables

Set additional variables:

```bash
railway variables set CORS_ORIGIN "https://gemdash-ggyfjknd.manus.space"
railway variables set JWT_SECRET "$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")"
railway variables set JWT_REFRESH_SECRET "$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")"
```

---

## Get Your Backend URL

```bash
railway status
```

Look for the URL like:
```
https://gemstone-backend-xxxxx.railway.app
```

---

## Test Deployment

### Health Check

```bash
curl https://gemstone-backend-xxxxx.railway.app/api/health
```

Expected:
```json
{
  "status": "OK",
  "message": "Gemstone Management API is running"
}
```

### Login Test

```bash
curl -X POST https://gemstone-backend-xxxxx.railway.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@gemstone.com",
    "password": "admin123"
  }'
```

Expected:
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

## Update Frontend

### In Manus Dashboard

1. Go to **Settings** → **Secrets**
2. Add/Update:
   ```
   VITE_FRONTEND_FORGE_API_URL=https://gemstone-backend-xxxxx.railway.app/api
   ```
3. Click **Publish**

Frontend now connects to production backend.

---

## View Logs

```bash
railway logs
```

Shows real-time server logs including:
- Startup messages
- Database initialization
- Admin user creation
- API requests

---

## Restart Service

```bash
railway redeploy
```

Restarts the backend service.

---

## Database Access

### View Database URL

```bash
railway variables
```

Look for `DATABASE_URL`.

### Connect to Database

```bash
psql <DATABASE_URL>
```

### Query Admin User

```sql
SELECT id, email, role FROM users WHERE email = 'admin@gemstone.com';
```

---

## Troubleshooting

### Issue: Deployment Failed

**Check logs:**
```bash
railway logs
```

**Common causes:**
- Missing dependencies
- Database connection error
- Port already in use

**Solution:**
```bash
railway redeploy
```

### Issue: Admin User Not Created

**Check logs for errors:**
```bash
railway logs | grep -i "admin\|seed"
```

**Manually create:**
```bash
railway run node scripts/seedAdminUser.js
```

### Issue: CORS Error

**Update CORS_ORIGIN:**
```bash
railway variables set CORS_ORIGIN "https://gemdash-ggyfjknd.manus.space"
railway redeploy
```

### Issue: Database Connection Timeout

**Verify DATABASE_URL:**
```bash
railway variables | grep DATABASE_URL
```

**Test connection:**
```bash
railway run node -e "require('pg').connect(process.env.DATABASE_URL, (err, client) => console.log(err ? 'Error' : 'Connected'))"
```

---

## Production Checklist

- [ ] Railway project created
- [ ] PostgreSQL database connected
- [ ] Environment variables set
- [ ] Server deployed successfully
- [ ] Health endpoint responds
- [ ] Login endpoint works
- [ ] Admin user created
- [ ] Frontend API URL updated
- [ ] Frontend can login
- [ ] Logs being monitored

---

## Final URLs

**Backend URL:**
```
https://gemstone-backend-xxxxx.railway.app
```

**API Base URL:**
```
https://gemstone-backend-xxxxx.railway.app/api
```

**Frontend Dashboard:**
```
https://gemdash-ggyfjknd.manus.space
```

**Admin Credentials:**
```
Email: admin@gemstone.com
Password: admin123
```

---

## Next Steps

1. **Monitor Logs**
   ```bash
   railway logs -f
   ```

2. **Setup Alerts** (optional)
   - In Railway dashboard → Settings → Alerts

3. **Enable Auto-Deploy** (optional)
   - Railway auto-deploys on GitHub push

4. **Backup Database** (optional)
   - Enable automatic backups in Railway settings

---

## Support

- Railway Docs: https://docs.railway.app
- Backend Logs: `railway logs`
- Database Shell: `railway run psql`

---

**Deployment Status:** ✅ READY FOR DEPLOYMENT

**Last Updated:** May 31, 2026
