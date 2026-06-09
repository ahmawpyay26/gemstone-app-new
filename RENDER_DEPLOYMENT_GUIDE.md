# Render Deployment Guide - Gemstone Management System

## Deployment Status

✅ **Web Service Created on Render**
- Service Name: `gemstone-backend`
- Environment: Node.js
- Plan: Free
- Region: Singapore
- Repository: https://github.com/ahmawpyay26/gemstone-app-new

## Configuration Details

### Build & Start Commands
```bash
Build Command: cd backend && npm install
Start Command: cd backend && npm start
```

### Environment Variables (Auto-configured by render.yaml)

#### Database Configuration
- `DB_HOST` - PostgreSQL host (from database)
- `DB_PORT` - PostgreSQL port (from database)
- `DB_NAME` - Database name: `gemstone_production`
- `DB_USER` - Database user: `gemstone_user`
- `DB_PASSWORD` - Database password (auto-generated)
- `DB_SSL` - SSL enabled: `true`

#### Server Configuration
- `NODE_ENV` - Environment: `production`
- `PORT` - Server port: `3001`

#### Security
- `JWT_SECRET` - Auto-generated JWT secret
- `JWT_REFRESH_SECRET` - Auto-generated refresh secret
- `CORS_ORIGIN` - Allowed origins:
  - https://gemdash-ggyfjknd.manus.space
  - http://localhost:3000
  - http://localhost:5173

## Database Setup

### PostgreSQL Database
- **Name**: `gemstone-postgres`
- **Database Name**: `gemstone_production`
- **User**: `gemstone_user`
- **Plan**: Free
- **Region**: Singapore
- **PostgreSQL Version**: 15

The database is automatically created by Render based on render.yaml configuration.

## Deployment Process

### Automatic Deployment
1. Push changes to `main` branch on GitHub
2. Render automatically detects changes
3. Render pulls the latest code
4. Runs build command: `cd backend && npm install`
5. Starts service with: `cd backend && npm start`
6. Service becomes available at the Render URL

### Manual Redeployment
1. Go to Render Dashboard
2. Select `gemstone-backend` service
3. Click "Manual Deploy" or "Redeploy latest commit"

## Monitoring & Logs

### Access Logs
1. Go to Render Dashboard
2. Select `gemstone-backend` service
3. Click "Logs" tab
4. View real-time logs and error messages

### Health Check
- Endpoint: `/api/health`
- Response: `{ status: 'OK', message: 'Gemstone Management API is running' }`

## API Endpoints

Once deployed, the API will be available at:
```
https://gemstone-backend.onrender.com
```

### Available Routes
- `GET /api/health` - Health check
- `POST /api/auth/login` - User login
- `GET /api/gemstones` - List gemstones
- `POST /api/gemstones` - Create gemstone
- `GET /api/sales` - List sales
- `POST /api/sales` - Create sale
- `GET /api/expenses` - List expenses
- `POST /api/expenses` - Create expense

## Troubleshooting

### Build Failures
1. Check Render logs for error messages
2. Verify `package.json` exists in `/backend` directory
3. Ensure all dependencies are listed in `package.json`
4. Check Node.js version compatibility

### Database Connection Issues
1. Verify database credentials in environment variables
2. Check PostgreSQL database is running
3. Ensure DB_SSL is set to `true` for Render
4. Check database user permissions

### Application Crashes
1. Check Render logs for error messages
2. Verify all required environment variables are set
3. Check database initialization script
4. Verify port configuration (should be 3001)

## Next Steps

1. ✅ Web Service created on Render
2. ⏳ Waiting for initial deployment to complete
3. 📊 Monitor deployment progress in Render Dashboard
4. 🧪 Test API endpoints once deployment is complete
5. 🔗 Connect Flutter mobile app to deployed API
6. 📱 Update API base URL in Flutter app

## Important Notes

- **Free Tier Limitations**: 
  - Service spins down after 15 minutes of inactivity
  - Limited to 0.5 CPU and 512 MB RAM
  - Database limited to 100 connections

- **Auto-Deploy**: 
  - Enabled on `main` branch
  - Any push to main will trigger automatic deployment

- **CORS Configuration**:
  - Allows requests from Manus dashboard
  - Allows localhost for development
  - Update CORS_ORIGIN if adding new frontend domains

## Support & Documentation

- Render Docs: https://render.com/docs
- Node.js Deployment: https://render.com/docs/deploy-node
- PostgreSQL: https://render.com/docs/databases

---

**Last Updated**: June 9, 2026
**Deployment Status**: In Progress
