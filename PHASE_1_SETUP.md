# Phase 1: Project Initialization & Backend Base Setup

## Overview
Phase 1 သည် ကျောက်မျက်ရတနာ စီမံခန့်ခွဲမှုစနစ်၏ Backend အခြေခံ အဆောက်အအုံကို တည်ဆောက်သည့် အဆင့်ဖြစ်ပါသည်။ Node.js + Express + PostgreSQL အပေါ်အခြေခံ၍ Scalable Backend Architecture ကို ချမှတ်ပါသည်။

## Project Structure

```
gemstone-app/
├── backend/                    # Node.js Backend
│   ├── config/                 # Configuration files
│   │   └── database.js         # PostgreSQL connection setup
│   ├── routes/                 # API route definitions
│   │   └── auth.routes.js      # Authentication routes
│   ├── controllers/            # Business logic (Phase 2)
│   ├── models/                 # Database models (Phase 2)
│   ├── middleware/             # Express middleware
│   │   └── auth.middleware.js  # JWT authentication
│   ├── utils/                  # Utility functions
│   │   └── jwt.js              # JWT token generation/verification
│   ├── database/               # Database migrations & seeds
│   ├── .env.example            # Environment variables template
│   ├── server.js               # Main Express server
│   └── package.json            # Node.js dependencies
│
└── frontend/                   # Flutter Frontend (Phase 3)
    └── (will be created in Phase 3)
```

## Completed in Phase 1

### 1. Backend Project Initialization
- ✅ Node.js project created with npm
- ✅ Express.js server setup with middleware (CORS, JSON parser)
- ✅ PostgreSQL connection configuration
- ✅ Environment variables setup (.env.example)

### 2. Project Structure
- ✅ Organized folder structure following enterprise standards
- ✅ Separation of concerns (routes, controllers, models, middleware, utils)
- ✅ Configuration management

### 3. Core Utilities
- ✅ JWT utility functions for token generation and verification
- ✅ Authentication middleware for protecting routes
- ✅ Role-based access control middleware setup

### 4. Server Setup
- ✅ Express server with error handling
- ✅ Health check endpoint
- ✅ CORS configuration
- ✅ 404 error handler

## Dependencies Installed

```json
{
  "express": "^4.x",           // Web framework
  "cors": "^2.x",              // Cross-origin resource sharing
  "dotenv": "^16.x",           // Environment variables
  "pg": "^8.x",                // PostgreSQL client
  "sequelize": "^6.x",         // ORM for database
  "bcryptjs": "^2.x",          // Password hashing
  "jsonwebtoken": "^9.x"       // JWT token handling
}
```

## Setup Instructions

### Prerequisites
- Node.js v14+ (we have v22.13.0 ✅)
- PostgreSQL v12+ (needs to be installed)
- npm v6+ (we have v10.9.2 ✅)

### Installation Steps

1. **Clone/Navigate to project:**
   ```bash
   cd /home/ubuntu/gemstone-app/backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Setup environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env file with your PostgreSQL credentials
   ```

4. **Create PostgreSQL database:**
   ```sql
   CREATE DATABASE gemstone_db;
   CREATE USER gemstone_user WITH PASSWORD 'your_password';
   GRANT ALL PRIVILEGES ON DATABASE gemstone_db TO gemstone_user;
   ```

5. **Update .env file:**
   ```
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=gemstone_db
   DB_USER=gemstone_user
   DB_PASSWORD=your_password
   JWT_SECRET=your_secure_jwt_secret_key
   ```

6. **Start the server:**
   ```bash
   npm start
   # or for development with auto-reload
   npm install -g nodemon
   nodemon server.js
   ```

## API Endpoints (Phase 1)

### Health Check
- **GET** `/api/health`
  - Response: `{ status: "OK", message: "Gemstone Management API is running" }`

## Next Steps (Phase 2)

Phase 2 တွင် အောက်ပါတွေကို အကောင်အထည်ဖော်ပါ့မယ်:

1. **Database Schema Creation**
   - User table (for authentication)
   - Gemstone table
   - Lot table
   - Sales table
   - Expenses table
   - Processing records table
   - Worker table
   - Broker table

2. **Authentication API**
   - User registration endpoint
   - User login endpoint
   - Token refresh endpoint
   - User logout endpoint
   - Password reset endpoints

3. **Database Models**
   - Sequelize models for all tables
   - Model relationships and associations
   - Validation rules

4. **Error Handling**
   - Custom error classes
   - Global error handler
   - Validation middleware

## Architecture Principles

### Clean Architecture
- Separation of concerns (routes, controllers, models, middleware)
- Business logic isolated from HTTP layer
- Easy to test and maintain

### Security
- JWT-based authentication
- Password hashing with bcryptjs
- Role-based access control
- Environment variable management

### Scalability
- Modular route structure
- Middleware-based architecture
- Connection pooling for database
- Error handling and logging ready

## Notes

- Database models will be created in Phase 2
- Authentication controllers will be implemented in Phase 2
- API documentation will be generated after Phase 2
- Frontend (Flutter) will be created in Phase 3

---

**Phase 1 Status: ✅ COMPLETE**

Ready to proceed to Phase 2: Database Schema & Authentication API Development
