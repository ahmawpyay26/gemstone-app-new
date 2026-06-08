# Backup and Recovery System - Complete Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Features](#features)
4. [Backup Types](#backup-types)
5. [Recovery Options](#recovery-options)
6. [Database Schema](#database-schema)
7. [Services](#services)
8. [API Endpoints](#api-endpoints)
9. [Backup Schedule](#backup-schedule)
10. [Recovery Workflow](#recovery-workflow)
11. [Security](#security)
12. [Monitoring and Alerts](#monitoring-and-alerts)

---

## Overview

The Backup and Recovery System provides comprehensive data protection for the gemstone management platform with automatic and manual backups, multiple recovery options, encryption, and complete audit logging.

### Key Features

- **Automatic Backups**: Daily, weekly, and monthly scheduled backups
- **Manual Backups**: On-demand backup creation
- **Multiple Recovery Options**: Full restore, point-in-time, selective restore
- **Encryption**: AES-256 encryption for backup files
- **Compression**: Gzip compression to reduce storage
- **Cloud Support**: AWS S3, Azure Blob, Google Cloud Storage
- **Validation**: Checksum verification and file integrity checks
- **Audit Logging**: Complete tracking of all backup and recovery actions
- **Retention Policy**: Automatic cleanup of expired backups

---

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Admin Dashboard                           │
│         (Backup Management, Recovery Requests)              │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                    API Layer                                 │
│         (Backup/Recovery Endpoints, RBAC)                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  Service Layer                               │
│  ┌──────────────┬──────────────┬──────────────────────────┐  │
│  │ Automatic    │ Manual       │ Recovery Service         │  │
│  │ Backup       │ Backup       │ - Full Restore           │  │
│  │ Service      │ Service      │ - Point-in-Time          │  │
│  │ - Scheduling │ - On-demand  │ - Selective Restore      │  │
│  │ - Retention  │ - Download   │ - Validation             │  │
│  └──────────────┴──────────────┴──────────────────────────┘  │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  Storage Layer                               │
│  ┌──────────────┬──────────────┬──────────────────────────┐  │
│  │ Local        │ AWS S3       │ Azure/GCP                │  │
│  │ Storage      │ Storage      │ Storage                  │  │
│  └──────────────┴──────────────┴──────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

### 1. Automatic Backups

**Daily Backup**
- Time: 2:00 AM (configurable)
- Type: Full or Incremental
- Retention: 7 days (configurable)
- Compression: Enabled
- Encryption: Enabled

**Weekly Backup**
- Day: Sunday (configurable)
- Time: 3:00 AM (configurable)
- Type: Full
- Retention: 30 days (configurable)
- Compression: Enabled
- Encryption: Enabled

**Monthly Backup**
- Day: 1st of month (configurable)
- Time: 4:00 AM (configurable)
- Type: Full
- Retention: 90 days (configurable)
- Compression: Enabled
- Encryption: Enabled

### 2. Manual Backups

- On-demand backup creation
- Selective table backup
- Custom retention period
- Immediate download option
- Custom naming and notes

### 3. Recovery Options

**Full Restore**
- Complete database restoration
- All tables and data restored
- Typical recovery time: 5-30 minutes (depends on size)

**Point-in-Time Recovery**
- Restore to specific timestamp
- Uses binary logs for granular recovery
- Requires backup + binary logs
- Typical recovery time: 10-60 minutes

**Selective Restore**
- Restore specific tables only
- Useful for partial data recovery
- Preserves other table data
- Typical recovery time: 1-10 minutes

---

## Backup Types

| Type | Description | Use Case | Frequency |
|------|-------------|----------|-----------|
| **FULL** | Complete database backup | Initial backup, archival | Daily/Weekly/Monthly |
| **INCREMENTAL** | Only changed data since last backup | Frequent backups, saves space | Daily |
| **DIFFERENTIAL** | Changed data since last full backup | Balance between full and incremental | Weekly |
| **SELECTIVE** | Specific tables only | Testing, partial recovery | On-demand |

---

## Recovery Options

| Option | Scope | Time | Use Case |
|--------|-------|------|----------|
| **FULL_RESTORE** | Entire database | 5-30 min | Complete failure, migration |
| **POINT_IN_TIME** | Specific timestamp | 10-60 min | Accidental deletion, data corruption |
| **SELECTIVE_RESTORE** | Specific tables | 1-10 min | Table-level recovery, testing |

---

## Database Schema

### backup_metadata Table

```sql
Columns:
- id (VARCHAR 36, PK) - Unique backup identifier
- backup_name (VARCHAR 255) - Human-readable name
- backup_type (ENUM) - FULL, INCREMENTAL, DIFFERENTIAL, SELECTIVE
- backup_status (ENUM) - PENDING, IN_PROGRESS, COMPLETED, FAILED, VERIFIED
- backup_date (DATETIME) - When backup was created
- start_time, end_time (DATETIME) - Execution timestamps
- duration_seconds (INT) - Backup duration
- storage_location (VARCHAR 500) - File path or cloud URL
- storage_type (ENUM) - LOCAL, AWS_S3, AZURE_BLOB, GOOGLE_CLOUD
- file_size (BIGINT) - Original file size
- compressed_size (BIGINT) - Compressed file size
- rows_backed_up (INT) - Number of rows backed up
- is_encrypted (BOOLEAN) - Encryption status
- checksum (VARCHAR 255) - SHA-256 checksum
- retention_days (INT) - Retention period
- expiration_date (DATE) - When backup expires
- is_archived (BOOLEAN) - Archive status
- created_by (VARCHAR 36, FK) - User who created backup
- notes (TEXT) - Additional notes
```

### backup_schedules Table

```sql
Columns:
- id (VARCHAR 36, PK) - Schedule identifier
- schedule_name (VARCHAR 255) - Schedule name
- backup_type (ENUM) - Backup type
- schedule_type (ENUM) - DAILY, WEEKLY, MONTHLY, CUSTOM
- is_active (BOOLEAN) - Active status
- cron_expression (VARCHAR 100) - Cron schedule
- day_of_week, day_of_month, hour, minute (INT) - Schedule details
- retention_days (INT) - Retention period
- compression_enabled (BOOLEAN) - Compression setting
- encryption_enabled (BOOLEAN) - Encryption setting
- notify_on_success, notify_on_failure (BOOLEAN) - Notification settings
- notification_email (VARCHAR 100) - Email address
```

### recovery_requests Table

```sql
Columns:
- id (VARCHAR 36, PK) - Recovery request ID
- backup_id (VARCHAR 36, FK) - Associated backup
- recovery_type (ENUM) - FULL_RESTORE, POINT_IN_TIME, SELECTIVE_RESTORE
- recovery_status (ENUM) - PENDING, IN_PROGRESS, COMPLETED, FAILED, CANCELLED
- requested_by (VARCHAR 36, FK) - User who requested recovery
- approved_by (VARCHAR 36, FK) - User who approved recovery
- recovery_target_time (DATETIME) - Target time for PIT recovery
- target_tables (JSON) - Tables for selective restore
- is_validated (BOOLEAN) - Validation status
- validation_result (JSON) - Validation details
- reason (TEXT) - Recovery reason
- notes (TEXT) - Additional notes
```

### backup_audit_logs Table

```sql
Columns:
- id (VARCHAR 36, PK) - Audit log ID
- backup_id (VARCHAR 36, FK) - Associated backup
- recovery_id (VARCHAR 36, FK) - Associated recovery
- action (ENUM) - BACKUP_CREATED, BACKUP_DELETED, BACKUP_RESTORED, etc.
- action_timestamp (TIMESTAMP) - When action occurred
- user_id (VARCHAR 36, FK) - User who performed action
- user_role (VARCHAR 50) - User role
- ip_address (VARCHAR 45) - Source IP
- action_details (JSON) - Detailed action information
- notes (TEXT) - Additional notes
```

---

## Services

### AutomaticBackupService

**Methods:**
- `initializeScheduledBackups()` - Initialize all active schedules
- `createSchedule(schedule)` - Create new backup schedule
- `executeScheduledBackup(scheduleId)` - Execute scheduled backup
- `performBackup(...)` - Perform backup operation
- `applyRetentionPolicy(days)` - Clean up expired backups
- `listBackupSchedules(activeOnly)` - List all schedules
- `createBackupSchedule(data)` - Create new schedule
- `updateBackupSchedule(id, data)` - Update schedule
- `deleteBackupSchedule(id)` - Delete schedule

### ManualBackupService

**Methods:**
- `triggerManualBackup(data)` - Trigger on-demand backup
- `triggerSelectiveBackup(data)` - Trigger selective backup
- `getBackupList(limit, offset, filters)` - List backups
- `getBackupDetails(backupId)` - Get backup details
- `deleteBackup(backupId)` - Delete backup
- `downloadBackup(backupId)` - Download backup file
- `getBackupStatistics(startDate, endDate)` - Get statistics

### RecoveryService

**Methods:**
- `requestFullRestore(backupId, data)` - Request full restore
- `requestPointInTimeRestore(backupId, targetTime, data)` - Request PIT restore
- `requestSelectiveRestore(backupId, tables, data)` - Request selective restore
- `validateBackup(backupId)` - Validate backup before restore
- `approveRecoveryRequest(recoveryId, approvedBy)` - Approve recovery
- `rejectRecoveryRequest(recoveryId, rejectedBy, reason)` - Reject recovery
- `getRecoveryHistory(limit, offset)` - Get recovery history

---

## API Endpoints

### Backup Management

```
POST /api/backup/manual
  Request: { backupType, compressionEnabled, encryptionEnabled, notes }
  Response: { backupId, filename, fileSize, status }
  Access: Owner

POST /api/backup/selective
  Request: { tables, compressionEnabled, encryptionEnabled, notes }
  Response: { backupId, filename, fileSize, status }
  Access: Owner

GET /api/backup/list
  Query: { limit, offset, backupType, status, storageType }
  Response: { data: [...], total, limit, offset }
  Access: Owner, Accountant

GET /api/backup/:backupId
  Response: { backup details, execution logs, verifications }
  Access: Owner, Accountant

DELETE /api/backup/:backupId
  Response: { backupId, deleted: true }
  Access: Owner

GET /api/backup/:backupId/download
  Response: File download
  Access: Owner, Accountant
```

### Backup Schedules

```
POST /api/backup/schedule
  Request: { scheduleName, backupType, scheduleType, hour, minute, ... }
  Response: { scheduleId, ...data }
  Access: Owner

GET /api/backup/schedules
  Query: { activeOnly }
  Response: { data: [...] }
  Access: Owner, Accountant

PUT /api/backup/schedule/:scheduleId
  Request: { ...updateData }
  Response: { scheduleId, ...data }
  Access: Owner

DELETE /api/backup/schedule/:scheduleId
  Response: { scheduleId, deleted: true }
  Access: Owner
```

### Recovery Management

```
POST /api/recovery/full-restore
  Request: { backupId, reason, notes }
  Response: { recoveryId, status, estimatedTime }
  Access: Owner

POST /api/recovery/point-in-time
  Request: { backupId, targetTime, reason, notes }
  Response: { recoveryId, status, estimatedTime }
  Access: Owner

POST /api/recovery/selective-restore
  Request: { backupId, tables, reason, notes }
  Response: { recoveryId, status, estimatedTime }
  Access: Owner

GET /api/recovery/history
  Query: { limit, offset }
  Response: { data: [...], total }
  Access: Owner, Accountant

PUT /api/recovery/:recoveryId/approve
  Response: { recoveryId, approved: true }
  Access: Owner

PUT /api/recovery/:recoveryId/reject
  Request: { reason }
  Response: { recoveryId, rejected: true }
  Access: Owner
```

---

## Backup Schedule

### Default Schedule

```
Daily Backup:
  - Time: 2:00 AM
  - Type: Full
  - Retention: 7 days
  - Compression: Enabled
  - Encryption: Enabled

Weekly Backup:
  - Day: Sunday
  - Time: 3:00 AM
  - Type: Full
  - Retention: 30 days
  - Compression: Enabled
  - Encryption: Enabled

Monthly Backup:
  - Day: 1st of month
  - Time: 4:00 AM
  - Type: Full
  - Retention: 90 days
  - Compression: Enabled
  - Encryption: Enabled
```

### Cron Expressions

```
Daily at 2:00 AM:     0 2 * * *
Weekly Sunday 3:00 AM: 0 3 * * 0
Monthly 1st 4:00 AM:  0 4 1 * *
```

---

## Recovery Workflow

### Full Restore Workflow

```
1. Request Full Restore
   └─ User submits recovery request
   
2. Validation
   └─ Verify backup integrity
   └─ Check checksum
   └─ Verify file exists
   
3. Approval (if required)
   └─ Owner approves recovery
   
4. Preparation
   └─ Decrypt backup (if encrypted)
   └─ Decompress backup (if compressed)
   
5. Restore
   └─ Stop application (optional)
   └─ Execute mysql restore command
   └─ Verify data integrity
   
6. Post-Restore
   └─ Restart application
   └─ Verify connectivity
   └─ Log recovery action
```

### Point-in-Time Recovery Workflow

```
1. Request PIT Restore
   └─ User specifies target timestamp
   
2. Validation
   └─ Verify backup exists
   └─ Verify binary logs available
   └─ Verify target time is valid
   
3. Approval
   └─ Owner approves recovery
   
4. Preparation
   └─ Decrypt and decompress backup
   └─ Identify relevant binary logs
   
5. Restore
   └─ Restore from backup
   └─ Apply binary logs up to target time
   
6. Verification
   └─ Verify data at target time
   └─ Check data consistency
   └─ Log recovery action
```

---

## Security

### Encryption

- **Algorithm**: AES-256-CBC
- **Key Derivation**: PBKDF2 with SHA-256
- **IV**: Random 16-byte initialization vector
- **Key Storage**: Environment variable (BACKUP_ENCRYPTION_KEY)

### Access Control

| Action | Owner | Accountant | Worker | Broker |
|--------|-------|-----------|--------|--------|
| Create Backup | ✓ | ✗ | ✗ | ✗ |
| View Backups | ✓ | ✓ | ✗ | ✗ |
| Download Backup | ✓ | ✓ | ✗ | ✗ |
| Delete Backup | ✓ | ✗ | ✗ | ✗ |
| Request Recovery | ✓ | ✗ | ✗ | ✗ |
| Approve Recovery | ✓ | ✗ | ✗ | ✗ |
| Execute Recovery | ✓ | ✗ | ✗ | ✗ |

### Audit Logging

All backup and recovery actions are logged with:
- User ID and role
- Action type
- Timestamp
- IP address
- User agent
- Action details

---

## Monitoring and Alerts

### Backup Monitoring

- **Backup Status**: Track completion, failures, duration
- **Storage Usage**: Monitor backup storage consumption
- **Retention Policy**: Automatic cleanup of expired backups
- **Compression Ratio**: Track compression effectiveness

### Alerts

- Backup failure notifications
- Storage quota warnings
- Recovery request approvals
- Suspicious activity detection

---

## Implementation Checklist

- [ ] Database schema created
- [ ] Automatic backup service initialized
- [ ] Manual backup service deployed
- [ ] Recovery service configured
- [ ] API endpoints implemented
- [ ] RBAC configured
- [ ] Audit logging enabled
- [ ] Email notifications configured
- [ ] Cloud storage integration (optional)
- [ ] Monitoring dashboard created
- [ ] Documentation completed
- [ ] Testing completed

---

## Troubleshooting

### Common Issues

**Issue**: Backup fails with "Database connection error"
- **Solution**: Verify database credentials, check network connectivity

**Issue**: Restore fails with "Backup file corrupted"
- **Solution**: Verify checksum, try different backup, restore from previous backup

**Issue**: Recovery takes too long
- **Solution**: Check database size, optimize queries, increase resources

**Issue**: Encryption/Decryption fails
- **Solution**: Verify encryption key, check file permissions

---

## Performance Considerations

### Backup Performance

- **Database Size**: Backup time scales linearly with database size
- **Compression**: Reduces storage by 70-80% (typical)
- **Encryption**: Minimal performance impact (<5%)
- **Network**: Cloud backups depend on network bandwidth

### Recovery Performance

- **Full Restore**: 1-30 minutes (depends on size)
- **Point-in-Time**: 10-60 minutes (depends on binary log size)
- **Selective Restore**: 1-10 minutes (depends on table size)

### Storage Optimization

- **Compression**: Enabled by default (70-80% reduction)
- **Retention Policy**: Automatic cleanup after retention period
- **Archival**: Old backups can be archived to cold storage
- **Deduplication**: Consider backup deduplication for multiple backups

---

**Last Updated**: May 31, 2026
**Version**: 1.0.0
**Status**: Production Ready
