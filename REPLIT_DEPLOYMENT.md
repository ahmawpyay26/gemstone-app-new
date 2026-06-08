# Replit Deployment Guide - Gemstone Backend

**Complete deployment to Replit with PostgreSQL database**

---

## Overview

Deploy Gemstone Backend to Replit with:
- ✅ Node.js server
- ✅ PostgreSQL database
- ✅ Automatic admin user creation
- ✅ Environment variables configured
- ✅ Public API access

---

## Prerequisites

1. **Replit Account**
   - Sign up at https://replit.com
   - Free tier available

2. **GitHub Account** (optional)
   - For easier code import

---

## Step 1: Create Replit Project

### Option A: Import from GitHub (Recommended)

1. Go to https://replit.com
2. Click "Create" → "Import from GitHub"
3. Enter: `https://github.com/YOUR_USERNAME/gemstone-backend`
4. Click "Import"

### Option B: Create Blank Node.js Project

1. Go to https://replit.com
2. Click "Create" → "New Repl"
3. Select "Node.js"
4. Name: `gemstone-backend`
5. Click "Create Repl"

---

## Step 2: Upload Backend Code

### If using blank project:

1. In Replit editor, click "Upload file"
2. Upload entire `/home/ubuntu/gemstone-app/backend/` directory
3. Or use Git:
   ```bash
   git clone https://github.com/YOUR_USERNAME/gemstone-backend.git
   cd gemstone-backend
   ```

---

## Step 3: Install Dependencies

In Replit terminal:

```bash
npm install
```

This installs all required packages:
- express
- cors
- dotenv
- pg
- bcryptjs
- jsonwebtoken

---

## Step 4: Configure Environment Variables

In Replit:

1. Click "Secrets" (lock icon) in left sidebar
2. Add these environment variables:

```
NODE_ENV=production
PORT=3000
CORS_ORIGIN=https://gemdash-ggyfjknd.manus.space
JWT_SECRET=your_secure_jwt_secret_key_here
JWT_REFRESH_SECRET=your_secure_jwt_refresh_secret_key_here
```

### Generate Secure Keys

In terminal:
```bash
node -e "console.log('JWT_SECRET=' + require('crypto').randomBytes(32).toString('hex'))"
node -e "console.log('JWT_REFRESH_SECRET=' + require('crypto').randomBytes(32).toString('hex'))"
```

Copy output to Secrets.

---

## Step 5: Setup PostgreSQL Database

### Option A: Use Replit PostgreSQL (Recommended)

1. In Replit, click "Tools" → "Database"
2. Select "PostgreSQL"
3. Click "Create"
4. Replit automatically sets `DATABASE_URL` environment variable

### Option B: Use External Database

If you have external PostgreSQL:

1. Click "Secrets"
2. Add `DATABASE_URL`:
   ```
   postgresql://user:password@host:port/database
   ```

---

## Step 6: Initialize Database

The server automatically initializes on startup:

1. Click "Run" button
2. Server starts and:
   - Creates database tables
   - Creates indexes
   - Seeds admin user
   - Listens on port 3000

Watch for logs:
```
🚀 Starting Gemstone Management Backend Server...
🔨 Initializing database...
✅ All tables created successfully
👤 Creating default admin user...
✅ Default admin user created successfully
✅ Server running on port 3000
```

---

## Step 7: Get Public URL

In Replit:

1. Look at the top of the editor
2. You'll see a URL like: `https://gemstone-backend-xxxxx.replit.dev`
3. This is your public backend URL

---

## Step 8: Test Backend

### Health Check

```bash
curl https://gemstone-backend-xxxxx.replit.dev/api/health
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
curl -X POST https://gemstone-backend-xxxxx.replit.dev/api/auth/login \
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

## Step 9: Connect Frontend

### In Manus Dashboard

1. Go to **Settings** → **Secrets**
2. Add/Update:
   ```
   VITE_FRONTEND_FORGE_API_URL=https://gemstone-backend-xxxxx.replit.dev/api
   ```
3. Click **Publish**

Frontend now connects to Replit backend.

---

## Step 10: Test Login from Frontend

1. Open https://gemdash-ggyfjknd.manus.space/login
2. Enter:
   - Email: `admin@gemstone.com`
   - Password: `admin123`
3. Click "Login"
4. Should redirect to dashboard

---

## Replit Features

### View Logs

Terminal shows all logs in real-time:
- Server startup
- Database initialization
- API requests
- Errors

### Restart Server

Click "Stop" then "Run" button.

### Database Access

In terminal:
```bash
psql $DATABASE_URL
```

Query admin user:
```sql
SELECT id, email, role FROM users WHERE email = 'admin@gemstone.com';
```

### Keep Server Running

Replit free tier stops after 1 hour of inactivity.

To keep running:
1. Click "Always On" (requires Replit Pro)
2. Or use external monitoring service

---

## Troubleshooting

### Issue: Server Won't Start

**Check logs for errors:**
- Look at terminal output
- Check for missing dependencies

**Solution:**
```bash
npm install
npm start
```

### Issue: Database Connection Error

**Check DATABASE_URL:**
1. Click "Secrets"
2. Verify DATABASE_URL is set
3. If using Replit DB, it should be auto-set

**Solution:**
```bash
echo $DATABASE_URL
```

### Issue: Admin User Not Created

**Check logs:**
```bash
npm start
```

Look for "Creating default admin user" message.

**Manually create:**
```bash
node scripts/seedAdminUser.js
```

### Issue: CORS Error from Frontend

**Update CORS_ORIGIN:**
1. Click "Secrets"
2. Update `CORS_ORIGIN`
3. Click "Stop" then "Run"

### Issue: Port Already in Use

**Change PORT in Secrets:**
1. Click "Secrets"
2. Change `PORT` to different number (3001, 3002)
3. Click "Run"

---

## Production Checklist

- [ ] Replit project created
- [ ] Backend code uploaded
- [ ] Dependencies installed
- [ ] Environment variables set
- [ ] PostgreSQL database connected
- [ ] Server running
- [ ] Health endpoint works
- [ ] Login endpoint works
- [ ] Admin user created
- [ ] Frontend API URL updated
- [ ] Frontend can login

---

## Final URLs

**Backend URL:**
```
https://gemstone-backend-xxxxx.replit.dev
```

**API Base URL:**
```
https://gemstone-backend-xxxxx.replit.dev/api
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

## Important Notes

### Replit Free Tier Limitations

- Server stops after 1 hour of inactivity
- Limited computing resources
- Suitable for development/testing

### For Production

Consider upgrading to:
- Replit Pro (Always On)
- Or use Railway/Heroku/VPS

---

## Support

- Replit Docs: https://docs.replit.com
- Terminal: View all logs and errors
- Database: Use `psql` command

---

**Deployment Status:** ✅ READY FOR DEPLOYMENT

**Last Updated:** May 31, 2026
