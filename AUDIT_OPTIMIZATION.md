# Audit Log System - Performance Optimization & Indexing

## Database Indexing Strategy

### Primary Indexes

```sql
-- User ID index (for filtering by user)
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);

-- Module name index (for filtering by module)
CREATE INDEX idx_audit_logs_module_name ON audit_logs(module_name);

-- Action type index (for filtering by action)
CREATE INDEX idx_audit_logs_action_type ON audit_logs(action_type);

-- Created at index (for date range queries)
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- Entity ID index (for entity history queries)
CREATE INDEX idx_audit_logs_entity_id ON audit_logs(entity_id);

-- Status index (for filtering by success/failure)
CREATE INDEX idx_audit_logs_status ON audit_logs(status);
```

### Composite Indexes (for common query patterns)

```sql
-- For filtering by user and date range
CREATE INDEX idx_audit_logs_user_date ON audit_logs(user_id, created_at DESC);

-- For filtering by module and action type
CREATE INDEX idx_audit_logs_module_action ON audit_logs(module_name, action_type);

-- For filtering by entity and module
CREATE INDEX idx_audit_logs_entity_module ON audit_logs(entity_id, module_name);

-- For complex queries (user, module, date)
CREATE INDEX idx_audit_logs_user_module_date ON audit_logs(user_id, module_name, created_at DESC);
```

### Partitioning Strategy (for large datasets)

```sql
-- Partition by month for better performance
ALTER TABLE audit_logs PARTITION BY RANGE (YEAR(created_at) * 100 + MONTH(created_at)) (
  PARTITION p202501 VALUES LESS THAN (202502),
  PARTITION p202502 VALUES LESS THAN (202503),
  PARTITION p202503 VALUES LESS THAN (202504),
  -- ... continue for each month
  PARTITION p_future VALUES LESS THAN MAXVALUE
);
```

## Query Optimization

### Efficient Filtering Queries

```javascript
// Good: Uses indexes effectively
const logs = await AuditLog.find({
  user_id: userId,
  created_at: { $gte: startDate, $lte: endDate },
  module_name: moduleName
})
  .sort({ created_at: -1 })
  .limit(50)
  .lean(); // Use lean() for read-only queries

// Bad: Full table scan
const logs = await AuditLog.find({
  description: { $regex: 'pattern' } // Avoid regex on large datasets
});
```

### Pagination Best Practices

```javascript
// Use cursor-based pagination for large datasets
const getAuditLogs = async (lastId, limit = 50) => {
  const query = lastId 
    ? { _id: { $lt: lastId } }
    : {};
  
  return await AuditLog.find(query)
    .sort({ _id: -1 })
    .limit(limit)
    .lean();
};

// Avoid offset-based pagination for large datasets
// Bad: SELECT * FROM audit_logs OFFSET 1000000 LIMIT 50
```

## Caching Strategy

### Redis Caching for Frequently Accessed Data

```javascript
const redis = require('redis');
const client = redis.createClient();

// Cache system statistics
const getCachedStats = async (days = 30) => {
  const cacheKey = `audit:stats:${days}`;
  
  // Try to get from cache
  const cached = await client.get(cacheKey);
  if (cached) return JSON.parse(cached);
  
  // If not in cache, calculate and store
  const stats = await calculateStats(days);
  await client.setex(cacheKey, 3600, JSON.stringify(stats)); // 1 hour TTL
  
  return stats;
};

// Cache user activity summary
const getCachedUserActivity = async (userId, days = 30) => {
  const cacheKey = `audit:user:${userId}:${days}`;
  
  const cached = await client.get(cacheKey);
  if (cached) return JSON.parse(cached);
  
  const activity = await getUserActivity(userId, days);
  await client.setex(cacheKey, 1800, JSON.stringify(activity)); // 30 min TTL
  
  return activity;
};

// Invalidate cache on new audit log
const logAudit = async (auditData) => {
  const log = await AuditLog.create(auditData);
  
  // Invalidate relevant caches
  await client.del(`audit:stats:*`);
  await client.del(`audit:user:${auditData.user_id}:*`);
  
  return log;
};
```

## Data Retention Policy

### Archive Old Logs

```javascript
// Archive logs older than 1 year
const archiveOldLogs = async () => {
  const oneYearAgo = new Date();
  oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
  
  // Move to archive table
  const oldLogs = await AuditLog.find({
    created_at: { $lt: oneYearAgo }
  });
  
  if (oldLogs.length > 0) {
    await AuditLogArchive.insertMany(oldLogs);
    await AuditLog.deleteMany({
      created_at: { $lt: oneYearAgo }
    });
  }
};

// Schedule this to run monthly
const schedule = require('node-schedule');
schedule.scheduleJob('0 0 1 * *', archiveOldLogs); // Run on 1st of each month
```

## Batch Operations

### Bulk Insert Audit Logs

```javascript
// Instead of inserting one by one
const logAuditBatch = async (auditDataArray) => {
  try {
    // Batch insert (more efficient)
    await AuditLog.insertMany(auditDataArray, { ordered: false });
  } catch (error) {
    console.error('Batch insert error:', error);
    // Handle partial failures
  }
};

// Use in middleware
const auditQueue = [];
const BATCH_SIZE = 100;

const queueAudit = (auditData) => {
  auditQueue.push(auditData);
  
  if (auditQueue.length >= BATCH_SIZE) {
    logAuditBatch(auditQueue);
    auditQueue.length = 0;
  }
};

// Flush remaining items periodically
setInterval(() => {
  if (auditQueue.length > 0) {
    logAuditBatch(auditQueue);
    auditQueue.length = 0;
  }
}, 5000); // Flush every 5 seconds
```

## Monitoring and Maintenance

### Monitor Query Performance

```javascript
// Enable query profiling
db.setProfilingLevel(1); // Log slow queries (> 100ms)

// Find slow queries
db.system.profile.find({
  millis: { $gt: 100 }
}).sort({ ts: -1 }).limit(10);
```

### Regular Maintenance

```javascript
// Rebuild indexes periodically
const rebuildIndexes = async () => {
  await AuditLog.collection.reIndex();
};

// Analyze table statistics
const analyzeTable = async () => {
  await AuditLog.collection.stats();
};

// Schedule maintenance
schedule.scheduleJob('0 2 * * 0', rebuildIndexes); // Weekly on Sunday at 2 AM
schedule.scheduleJob('0 3 * * 0', analyzeTable); // Weekly on Sunday at 3 AM
```

## Performance Metrics

### Expected Performance

- **Single log retrieval**: < 10ms
- **List with pagination**: < 100ms (with proper indexing)
- **Complex filtering**: < 500ms (with composite indexes)
- **Statistics calculation**: < 1000ms (with caching)
- **Export to CSV**: < 5000ms (for 10,000 records)

### Monitoring Queries

```javascript
// Monitor audit log table size
db.audit_logs.stats();

// Check index usage
db.audit_logs.aggregate([
  { $indexStats: {} }
]);

// Monitor slow queries
db.system.profile.find({
  millis: { $gt: 100 },
  "command.collection": "audit_logs"
}).sort({ ts: -1 });
```

## Recommendations

1. **Use Composite Indexes**: Create indexes on frequently filtered column combinations
2. **Implement Caching**: Cache statistics and frequently accessed data in Redis
3. **Archive Old Data**: Move logs older than 1 year to archive table
4. **Batch Operations**: Use batch inserts for better performance
5. **Monitor Performance**: Set up alerts for slow queries
6. **Regular Maintenance**: Rebuild indexes and analyze table statistics weekly
7. **Pagination**: Use cursor-based pagination instead of offset-based
8. **Lean Queries**: Use `.lean()` for read-only queries to reduce memory usage

## Estimated Storage

- **Per log entry**: ~500 bytes (with before/after values)
- **1 million logs**: ~500 MB
- **1 year of logs** (10,000 logs/day): ~1.8 GB
- **Recommended retention**: 1-2 years with archiving
