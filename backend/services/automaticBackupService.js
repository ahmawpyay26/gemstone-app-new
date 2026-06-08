const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const mysqldump = require('mysqldump');
const fs = require('fs');
const path = require('path');
const cron = require('node-cron');
const zlib = require('zlib');
const crypto = require('crypto');

class AutomaticBackupService {
  constructor() {
    this.backupDir = path.join(__dirname, '../backups');
    this.ensureBackupDir();
    this.schedules = new Map();
  }

  ensureBackupDir() {
    if (!fs.existsSync(this.backupDir)) {
      fs.mkdirSync(this.backupDir, { recursive: true });
    }
  }

  /**
   * Initialize scheduled backups
   */
  async initializeScheduledBackups() {
    try {
      const query = `SELECT * FROM backup_schedules WHERE is_active = TRUE`;
      const [schedules] = await db.execute(query, []);

      for (const schedule of schedules) {
        await this.createSchedule(schedule);
      }

      console.log(`✓ Initialized ${schedules.length} backup schedules`);
    } catch (error) {
      console.error('Failed to initialize scheduled backups:', error);
    }
  }

  /**
   * Create a backup schedule
   */
  async createSchedule(schedule) {
    try {
      const cronExpression = this.generateCronExpression(schedule);
      
      const task = cron.schedule(cronExpression, async () => {
        await this.executeScheduledBackup(schedule.id);
      });

      this.schedules.set(schedule.id, task);
      console.log(`✓ Scheduled backup: ${schedule.schedule_name}`);
    } catch (error) {
      console.error(`Failed to create schedule: ${error.message}`);
    }
  }

  /**
   * Generate cron expression from schedule
   */
  generateCronExpression(schedule) {
    switch (schedule.schedule_type) {
      case 'DAILY':
        return `${schedule.minute} ${schedule.hour} * * *`;
      
      case 'WEEKLY':
        return `${schedule.minute} ${schedule.hour} * * ${schedule.day_of_week}`;
      
      case 'MONTHLY':
        return `${schedule.minute} ${schedule.hour} ${schedule.day_of_month} * *`;
      
      case 'CUSTOM':
        return schedule.cron_expression;
      
      default:
        return `0 2 * * *`; // Default: 2 AM daily
    }
  }

  /**
   * Execute scheduled backup
   */
  async executeScheduledBackup(scheduleId) {
    const backupId = uuidv4();
    
    try {
      // Get schedule details
      const query = `SELECT * FROM backup_schedules WHERE id = ?`;
      const [schedules] = await db.execute(query, [scheduleId]);
      
      if (schedules.length === 0) {
        throw new Error('Schedule not found');
      }

      const schedule = schedules[0];

      // Log execution start
      await this.logExecutionStart(backupId, scheduleId);

      // Perform backup
      const backupResult = await this.performBackup(
        backupId,
        schedule.backup_type,
        schedule.compression_enabled,
        schedule.encryption_enabled,
        schedule.storage_type
      );

      // Update backup metadata
      await this.updateBackupMetadata(backupId, backupResult, schedule);

      // Log execution completion
      await this.logExecutionCompletion(backupId, 'COMPLETED', backupResult);

      // Send notification if enabled
      if (schedule.notify_on_success) {
        await this.sendNotification(schedule, 'SUCCESS', backupResult);
      }

      // Apply retention policy
      await this.applyRetentionPolicy(schedule.retention_days);

      console.log(`✓ Backup completed: ${backupId}`);
      return backupResult;
    } catch (error) {
      console.error(`✗ Backup failed: ${error.message}`);
      
      // Log failure
      await this.logExecutionCompletion(backupId, 'FAILED', { error: error.message });

      // Send failure notification
      const scheduleQuery = `SELECT * FROM backup_schedules WHERE id = ?`;
      const [schedules] = await db.execute(scheduleQuery, [scheduleId]);
      
      if (schedules.length > 0 && schedules[0].notify_on_failure) {
        await this.sendNotification(schedules[0], 'FAILURE', { error: error.message });
      }

      throw error;
    }
  }

  /**
   * Perform backup operation
   */
  async performBackup(backupId, backupType, compressionEnabled, encryptionEnabled, storageType) {
    try {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const backupFilename = `backup-${backupId}-${timestamp}.sql`;
      const backupPath = path.join(this.backupDir, backupFilename);

      // Get database configuration
      const dbConfig = {
        host: process.env.DB_HOST || 'localhost',
        user: process.env.DB_USER || 'root',
        password: process.env.DB_PASSWORD || '',
        database: process.env.DB_NAME || 'gemstone_db'
      };

      // Perform mysqldump
      const startTime = Date.now();
      
      await mysqldump({
        connection: dbConfig,
        dumpToFile: backupPath,
        compressFile: compressionEnabled
      });

      const endTime = Date.now();
      const durationSeconds = Math.floor((endTime - startTime) / 1000);

      // Get file stats
      const stats = fs.statSync(backupPath);
      let finalPath = backupPath;
      let compressedSize = stats.size;

      // Compress if enabled and not already compressed
      if (compressionEnabled && !backupPath.endsWith('.gz')) {
        const compressedPath = `${backupPath}.gz`;
        await this.compressFile(backupPath, compressedPath);
        fs.unlinkSync(backupPath);
        finalPath = compressedPath;
        compressedSize = fs.statSync(compressedPath).size;
      }

      // Encrypt if enabled
      if (encryptionEnabled) {
        const encryptedPath = `${finalPath}.enc`;
        await this.encryptFile(finalPath, encryptedPath);
        fs.unlinkSync(finalPath);
        finalPath = encryptedPath;
      }

      // Calculate checksum
      const checksum = await this.calculateChecksum(finalPath);

      // Get row count
      const rowCountQuery = `SELECT SUM(TABLE_ROWS) as total_rows FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ?`;
      const [rowCountResult] = await db.execute(rowCountQuery, [dbConfig.database]);
      const totalRows = rowCountResult[0].total_rows || 0;

      return {
        backupId,
        filename: path.basename(finalPath),
        filepath: finalPath,
        fileSize: stats.size,
        compressedSize,
        durationSeconds,
        checksum,
        totalRows,
        backupType,
        storageType
      };
    } catch (error) {
      throw new Error(`Backup operation failed: ${error.message}`);
    }
  }

  /**
   * Compress file using gzip
   */
  async compressFile(inputPath, outputPath) {
    return new Promise((resolve, reject) => {
      const input = fs.createReadStream(inputPath);
      const output = fs.createWriteStream(outputPath);
      const gzip = zlib.createGzip();

      input
        .pipe(gzip)
        .pipe(output)
        .on('finish', resolve)
        .on('error', reject);
    });
  }

  /**
   * Encrypt file using AES-256
   */
  async encryptFile(inputPath, outputPath) {
    try {
      const encryptionKey = process.env.BACKUP_ENCRYPTION_KEY || 'default-key-32-chars-long-string';
      const algorithm = 'aes-256-cbc';
      const key = crypto.scryptSync(encryptionKey, 'salt', 32);
      const iv = crypto.randomBytes(16);

      const input = fs.createReadStream(inputPath);
      const output = fs.createWriteStream(outputPath);
      const cipher = crypto.createCipheriv(algorithm, key, iv);

      // Write IV to file first
      output.write(iv);

      input
        .pipe(cipher)
        .pipe(output)
        .on('finish', () => {})
        .on('error', (error) => {
          throw error;
        });

      return new Promise((resolve, reject) => {
        output.on('finish', resolve);
        output.on('error', reject);
      });
    } catch (error) {
      throw new Error(`File encryption failed: ${error.message}`);
    }
  }

  /**
   * Calculate file checksum
   */
  async calculateChecksum(filepath) {
    return new Promise((resolve, reject) => {
      const hash = crypto.createHash('sha256');
      const stream = fs.createReadStream(filepath);

      stream.on('data', (data) => hash.update(data));
      stream.on('end', () => resolve(hash.digest('hex')));
      stream.on('error', reject);
    });
  }

  /**
   * Update backup metadata
   */
  async updateBackupMetadata(backupId, backupResult, schedule) {
    try {
      const query = `
        INSERT INTO backup_metadata (
          id, backup_name, backup_type, backup_status, backup_date,
          start_time, end_time, duration_seconds, storage_location,
          storage_type, file_size, compressed_size, rows_backed_up,
          is_encrypted, checksum, retention_days, expiration_date,
          created_by, notes
        ) VALUES (?, ?, ?, ?, NOW(), NOW(), NOW(), ?, ?, ?, ?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY), ?, ?)
      `;

      await db.execute(query, [
        backupId,
        `Scheduled backup - ${schedule.schedule_name}`,
        backupResult.backupType,
        'COMPLETED',
        backupResult.durationSeconds,
        backupResult.filepath,
        backupResult.storageType,
        backupResult.fileSize,
        backupResult.compressedSize,
        backupResult.totalRows,
        true, // is_encrypted
        backupResult.checksum,
        schedule.retention_days,
        schedule.id,
        `Auto-generated backup from schedule: ${schedule.schedule_name}`
      ]);
    } catch (error) {
      throw new Error(`Failed to update backup metadata: ${error.message}`);
    }
  }

  /**
   * Log execution start
   */
  async logExecutionStart(backupId, scheduleId) {
    try {
      const query = `
        INSERT INTO backup_execution_logs (
          id, backup_id, schedule_id, execution_status, start_time, executed_by
        ) VALUES (?, ?, ?, 'STARTED', NOW(), ?)
      `;

      await db.execute(query, [uuidv4(), backupId, scheduleId, 'SYSTEM']);
    } catch (error) {
      console.error('Failed to log execution start:', error);
    }
  }

  /**
   * Log execution completion
   */
  async logExecutionCompletion(backupId, status, result) {
    try {
      const query = `
        UPDATE backup_execution_logs
        SET execution_status = ?, end_time = NOW(), execution_log = ?
        WHERE backup_id = ? AND execution_status = 'STARTED'
      `;

      await db.execute(query, [
        status,
        JSON.stringify(result),
        backupId
      ]);
    } catch (error) {
      console.error('Failed to log execution completion:', error);
    }
  }

  /**
   * Send notification
   */
  async sendNotification(schedule, status, result) {
    try {
      const email = schedule.notification_email;
      if (!email) return;

      const subject = `Backup ${status}: ${schedule.schedule_name}`;
      const message = status === 'SUCCESS'
        ? `Backup completed successfully. Size: ${(result.fileSize / 1024 / 1024).toFixed(2)}MB`
        : `Backup failed: ${result.error}`;

      // TODO: Implement email sending
      console.log(`Notification: ${subject} - ${message}`);
    } catch (error) {
      console.error('Failed to send notification:', error);
    }
  }

  /**
   * Apply retention policy
   */
  async applyRetentionPolicy(retentionDays) {
    try {
      const query = `
        SELECT id, storage_location FROM backup_metadata
        WHERE expiration_date < NOW() AND is_archived = FALSE
      `;

      const [expiredBackups] = await db.execute(query, []);

      for (const backup of expiredBackups) {
        // Delete backup file
        if (fs.existsSync(backup.storage_location)) {
          fs.unlinkSync(backup.storage_location);
        }

        // Mark as archived
        const updateQuery = `UPDATE backup_metadata SET is_archived = TRUE WHERE id = ?`;
        await db.execute(updateQuery, [backup.id]);
      }

      console.log(`✓ Retention policy applied: ${expiredBackups.length} backups archived`);
    } catch (error) {
      console.error('Failed to apply retention policy:', error);
    }
  }

  /**
   * Get backup schedule
   */
  async getBackupSchedule(scheduleId) {
    try {
      const query = `SELECT * FROM backup_schedules WHERE id = ?`;
      const [schedules] = await db.execute(query, [scheduleId]);
      return schedules[0] || null;
    } catch (error) {
      throw new Error(`Failed to get backup schedule: ${error.message}`);
    }
  }

  /**
   * List all backup schedules
   */
  async listBackupSchedules(activeOnly = true) {
    try {
      let query = `SELECT * FROM backup_schedules`;
      const params = [];

      if (activeOnly) {
        query += ` WHERE is_active = TRUE`;
      }

      query += ` ORDER BY created_at DESC`;

      const [schedules] = await db.execute(query, params);
      return schedules;
    } catch (error) {
      throw new Error(`Failed to list backup schedules: ${error.message}`);
    }
  }

  /**
   * Create backup schedule
   */
  async createBackupSchedule(scheduleData) {
    try {
      const scheduleId = uuidv4();

      const query = `
        INSERT INTO backup_schedules (
          id, schedule_name, backup_type, schedule_type, is_active,
          cron_expression, day_of_week, day_of_month, hour, minute,
          retention_days, compression_enabled, encryption_enabled,
          storage_type, notify_on_success, notify_on_failure,
          notification_email, created_by
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;

      await db.execute(query, [
        scheduleId,
        scheduleData.scheduleName,
        scheduleData.backupType,
        scheduleData.scheduleType,
        scheduleData.isActive !== false,
        scheduleData.cronExpression,
        scheduleData.dayOfWeek,
        scheduleData.dayOfMonth,
        scheduleData.hour,
        scheduleData.minute,
        scheduleData.retentionDays || 30,
        scheduleData.compressionEnabled !== false,
        scheduleData.encryptionEnabled !== false,
        scheduleData.storageType || 'LOCAL',
        scheduleData.notifyOnSuccess !== false,
        scheduleData.notifyOnFailure !== false,
        scheduleData.notificationEmail,
        scheduleData.createdBy
      ]);

      // Create cron schedule
      const schedule = await this.getBackupSchedule(scheduleId);
      await this.createSchedule(schedule);

      return { scheduleId, ...scheduleData };
    } catch (error) {
      throw new Error(`Failed to create backup schedule: ${error.message}`);
    }
  }

  /**
   * Update backup schedule
   */
  async updateBackupSchedule(scheduleId, updateData) {
    try {
      // Stop existing schedule
      if (this.schedules.has(scheduleId)) {
        this.schedules.get(scheduleId).stop();
        this.schedules.delete(scheduleId);
      }

      // Update database
      const fields = [];
      const values = [];

      Object.entries(updateData).forEach(([key, value]) => {
        fields.push(`${key} = ?`);
        values.push(value);
      });

      values.push(scheduleId);

      const query = `UPDATE backup_schedules SET ${fields.join(', ')} WHERE id = ?`;
      await db.execute(query, values);

      // Recreate schedule if active
      if (updateData.isActive !== false) {
        const schedule = await this.getBackupSchedule(scheduleId);
        await this.createSchedule(schedule);
      }

      return { scheduleId, ...updateData };
    } catch (error) {
      throw new Error(`Failed to update backup schedule: ${error.message}`);
    }
  }

  /**
   * Delete backup schedule
   */
  async deleteBackupSchedule(scheduleId) {
    try {
      // Stop schedule
      if (this.schedules.has(scheduleId)) {
        this.schedules.get(scheduleId).stop();
        this.schedules.delete(scheduleId);
      }

      // Delete from database
      const query = `DELETE FROM backup_schedules WHERE id = ?`;
      await db.execute(query, [scheduleId]);

      return { scheduleId, deleted: true };
    } catch (error) {
      throw new Error(`Failed to delete backup schedule: ${error.message}`);
    }
  }
}

module.exports = new AutomaticBackupService();
