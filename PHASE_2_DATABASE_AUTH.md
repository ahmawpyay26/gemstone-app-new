# Phase 2: Database Schema & Authentication API Development

## Overview
Phase 2 သည် PostgreSQL Database Schema ကို အကောင်အထည်ဖော်ပြီး User Authentication (Register/Login) အတွက် REST APIs များကို ရေးသားသည့် အဆင့်ဖြစ်ပါသည်။

## Completed in Phase 2

### 1. ✅ Database Schema Creation
- **12 Main Tables** created with proper relationships
- **Indexes** for performance optimization
- **Views** for reporting (Profit/Loss, Inventory Valuation, Worker Performance)

### 2. ✅ Database Tables

| Table Name | Purpose |
|-----------|---------|
| `users` | User authentication and role management |
| `gemstones` | Individual stone inventory tracking |
| `lots` | Bulk gemstone lot management |
| `lot_splits` | Track lot splitting operations |
| `processing_records` | Polishing, cutting, and other processes |
| `workers` | Worker management and specialization |
| `machines` | Machine inventory and maintenance |
| `expenses` | Cost tracking (worker, machine, tools, oil) |
| `sales` | Sales transactions |
| `sale_items` | Individual items in each sale |
| `brokers` | Broker management and commission tracking |
| `waste_stones` | Track waste and damaged stones |

### 3. ✅ Sequelize Models
- **User Model** created with validation
- Password hashing with bcryptjs
- Role-based access control (owner, accountant, worker, broker)

### 4. ✅ Authentication APIs

#### Register Endpoint
```
POST /api/auth/register
Content-Type: application/json

Request Body:
{
  "email": "user@example.com",
  "password": "secure_password",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+95912345678",
  "role": "owner"
}

Response (201 Created):
{
  "status": "success",
  "message": "User registered successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "uuid-user-id",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "role": "owner"
    }
  }
}
```

#### Login Endpoint
```
POST /api/auth/login
Content-Type: application/json

Request Body:
{
  "email": "user@example.com",
  "password": "secure_password"
}

Response (200 OK):
{
  "status": "success",
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "uuid-user-id",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "role": "owner"
    }
  }
}
```

#### Refresh Token Endpoint
```
POST /api/auth/refresh-token
Content-Type: application/json

Request Body:
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}

Response (200 OK):
{
  "status": "success",
  "message": "Token refreshed successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

#### Get Current User Endpoint
```
GET /api/auth/me
Authorization: Bearer <accessToken>

Response (200 OK):
{
  "status": "success",
  "data": {
    "id": "uuid-user-id",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "owner",
    "is_active": true,
    "created_at": "2026-05-27T10:00:00Z"
  }
}
```

#### Logout Endpoint
```
POST /api/auth/logout
Authorization: Bearer <accessToken>

Response (200 OK):
{
  "status": "success",
  "message": "Logout successful"
}
```

### 5. ✅ Authentication Features
- User registration with email validation
- Secure password hashing (bcryptjs)
- JWT-based authentication (access + refresh tokens)
- Token refresh mechanism
- Role-based access control
- User profile retrieval

### 6. ✅ Security Implementation
- Password hashing with bcrypt salt (10 rounds)
- JWT tokens with expiration
- Separate access and refresh tokens
- Email uniqueness validation
- User active status checking

## Files Created

```
backend/
├── database/
│   └── schema.sql                 # Complete PostgreSQL schema
├── models/
│   └── User.js                    # Sequelize User model
├── controllers/
│   └── auth.controller.js         # Authentication logic
├── routes/
│   └── auth.routes.js             # Auth API routes
├── package.json                   # Updated with scripts
└── PHASE_2_DATABASE_AUTH.md       # This file
```

## Database Setup Instructions

### 1. Create PostgreSQL Database
```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE gemstone_db;

# Create user
CREATE USER gemstone_user WITH PASSWORD 'your_secure_password';

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE gemstone_db TO gemstone_user;

# Exit
\q
```

### 2. Create Tables
```bash
# Run the schema file
psql -U gemstone_user -d gemstone_db -f backend/database/schema.sql
```

### 3. Update .env File
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=gemstone_db
DB_USER=gemstone_user
DB_PASSWORD=your_secure_password
JWT_SECRET=your_super_secret_jwt_key_change_in_production
JWT_EXPIRE=7d
JWT_REFRESH_SECRET=your_super_secret_refresh_key_change_in_production
JWT_REFRESH_EXPIRE=30d
```

## Testing Authentication APIs

### Using cURL

```bash
# Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "first_name": "Test",
    "last_name": "User",
    "role": "owner"
  }'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# Get Current User (replace TOKEN with actual token)
curl -X GET http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer TOKEN"
```

### Using Postman
1. Import the API endpoints
2. Set up environment variables for tokens
3. Test each endpoint sequentially

## Database Relationships

### User Relationships
- User → Gemstones (creator)
- User → Lots (creator)
- User → Sales (creator)
- User → Expenses (creator)
- User → ProcessingRecords (creator)
- User → Workers (user profile)
- User → Brokers (user profile)

### Gemstone Relationships
- Gemstone → Lot (belongs to lot)
- Gemstone → ProcessingRecords (has many)
- Gemstone → Expenses (has many)
- Gemstone → SaleItems (sold in sales)
- Gemstone → WasteStones (tracked if waste/damaged)

### Sales Relationships
- Sale → SaleItems (has many)
- SaleItem → Gemstone (belongs to)
- Sale → Broker (optional)

## Error Codes

| Code | HTTP Status | Message |
|------|-------------|---------|
| VALIDATION_ERROR | 400 | Missing or invalid input |
| USER_EXISTS | 409 | User with email already exists |
| INVALID_CREDENTIALS | 401 | Invalid email or password |
| ACCOUNT_INACTIVE | 403 | User account is inactive |
| UNAUTHORIZED | 401 | Missing or invalid token |
| USER_NOT_FOUND | 404 | User not found |
| TOKEN_REFRESH_ERROR | 401 | Token refresh failed |

## Next Steps (Phase 3)

Phase 3 တွင် အောက်ပါတွေကို အကောင်အထည်ဖော်ပါ့မယ်:

1. **Flutter Project Initialization**
   - Clean Architecture setup
   - Folder structure creation
   - BLoC/Cubit state management

2. **Authentication UI (Dark Luxury Style)**
   - Login screen
   - Register screen
   - Splash screen
   - Profile screen

3. **API Integration**
   - Dio HTTP client setup
   - API service layer
   - Token management
   - Offline storage

---

**Phase 2 Status: ✅ COMPLETE**

Ready to proceed to Phase 3: Flutter Project Initialization & Authentication UI
