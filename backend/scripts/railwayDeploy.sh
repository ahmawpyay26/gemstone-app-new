#!/bin/bash

# Railway.app Deployment Script
# This script automates the deployment of Gemstone Backend to Railway

set -e

echo "🚀 Starting Railway Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo -e "${RED}❌ Railway CLI not found. Installing...${NC}"
    npm install -g @railway/cli
fi

echo -e "${GREEN}✅ Railway CLI found${NC}"

# Initialize Railway project
echo -e "${YELLOW}📦 Initializing Railway project...${NC}"
railway init --name gemstone-backend

# Create PostgreSQL database
echo -e "${YELLOW}🗄️  Creating PostgreSQL database...${NC}"
railway add --service postgres

# Set environment variables
echo -e "${YELLOW}⚙️  Setting environment variables...${NC}"
railway variables set NODE_ENV production
railway variables set CORS_ORIGIN "https://gemdash-ggyfjknd.manus.space"

# Generate JWT secrets
JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
JWT_REFRESH_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")

railway variables set JWT_SECRET "$JWT_SECRET"
railway variables set JWT_REFRESH_SECRET "$JWT_REFRESH_SECRET"

# Deploy
echo -e "${YELLOW}🚀 Deploying to Railway...${NC}"
railway up

# Get the deployed URL
echo -e "${YELLOW}📍 Getting deployment URL...${NC}"
RAILWAY_URL=$(railway status | grep "https://" | head -1 | awk '{print $NF}')

echo ""
echo -e "${GREEN}✅ Deployment completed!${NC}"
echo ""
echo -e "${GREEN}📊 Backend URL: ${RAILWAY_URL}${NC}"
echo -e "${GREEN}🔑 API Base URL: ${RAILWAY_URL}/api${NC}"
echo ""
echo -e "${YELLOW}🔐 Admin Credentials:${NC}"
echo "   Email: admin@gemstone.com"
echo "   Password: admin123"
echo ""
echo -e "${YELLOW}✅ Next steps:${NC}"
echo "1. Update frontend API URL: ${RAILWAY_URL}/api"
echo "2. Test login: curl -X POST ${RAILWAY_URL}/api/auth/login -H 'Content-Type: application/json' -d '{\"email\":\"admin@gemstone.com\",\"password\":\"admin123\"}'"
echo ""
