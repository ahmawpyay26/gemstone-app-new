# Default Admin User Setup Guide

**Version:** 1.0.0  
**Last Updated:** May 31, 2026

---

## Overview

This guide explains how the default admin user is automatically created when the Gemstone Management Backend starts up for the first time.

---

## Default Admin Credentials

| Field | Value |
|-------|-------|
| **Email** | admin@gemstone.com |
| **Password** | admin123 |
| **Role** | Owner |
| **Status** | Active |

---

## How It Works

### 1. Automatic Creation on Startup

When the backend server starts, it automatically:

1. Connects to the database
2. Checks if an admin user already exists
3. If not, creates the default admin user with:
   - Email: `admin@gemstone.com`
   - Password: `admin123` (hashed with bcrypt)
   - Role: `Owner`
   - Status: `Active`

### 2. Password Security

The password is **never stored in plain text**. Instead:

1. Password is hashed using bcrypt with salt rounds = 10
2. Only the hashed password is stored in the database
3. When user logs in, the provided password is compared against the hash
4. The plain password `admin123` is only used during initial setup

### 3. Idempotent Creation

The script is **idempotent**, meaning:

- If admin user already exists, it won't create a duplicate
- Safe to run multiple times
- Safe to restart the server

---

## Files Involved

### 1. `backend/scripts/seedAdminUser.js`

Main script that handles admin user creation:

```javascript
// Functions:
- seedAdminUser()           // Main function
- createAdminUser()         // Create user in database
- adminUserExists()         // Check if admin exists
- verifyAdminCredentials()  // Verify login works
- hashPassword()            // Hash password with bcrypt
```

### 2. `backend/utils/initializeApp.js`

Initialization module called on server startup:

```javascript
// Functions:
- initializeApp()              // Main initialization
- verifyDatabaseConnection()   // Check database
- checkRequiredTables()        // Verify tables exist
- healthCheck()                // Health check endpoint
```

### 3. `backend/SERVER_STARTUP_EXAMPLE.js`

Example of how to integrate into your server startup code.

---

## Integration Steps

### Step 1: Add to Your Server File

In your main server file (e.g., `server.js` or `index.ts`), add:

```javascript
const { initializeApp, healthCheck } = require('./utils/initializeApp');

async function start() {
  try {
    // Initialize app (creates admin user if needed)
    await initializeApp();
    
    // Setup Express and routes...
    app.use('/api/auth', require('./routes/auth.routes'));
    // ... other routes ...

    // Health check endpoint
    app.get('/health', async (req, res) => {
      const health = await healthCheck();
      res.status(health.status === 'healthy' ? 200 : 503).json(health);
    });

    // Start server
    app.listen(PORT, () => {
      console.log(`✅ Server running on port ${PORT}`);
      console.log('🔐 Admin: admin@gemstone.com / admin123');
    });
  } catch (error) {
    console.error('❌ Failed to start:', error);
    process.exit(1);
  }
}

start();
```

### Step 2: Ensure Dependencies

Make sure these packages are installed:

```bash
npm install bcryptjs
npm install express
```

### Step 3: Test

Start the server:

```bash
npm start
```

You should see in logs:

```
🚀 Starting application initialization...
📦 Step 1/3: Verifying database connection...
✅ Database connection verified successfully
📦 Step 2/3: Checking required tables...
✅ All required tables exist
📦 Step 3/3: Seeding default admin user...
✅ Default admin user created successfully
✅ Application initialization completed successfully
✅ Server running on port 3001
🔐 Admin: admin@gemstone.com / admin123
```

---

## Manual Admin User Creation

If you need to create the admin user manually:

```bash
# From backend directory
node scripts/seedAdminUser.js
```

Output:

```
🌱 Starting admin user seed process...
✅ Default admin user created successfully
✅ Admin user creation completed
✅ Admin credentials verified successfully
✅ Admin user seed process completed successfully
📧 Admin Email: admin@gemstone.com
🔐 Admin Password: admin123
👤 Admin Role: Owner
```

---

## Verify Admin User

### Via Database Query

```sql
SELECT id, email, role, is_active, created_at 
FROM users 
WHERE email = 'admin@gemstone.com';
```

Expected output:

```
 id  |       email        | role  | is_active |         created_at
-----+--------------------+-------+-----------+----------------------------
  1  | admin@gemstone.com | Owner | t         | 2026-05-31 12:00:00+00:00
```

### Via API Login

```bash
curl -X POST http://localhost:3001/api/auth/login \
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
    "id": 1,
    "email": "admin@gemstone.com",
    "role": "Owner",
    "firstName": "Admin",
    "lastName": "User"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Via Web Dashboard

1. Navigate to `https://your-domain.com/login`
2. Enter credentials:
   - Email: `admin@gemstone.com`
   - Password: `admin123`
3. Click "Login"

---

## Changing Admin Password

After first login, change the default password:

### Via API

```bash
curl -X POST http://localhost:3001/api/auth/change-password \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "oldPassword": "admin123",
    "newPassword": "new_secure_password_123"
  }'
```

### Via Web Dashboard

1. Login with admin credentials
2. Go to Settings → Profile
3. Click "Change Password"
4. Enter old password and new password
5. Click "Save"

---

## Security Recommendations

### ⚠️ Important

1. **Change Default Password Immediately**
   - The default password `admin123` is publicly known
   - Change it to a strong, unique password after first login

2. **Use Strong Passwords**
   - Minimum 12 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - Example: `G3m$t0ne@Admin2026!`

3. **Enable 2FA** (if implemented)
   - Add two-factor authentication for admin account
   - Use authenticator app or SMS

4. **Restrict Admin Access**
   - Use VPN for admin access
   - Whitelist admin IP addresses
   - Enable rate limiting on login

5. **Monitor Admin Activity**
   - Check audit logs regularly
   - Alert on suspicious admin activities
   - Review login history

---

## Troubleshooting

### Issue: Admin User Not Created

**Symptoms:**
- Login fails with `admin@gemstone.com`
- No admin user in database

**Solutions:**

1. Check database connection:
   ```bash
   psql -U gemstone_user -d gemstone_production -c "SELECT 1"
   ```

2. Check if users table exists:
   ```bash
   psql -U gemstone_user -d gemstone_production -c "\dt users"
   ```

3. Run seed script manually:
   ```bash
   node backend/scripts/seedAdminUser.js
   ```

4. Check server logs:
   ```bash
   pm2 logs gemstone-backend
   ```

### Issue: Password Hash Mismatch

**Symptoms:**
- Login fails even with correct password
- Error: `Invalid credentials`

**Solutions:**

1. Delete existing admin user:
   ```sql
   DELETE FROM users WHERE email = 'admin@gemstone.com';
   ```

2. Restart server to recreate admin user

3. Or manually run seed script:
   ```bash
   node backend/scripts/seedAdminUser.js
   ```

### Issue: Duplicate Admin Users

**Symptoms:**
- Multiple admin users with same email
- Unclear which one is active

**Solutions:**

1. Check all admin users:
   ```sql
   SELECT id, email, role, is_active FROM users WHERE role = 'Owner';
   ```

2. Deactivate duplicates:
   ```sql
   UPDATE users SET is_active = false WHERE id IN (2, 3);
   ```

3. Keep only one active admin user

---

## Database Schema

The admin user is stored in the `users` table:

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,  -- bcrypt hash
  role VARCHAR(50) NOT NULL,        -- Owner, Accountant, Worker, Broker
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  phone VARCHAR(20),
  is_active BOOLEAN DEFAULT true,
  last_login TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

---

## API Endpoints

### Login

```
POST /api/auth/login
Content-Type: application/json

{
  "email": "admin@gemstone.com",
  "password": "admin123"
}
```

### Verify Token

```
GET /api/auth/me
Authorization: Bearer <token>
```

### Logout

```
POST /api/auth/logout
Authorization: Bearer <token>
```

### Change Password

```
POST /api/auth/change-password
Authorization: Bearer <token>
Content-Type: application/json

{
  "oldPassword": "admin123",
  "newPassword": "new_password"
}
```

---

## Logs

### Server Startup Logs

```
🚀 Starting application initialization...
📦 Step 1/3: Verifying database connection...
✅ Database connection verified successfully
📦 Step 2/3: Checking required tables...
✅ All required tables exist
📦 Step 3/3: Seeding default admin user...
✅ Default admin user created successfully
✅ Application initialization completed successfully
```

### Seed Script Logs

```
🌱 Starting admin user seed process...
✅ Default admin user created successfully
📧 Admin Email: admin@gemstone.com
🔐 Admin Password: admin123
👤 Admin Role: Owner
✅ Admin user seed process completed successfully
```

---

## Testing Checklist

- [ ] Server starts without errors
- [ ] Admin user created on first startup
- [ ] Admin user not duplicated on restart
- [ ] Login works with admin credentials
- [ ] JWT token generated correctly
- [ ] Token refresh works
- [ ] Logout clears session
- [ ] Password change works
- [ ] Admin has all permissions
- [ ] Audit log records admin activities

---

## Support

For issues or questions:

1. Check logs: `pm2 logs gemstone-backend`
2. Check database: `psql -U gemstone_user -d gemstone_production`
3. Run seed script: `node backend/scripts/seedAdminUser.js`
4. Contact support: support@gemstone.local

---

**Document Version:** 1.0.0  
**Last Updated:** May 31, 2026  
**Next Review:** June 30, 2026
