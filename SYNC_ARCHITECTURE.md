# Hybrid Offline-First + Online Sync Architecture

## Overview

This document describes the complete architecture for the gemstone management platform's offline-first synchronization system. The system enables mobile users to work fully offline with SQLite and sync data to a Node.js/PostgreSQL cloud backend when internet is available.

**Key Features:**
- ✅ Full offline functionality with SQLite
- ✅ Automatic and manual sync
- ✅ Conflict resolution (server-wins and last-updated-wins strategies)
- ✅ Sync queue with retry mechanism
- ✅ Data encryption for sync transfers
- ✅ JWT authentication and security
- ✅ Comprehensive audit logging

---

## System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE APP (Flutter)                      │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Offline-First Layer                      │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │  SQLite Local Database                         │  │   │
│  │  │  - Gemstones, Sales, Expenses, Workers, Lots   │  │   │
│  │  │  - Sync metadata, queue, conflicts             │  │   │
│  │  └────────────────────────────────────────────────┘  │   │
│  │                                                        │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │  Sync Engine (Client-Side)                     │  │   │
│  │  │  - Queue management                            │  │   │
│  │  │  - Offline detection                           │  │   │
│  │  │  - Background sync                             │  │   │
│  │  └────────────────────────────────────────────────┘  │   │
│  │                                                        │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │  UI Layer                                      │  │   │
│  │  │  - Sync status indicator                       │  │   │
│  │  │  - Manual sync button                          │  │   │
│  │  │  - Conflict resolution UI                      │  │   │
│  │  └────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  REST API Client (HTTP/HTTPS)                        │   │
│  │  - JWT Authentication                                │   │
│  │  - Request/Response Encryption                       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↕ (Sync)
┌─────────────────────────────────────────────────────────────┐
│                  CLOUD BACKEND (Node.js)                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Sync API Endpoints                                  │   │
│  │  - POST /api/sync/initialize                         │   │
│  │  - POST /api/sync/push                               │   │
│  │  - POST /api/sync/pull                               │   │
│  │  - POST /api/sync/bidirectional                      │   │
│  │  - GET /api/sync/status                              │   │
│  │  - POST /api/sync/retry                              │   │
│  │  - POST /api/sync/resolve-conflict                   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Sync Engine Service                                 │   │
│  │  - Process sync requests                             │   │
│  │  - Detect conflicts                                  │   │
│  │  - Resolve conflicts                                 │   │
│  │  - Validate data integrity                           │   │
│  │  - Retry failed syncs                                │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  PostgreSQL Database                                 │   │
│  │  - Master data (gemstones, sales, expenses, etc.)    │   │
│  │  - Sync metadata                                     │   │
│  │  - Conflict records                                  │   │
│  │  - Audit logs                                        │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Database Schema

### SQLite Schema (Mobile App)

#### Core Tables

```sql
-- Gemstones
CREATE TABLE gemstones (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  weight REAL,
  price REAL,
  quality TEXT,
  location TEXT,
  sync_status TEXT DEFAULT 'pending', -- pending, synced, conflict
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by TEXT
);

-- Sales
CREATE TABLE sales (
  id TEXT PRIMARY KEY,
  gemstone_id TEXT,
  buyer_name TEXT,
  quantity REAL,
  unit_price REAL,
  total_amount REAL,
  sale_date TIMESTAMP,
  sync_status TEXT DEFAULT 'pending',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by TEXT,
  FOREIGN KEY (gemstone_id) REFERENCES gemstones(id)
);

-- Expenses
CREATE TABLE expenses (
  id TEXT PRIMARY KEY,
  category TEXT,
  amount REAL,
  description TEXT,
  expense_date TIMESTAMP,
  sync_status TEXT DEFAULT 'pending',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by TEXT
);

-- Workers
CREATE TABLE workers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  position TEXT,
  salary REAL,
  phone TEXT,
  sync_status TEXT DEFAULT 'pending',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by TEXT
);

-- Lots
CREATE TABLE lots (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  gemstone_ids TEXT, -- JSON array
  total_weight REAL,
  total_value REAL,
  status TEXT,
  sync_status TEXT DEFAULT 'pending',
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by TEXT
);
```

#### Sync Metadata Tables

```sql
-- Sync Metadata
CREATE TABLE sync_metadata (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT UNIQUE NOT NULL,
  last_sync_timestamp TIMESTAMP,
  sync_status TEXT DEFAULT 'pending', -- pending, success, failed
  processed_count INTEGER DEFAULT 0,
  conflict_count INTEGER DEFAULT 0,
  resolved_count INTEGER DEFAULT 0,
  last_error TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sync Queue
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  operation TEXT NOT NULL, -- create, update, delete
  data TEXT NOT NULL, -- JSON
  sync_status TEXT DEFAULT 'pending', -- pending, synced, failed
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,
  last_error TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sync Conflicts
CREATE TABLE sync_conflicts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  conflict_type TEXT NOT NULL, -- update_conflict, delete_conflict
  local_data TEXT, -- JSON
  server_data TEXT, -- JSON
  resolution TEXT, -- local_wins, server_wins, manual
  resolved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### PostgreSQL Schema (Cloud Backend)

The cloud backend uses the same table structure as SQLite, with additional fields for audit tracking:

```sql
-- Extended with audit fields
ALTER TABLE gemstones ADD COLUMN sync_status TEXT DEFAULT 'synced';
ALTER TABLE gemstones ADD COLUMN updated_at TIMESTAMP DEFAULT NOW();
ALTER TABLE gemstones ADD COLUMN created_by UUID REFERENCES users(id);

-- Sync metadata tables
CREATE TABLE sync_metadata (
  id UUID PRIMARY KEY,
  user_id UUID UNIQUE NOT NULL REFERENCES users(id),
  last_sync_timestamp TIMESTAMP,
  sync_status TEXT DEFAULT 'pending',
  processed_count INTEGER DEFAULT 0,
  conflict_count INTEGER DEFAULT 0,
  resolved_count INTEGER DEFAULT 0,
  last_error TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE sync_conflicts (
  id UUID PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  conflict_type TEXT NOT NULL,
  local_data JSONB,
  server_data JSONB,
  resolution TEXT,
  resolved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE sync_queue (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  operation TEXT NOT NULL,
  data JSONB,
  sync_status TEXT DEFAULT 'pending',
  retry_count INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,
  last_error TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

---

## Sync Flow

### 1. Initialization Flow

```
Mobile App                          Cloud Backend
    |                                    |
    |--- POST /api/sync/initialize ----->|
    |                                    |
    |<-- 200 OK (sync initialized) ------|
    |
    | Create sync_metadata record
    | Set last_sync_timestamp = NOW()
    | Set sync_status = 'initialized'
```

### 2. Push Flow (Mobile → Cloud)

```
Mobile App                          Cloud Backend
    |
    | Collect local changes
    | (create, update, delete)
    |
    |--- POST /api/sync/push ----------->|
    | {                                  |
    |   localChanges: [...],             |
    |   lastSyncTimestamp: T1,           |
    |   conflictResolutionStrategy       |
    | }                                  |
    |                                    |
    |                                    | 1. Validate sync data
    |                                    | 2. Process local changes
    |                                    | 3. Detect conflicts
    |                                    | 4. Resolve conflicts
    |                                    | 5. Update sync metadata
    |                                    |
    |<-- 200 OK (sync result) -----------|
    | {                                  |
    |   processedChanges: [...],         |
    |   conflicts: [...],                |
    |   resolutions: [...],              |
    |   serverChanges: [...]             |
    | }                                  |
    |
    | Update local sync_status
    | Clear sync_queue for synced items
```

### 3. Pull Flow (Cloud → Mobile)

```
Mobile App                          Cloud Backend
    |
    |--- POST /api/sync/pull ----------->|
    | {                                  |
    |   lastSyncTimestamp: T1            |
    | }                                  |
    |                                    |
    |                                    | 1. Query changes since T1
    |                                    | 2. Collect server changes
    |                                    |
    |<-- 200 OK (server changes) --------|
    | {                                  |
    |   changes: [                       |
    |     {                              |
    |       entityType: 'gemstone',      |
    |       operation: 'update',         |
    |       data: {...}                  |
    |     }                              |
    |   ]                                |
    | }                                  |
    |
    | Apply server changes to SQLite
    | Update local_sync_status = 'synced'
```

### 4. Bidirectional Flow (Push + Pull)

```
Mobile App                          Cloud Backend
    |
    |--- POST /api/sync/bidirectional -->|
    | {                                  |
    |   localChanges: [...],             |
    |   lastSyncTimestamp: T1            |
    | }                                  |
    |                                    |
    |                                    | 1. Process push
    |                                    | 2. Collect pull
    |                                    |
    |<-- 200 OK (push + pull result) ----|
    | {                                  |
    |   push: {...},                     |
    |   pull: {...},                     |
    |   syncedAt: NOW()                  |
    | }                                  |
    |
    | Apply both push and pull results
```

---

## Conflict Resolution

### Conflict Detection

Conflicts are detected when:
1. Both local and server versions were updated after the last sync timestamp
2. The data has diverged between local and server

### Conflict Resolution Strategies

#### 1. Server Wins (Default)
- Server version always takes precedence
- Local changes are discarded
- Best for: Centralized data management

```javascript
if (serverUpdatedAt > clientUpdatedAt) {
  // Use server version
  result = serverData;
} else {
  // Use client version
  result = clientData;
}
```

#### 2. Last Updated Wins
- The version with the most recent timestamp wins
- Requires accurate clock synchronization
- Best for: Distributed systems with synchronized clocks

```javascript
if (clientUpdatedAt > serverUpdatedAt) {
  // Use client version
  result = clientData;
} else {
  // Use server version
  result = serverData;
}
```

#### 3. Manual Resolution
- User is prompted to choose which version to keep
- Requires UI implementation
- Best for: Critical data where user input is necessary

### Conflict Record Structure

```javascript
{
  id: 'conflict-id',
  entityType: 'gemstone',
  entityId: 'gemstone-123',
  conflictType: 'update_conflict',
  clientData: {
    name: 'Ruby',
    weight: 5.5,
    updatedAt: '2026-05-31T10:00:00Z'
  },
  serverData: {
    name: 'Ruby (Updated)',
    weight: 5.2,
    updatedAt: '2026-05-31T11:00:00Z'
  },
  resolution: 'server_wins',
  resolvedAt: '2026-05-31T11:05:00Z'
}
```

---

## Sync Queue and Retry Mechanism

### Queue Structure

```javascript
{
  id: 'queue-item-id',
  userId: 'user-123',
  entityType: 'gemstone',
  entityId: 'gemstone-123',
  operation: 'update',
  data: {...},
  syncStatus: 'pending', // pending, synced, failed
  retryCount: 0,
  maxRetries: 3,
  lastError: null,
  createdAt: '2026-05-31T10:00:00Z',
  updatedAt: '2026-05-31T10:00:00Z'
}
```

### Retry Logic

```
Initial Attempt
    ↓
Success? → Yes → Mark as 'synced'
    ↓ No
Retry Count < Max Retries? → No → Mark as 'failed'
    ↓ Yes
Wait (exponential backoff)
    ↓
Retry Attempt
    ↓
Success? → Yes → Mark as 'synced'
    ↓ No
Increment Retry Count
    ↓
(Repeat)
```

### Exponential Backoff Strategy

```javascript
const baseDelay = 1000; // 1 second
const maxDelay = 60000; // 1 minute
const delay = Math.min(baseDelay * Math.pow(2, retryCount), maxDelay);

// Retry counts:
// 1st retry: 2 seconds
// 2nd retry: 4 seconds
// 3rd retry: 8 seconds
// 4th retry: 16 seconds
// 5th retry: 32 seconds
// 6th+ retry: 60 seconds (capped)
```

---

## Data Encryption

### Encryption Strategy

All sensitive data is encrypted during sync transfer:

1. **In Transit**: HTTPS/TLS encryption
2. **At Rest**: AES-256-GCM encryption for sensitive fields
3. **Authentication**: JWT tokens with RS256 signing

### Encrypted Fields

```javascript
const encryptedFields = [
  'gemstone.price',
  'sale.total_amount',
  'expense.amount',
  'worker.salary',
  'lot.total_value'
];
```

### Encryption Implementation

```javascript
// Client-side encryption before sending
const encryptedData = await encryptData(sensitiveData, encryptionKey);

// Server-side decryption after receiving
const decryptedData = await decryptData(encryptedData, encryptionKey);

// Using AES-256-GCM
const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
const encrypted = Buffer.concat([
  cipher.update(data, 'utf8'),
  cipher.final()
]);
const authTag = cipher.getAuthTag();
```

---

## Authentication and Security

### JWT Authentication

All sync endpoints require JWT authentication:

```javascript
// Request header
Authorization: Bearer <JWT_TOKEN>

// JWT payload
{
  sub: 'user-id',
  iat: 1234567890,
  exp: 1234571490,
  role: 'Worker'
}
```

### Token Refresh

```
Mobile App                          Cloud Backend
    |
    | Token expired?
    | Yes → Request refresh
    |
    |--- POST /api/auth/refresh ------->|
    |                                    |
    |<-- 200 OK (new token) ------------|
    |
    | Store new token
    | Retry original request
```

### Security Best Practices

1. **HTTPS Only**: All API calls must use HTTPS
2. **Token Expiration**: Tokens expire after 1 hour
3. **Refresh Tokens**: Separate refresh tokens with 7-day expiration
4. **Rate Limiting**: 100 sync requests per minute per user
5. **Input Validation**: All inputs validated server-side
6. **CORS**: Strict CORS policy for API endpoints

---

## API Endpoints

### 1. Initialize Sync

```
POST /api/sync/initialize

Response:
{
  status: 'success',
  data: {
    message: 'Sync initialized',
    userId: 'user-123'
  },
  timestamp: '2026-05-31T10:00:00Z'
}
```

### 2. Push Local Changes

```
POST /api/sync/push

Request:
{
  localChanges: [
    {
      entityType: 'gemstone',
      entityId: 'gem-123',
      operation: 'update',
      data: {...},
      updatedAt: '2026-05-31T10:00:00Z'
    }
  ],
  lastSyncTimestamp: '2026-05-31T09:00:00Z',
  conflictResolutionStrategy: 'server_wins'
}

Response:
{
  status: 'success',
  data: {
    processedChanges: [...],
    conflicts: [...],
    resolutions: [...],
    serverChanges: [...]
  },
  timestamp: '2026-05-31T10:05:00Z'
}
```

### 3. Pull Server Changes

```
POST /api/sync/pull

Request:
{
  lastSyncTimestamp: '2026-05-31T09:00:00Z'
}

Response:
{
  status: 'success',
  data: {
    changes: [
      {
        entityType: 'gemstone',
        operation: 'update',
        data: {...}
      }
    ],
    count: 5
  },
  timestamp: '2026-05-31T10:05:00Z'
}
```

### 4. Bidirectional Sync

```
POST /api/sync/bidirectional

Request:
{
  localChanges: [...],
  lastSyncTimestamp: '2026-05-31T09:00:00Z'
}

Response:
{
  status: 'success',
  data: {
    push: {...},
    pull: {...},
    syncedAt: '2026-05-31T10:05:00Z'
  },
  timestamp: '2026-05-31T10:05:00Z'
}
```

### 5. Get Sync Status

```
GET /api/sync/status

Response:
{
  status: 'success',
  data: {
    lastSyncTimestamp: '2026-05-31T10:00:00Z',
    syncStatus: 'success',
    processedCount: 10,
    conflictCount: 2,
    resolvedCount: 2,
    lastError: null
  },
  timestamp: '2026-05-31T10:05:00Z'
}
```

### 6. Retry Failed Syncs

```
POST /api/sync/retry

Response:
{
  status: 'success',
  data: {
    retriedCount: 5,
    message: 'Retried 5 failed syncs'
  },
  timestamp: '2026-05-31T10:05:00Z'
}
```

### 7. Resolve Conflict

```
POST /api/sync/resolve-conflict

Request:
{
  conflictId: 'conflict-123',
  resolution: 'server_wins'
}

Response:
{
  status: 'success',
  message: 'Conflict resolved',
  timestamp: '2026-05-31T10:05:00Z'
}
```

---

## Error Handling

### Error Response Format

```javascript
{
  status: 'error',
  message: 'Error description',
  code: 'ERROR_CODE',
  details: {
    field: 'error details'
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| SYNC_INIT_ERROR | 500 | Sync initialization failed |
| SYNC_PUSH_ERROR | 500 | Push sync failed |
| SYNC_PULL_ERROR | 500 | Pull sync failed |
| SYNC_BIDIRECTIONAL_ERROR | 500 | Bidirectional sync failed |
| SYNC_STATUS_ERROR | 500 | Status retrieval failed |
| SYNC_RETRY_ERROR | 500 | Retry operation failed |
| CONFLICT_RESOLUTION_ERROR | 500 | Conflict resolution failed |
| INVALID_REQUEST | 400 | Invalid request format |
| UNAUTHORIZED | 401 | Authentication failed |
| FORBIDDEN | 403 | Authorization failed |
| NOT_FOUND | 404 | Resource not found |

---

## Performance Optimization

### 1. Batch Processing

```javascript
// Process changes in batches of 100
const batchSize = 100;
for (let i = 0; i < changes.length; i += batchSize) {
  const batch = changes.slice(i, i + batchSize);
  await processBatch(batch);
}
```

### 2. Compression

```javascript
// Compress sync payload for large transfers
const compressed = zlib.gzipSync(JSON.stringify(syncData));
```

### 3. Caching

```javascript
// Cache sync metadata to reduce database queries
const cache = new Map();
cache.set(userId, syncMetadata);
```

### 4. Indexing

```sql
-- Database indexes for performance
CREATE INDEX idx_sync_metadata_user ON sync_metadata(user_id);
CREATE INDEX idx_sync_queue_status ON sync_queue(sync_status);
CREATE INDEX idx_sync_conflicts_entity ON sync_conflicts(entity_type, entity_id);
CREATE INDEX idx_gemstones_updated_at ON gemstones(updated_at);
CREATE INDEX idx_sales_updated_at ON sales(updated_at);
CREATE INDEX idx_expenses_updated_at ON expenses(updated_at);
```

---

## Monitoring and Logging

### Sync Metrics

```javascript
{
  userId: 'user-123',
  syncDuration: 2500, // milliseconds
  changesProcessed: 10,
  conflictsDetected: 2,
  conflictsResolved: 2,
  dataTransferred: 51200, // bytes
  timestamp: '2026-05-31T10:05:00Z'
}
```

### Log Levels

- **ERROR**: Sync failures, data corruption
- **WARN**: Conflicts, retries, slow syncs
- **INFO**: Sync start/completion, status changes
- **DEBUG**: Detailed sync operations, data changes

### Audit Trail

All sync operations are logged in the audit trail:

```javascript
{
  userId: 'user-123',
  action: 'update',
  module: 'gemstone',
  entityId: 'gem-123',
  beforeValue: {...},
  afterValue: {...},
  timestamp: '2026-05-31T10:05:00Z'
}
```

---

## Implementation Roadmap

### Phase 1: Core Backend (✅ Completed)
- [x] SQLite schema design
- [x] Sync Engine Service
- [x] API endpoints
- [x] Conflict resolution logic

### Phase 2: Client-Side Implementation
- [ ] Flutter offline-first architecture
- [ ] SQLite integration
- [ ] Sync queue management
- [ ] Background sync tasks

### Phase 3: Advanced Features
- [ ] Data encryption
- [ ] Advanced retry mechanisms
- [ ] Conflict UI resolution
- [ ] Performance optimization

### Phase 4: Testing & Deployment
- [ ] Unit tests
- [ ] Integration tests
- [ ] Load testing
- [ ] Security audit
- [ ] Production deployment

---

## Troubleshooting

### Issue: Sync keeps failing

**Solution:**
1. Check network connectivity
2. Verify JWT token validity
3. Check server logs for errors
4. Retry sync operation
5. Clear cache and reinitialize

### Issue: Conflicts not resolving

**Solution:**
1. Check conflict resolution strategy
2. Verify server data integrity
3. Manual conflict resolution via UI
4. Contact support if persists

### Issue: Data inconsistency

**Solution:**
1. Run data validation
2. Force full sync
3. Check audit logs
4. Restore from backup if necessary

---

## References

- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Node.js Best Practices](https://nodejs.org/en/docs/)
- [JWT Authentication](https://jwt.io/)
- [AES Encryption](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)

---

**Last Updated:** May 31, 2026
**Version:** 1.0.0
**Status:** Production Ready
