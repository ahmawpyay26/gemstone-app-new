# Audit Trail System - Testing Guide

## Test Cases

### 1. Authentication Logging

#### Test 1.1: Login Success
```
Precondition: Valid user credentials exist
Steps:
1. Navigate to login page
2. Enter valid email and password
3. Click login button
Expected:
- User is logged in
- Audit log created with:
  - action_type: LOGIN
  - module_name: AUTH
  - status: SUCCESS
  - user_email: [email used]
  - user_role: [role of user]
```

#### Test 1.2: Login Failure
```
Precondition: User exists
Steps:
1. Navigate to login page
2. Enter valid email but wrong password
3. Click login button
Expected:
- Login fails with error message
- Audit log created with:
  - action_type: LOGIN
  - module_name: AUTH
  - status: FAILURE
  - error_message: "Invalid credentials"
```

#### Test 1.3: Logout
```
Precondition: User is logged in
Steps:
1. Click logout button
Expected:
- User is logged out and redirected to login
- Audit log created with:
  - action_type: LOGOUT
  - module_name: AUTH
  - status: SUCCESS
```

### 2. Inventory Operations Logging

#### Test 2.1: Create Gemstone
```
Precondition: Owner is logged in
Steps:
1. Navigate to Inventory page
2. Click "Add Gemstone" button
3. Fill in gemstone details
4. Click save
Expected:
- Gemstone is created
- Audit log created with:
  - action_type: CREATE
  - module_name: GEMSTONE
  - status: SUCCESS
  - entity_id: [gemstone_id]
  - entity_name: [gemstone_name]
  - after_value: [gemstone data]
  - before_value: null
```

#### Test 2.2: Update Gemstone
```
Precondition: Gemstone exists, Owner is logged in
Steps:
1. Navigate to Inventory page
2. Click edit on a gemstone
3. Modify gemstone details
4. Click save
Expected:
- Gemstone is updated
- Audit log created with:
  - action_type: UPDATE
  - module_name: GEMSTONE
  - status: SUCCESS
  - entity_id: [gemstone_id]
  - before_value: [old data]
  - after_value: [new data]
```

#### Test 2.3: Delete Gemstone
```
Precondition: Gemstone exists, Owner is logged in
Steps:
1. Navigate to Inventory page
2. Click delete on a gemstone
3. Confirm deletion
Expected:
- Gemstone is deleted
- Audit log created with:
  - action_type: DELETE
  - module_name: GEMSTONE
  - status: SUCCESS
  - entity_id: [gemstone_id]
  - before_value: [deleted data]
```

### 3. Sales Operations Logging

#### Test 3.1: Create Sale
```
Precondition: Owner/Accountant logged in, gemstones exist
Steps:
1. Navigate to Sales page
2. Click "New Sale"
3. Select gemstone and buyer
4. Enter sale details
5. Click save
Expected:
- Sale is created
- Audit log created with:
  - action_type: CREATE
  - module_name: SALE
  - status: SUCCESS
  - entity_id: [sale_id]
```

#### Test 3.2: Update Sale
```
Precondition: Sale exists, Accountant logged in
Steps:
1. Navigate to Sales page
2. Click edit on a sale
3. Modify sale details
4. Click save
Expected:
- Sale is updated
- Audit log created with:
  - action_type: UPDATE
  - module_name: SALE
  - before_value: [old sale data]
  - after_value: [new sale data]
```

### 4. Expense Operations Logging

#### Test 4.1: Create Expense
```
Precondition: Worker/Accountant logged in
Steps:
1. Navigate to Expenses page
2. Click "Add Expense"
3. Fill in expense details
4. Click save
Expected:
- Expense is created
- Audit log created with:
  - action_type: CREATE
  - module_name: EXPENSE
  - status: SUCCESS
```

### 5. User Management Logging

#### Test 5.1: Create User
```
Precondition: Owner is logged in
Steps:
1. Navigate to User Management
2. Click "Add User"
3. Fill in user details
4. Assign role
5. Click save
Expected:
- User is created
- Audit log created with:
  - action_type: CREATE
  - module_name: USER
  - entity_name: [user_email]
  - after_value: [user data including role]
```

#### Test 5.2: Update User Role
```
Precondition: User exists, Owner is logged in
Steps:
1. Navigate to User Management
2. Click edit on a user
3. Change user role
4. Click save
Expected:
- User role is updated
- Audit log created with:
  - action_type: UPDATE
  - module_name: USER
  - before_value: { role: 'old_role' }
  - after_value: { role: 'new_role' }
```

#### Test 5.3: Disable User
```
Precondition: User exists, Owner is logged in
Steps:
1. Navigate to User Management
2. Click disable on a user
3. Confirm
Expected:
- User is disabled
- Audit log created with:
  - action_type: UPDATE
  - module_name: USER
  - before_value: { is_active: true }
  - after_value: { is_active: false }
```

### 6. Audit Dashboard Tests

#### Test 6.1: View Audit Logs
```
Precondition: Owner/Accountant logged in, audit logs exist
Steps:
1. Navigate to Audit Logs page
2. Verify logs are displayed
Expected:
- Audit logs are displayed in table
- Columns show: User, Action, Module, Status, Timestamp
- Logs are sorted by timestamp (newest first)
```

#### Test 6.2: Filter by Module
```
Precondition: Multiple audit logs exist
Steps:
1. Navigate to Audit Logs page
2. Select "GEMSTONE" from Module filter
3. Click apply
Expected:
- Only GEMSTONE module logs are displayed
- Count matches filtered results
```

#### Test 6.3: Filter by Date Range
```
Precondition: Audit logs exist across multiple days
Steps:
1. Navigate to Audit Logs page
2. Select start date and end date
3. Click apply
Expected:
- Only logs within date range are displayed
```

#### Test 6.4: Filter by Action Type
```
Precondition: Multiple action types exist
Steps:
1. Navigate to Audit Logs page
2. Select "CREATE" from Action Type filter
3. Click apply
Expected:
- Only CREATE action logs are displayed
```

#### Test 6.5: Search by User
```
Precondition: Multiple users have performed actions
Steps:
1. Navigate to Audit Logs page
2. Enter user email in search
3. Click apply
Expected:
- Only logs from that user are displayed
```

#### Test 6.6: View Log Details
```
Precondition: Audit logs exist
Steps:
1. Navigate to Audit Logs page
2. Click eye icon on a log entry
3. View detail modal
Expected:
- Modal shows:
  - User info
  - Action type and module
  - Timestamp
  - Before/After values (if applicable)
  - IP address
  - Error message (if failed)
```

#### Test 6.7: Export Audit Logs
```
Precondition: Audit logs exist
Steps:
1. Navigate to Audit Logs page
2. Apply filters (optional)
3. Click "Export to CSV" button
Expected:
- CSV file is downloaded
- File contains all filtered logs
- Columns: User, Role, Action, Module, Status, Timestamp, Description
```

#### Test 6.8: Pagination
```
Precondition: More than 50 audit logs exist
Steps:
1. Navigate to Audit Logs page
2. Verify pagination controls
3. Click "Next" button
Expected:
- Next page of logs is displayed
- Page number updates
- Previous button becomes enabled
```

### 7. Role-Based Access Tests

#### Test 7.1: Worker Cannot Access Audit Logs
```
Precondition: Worker is logged in
Steps:
1. Try to navigate to /audit-logs
Expected:
- Access denied message or 403 error
- Audit Logs not visible in menu
```

#### Test 7.2: Broker Cannot Access Audit Logs
```
Precondition: Broker is logged in
Steps:
1. Try to navigate to /audit-logs
Expected:
- Access denied message or 403 error
- Audit Logs not visible in menu
```

#### Test 7.3: Accountant Can Access Audit Logs
```
Precondition: Accountant is logged in
Steps:
1. Navigate to Audit Logs page
Expected:
- Audit Logs page loads successfully
- Can view all logs
- Can filter and search
```

#### Test 7.4: Owner Can Access Audit Logs
```
Precondition: Owner is logged in
Steps:
1. Navigate to Audit Logs page
Expected:
- Audit Logs page loads successfully
- Can view all logs
- Can filter, search, and export
```

### 8. Data Integrity Tests

#### Test 8.1: Verify Log Immutability
```
Precondition: Audit log exists in database
Steps:
1. Try to update an audit log record directly
Expected:
- Update fails or is prevented
- Audit logs should be immutable
```

#### Test 8.2: Verify All Required Fields
```
Precondition: Multiple audit logs exist
Steps:
1. Query audit logs from database
2. Verify each log has all required fields
Expected:
- All logs have: id, user_id, action_type, module_name, created_at
- All logs have: status (SUCCESS/FAILURE)
- Failed logs have: error_message
- Update/Delete logs have: before_value, after_value
```

#### Test 8.3: Verify Timestamp Accuracy
```
Precondition: Audit log is created
Steps:
1. Create an action (e.g., create gemstone)
2. Check audit log timestamp
3. Compare with current time
Expected:
- Timestamp is within 1 second of action time
- Timestamp is in UTC or consistent timezone
```

### 9. Performance Tests

#### Test 9.1: Load 1000 Logs
```
Precondition: 1000+ audit logs exist
Steps:
1. Navigate to Audit Logs page
2. Measure page load time
Expected:
- Page loads in < 2 seconds
- All logs displayed correctly
- No console errors
```

#### Test 9.2: Filter Performance
```
Precondition: 10000+ audit logs exist
Steps:
1. Navigate to Audit Logs page
2. Apply complex filter (user + module + date range)
3. Measure query time
Expected:
- Results displayed in < 500ms
- No timeout errors
```

#### Test 9.3: Export Performance
```
Precondition: 10000+ audit logs exist
Steps:
1. Navigate to Audit Logs page
2. Click Export to CSV
3. Measure export time
Expected:
- CSV generated in < 5 seconds
- File size reasonable (< 10MB)
```

## Test Data Setup

### Create Test Users
```javascript
const testUsers = [
  { email: 'owner@test.com', role: 'owner', password: 'test123' },
  { email: 'accountant@test.com', role: 'accountant', password: 'test123' },
  { email: 'worker@test.com', role: 'worker', password: 'test123' },
  { email: 'broker@test.com', role: 'broker', password: 'test123' }
];
```

### Create Test Gemstones
```javascript
const testGemstones = [
  { name: 'Ruby', carat: 5.5, price: 50000 },
  { name: 'Sapphire', carat: 3.2, price: 30000 },
  { name: 'Emerald', carat: 2.8, price: 25000 }
];
```

## Automated Testing Script

```javascript
// audit.test.js
const request = require('supertest');
const app = require('../server');

describe('Audit Logging System', () => {
  let ownerToken, accountantToken;

  before(async () => {
    // Login as owner
    const ownerRes = await request(app)
      .post('/api/auth/login')
      .send({ email: 'owner@test.com', password: 'test123' });
    ownerToken = ownerRes.body.data.accessToken;

    // Login as accountant
    const accountantRes = await request(app)
      .post('/api/auth/login')
      .send({ email: 'accountant@test.com', password: 'test123' });
    accountantToken = accountantRes.body.data.accessToken;
  });

  describe('Audit Log Creation', () => {
    it('should create audit log on gemstone create', async () => {
      const gemstoneRes = await request(app)
        .post('/api/gemstones')
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ name: 'Test Ruby', carat: 5, price: 50000 });

      const auditRes = await request(app)
        .get('/api/audit/logs')
        .set('Authorization', `Bearer ${ownerToken}`)
        .query({ moduleName: 'GEMSTONE', actionType: 'CREATE' });

      expect(auditRes.body.data).toHaveLength(1);
      expect(auditRes.body.data[0].entity_id).toBe(gemstoneRes.body.data.id);
    });
  });

  describe('Audit Log Filtering', () => {
    it('should filter logs by module', async () => {
      const res = await request(app)
        .get('/api/audit/logs')
        .set('Authorization', `Bearer ${ownerToken}`)
        .query({ moduleName: 'GEMSTONE' });

      expect(res.body.data.every(log => log.module_name === 'GEMSTONE')).toBe(true);
    });
  });

  describe('Access Control', () => {
    it('should deny worker access to audit logs', async () => {
      const workerRes = await request(app)
        .post('/api/auth/login')
        .send({ email: 'worker@test.com', password: 'test123' });
      const workerToken = workerRes.body.data.accessToken;

      const res = await request(app)
        .get('/api/audit/logs')
        .set('Authorization', `Bearer ${workerToken}`);

      expect(res.status).toBe(403);
    });
  });
});
```

## Verification Checklist

- [ ] All CRUD operations create audit logs
- [ ] Login/Logout events are logged
- [ ] Before/After values are captured correctly
- [ ] Failed operations show error messages
- [ ] Audit logs are immutable
- [ ] Role-based access is enforced
- [ ] Filtering works correctly
- [ ] Pagination works correctly
- [ ] Export to CSV works
- [ ] Performance is acceptable (< 500ms for queries)
- [ ] All required fields are populated
- [ ] Timestamps are accurate
- [ ] IP addresses are captured
- [ ] User roles are logged correctly
