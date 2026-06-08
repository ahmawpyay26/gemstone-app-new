const nodemailer = require('nodemailer');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');
const NotificationService = require('./notificationService');

class EmailNotificationService {
  constructor() {
    this.transporter = this.initializeTransporter();
    this.emailQueue = [];
    this.isProcessing = false;
    this.startQueueProcessor();
  }

  /**
   * Initialize email transporter
   */
  initializeTransporter() {
    const emailConfig = {
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: process.env.SMTP_PORT || 587,
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASSWORD
      }
    };

    return nodemailer.createTransport(emailConfig);
  }

  /**
   * Start email queue processor
   */
  startQueueProcessor() {
    // Process email queue every 10 seconds
    setInterval(() => {
      this.processEmailQueue();
    }, 10000);

    // Listen for email queue events
    NotificationService.on('email:queue', (data) => {
      this.addToQueue(data);
    });
  }

  /**
   * Add email to queue
   */
  addToQueue(emailData) {
    this.emailQueue.push(emailData);
  }

  /**
   * Process email queue
   */
  async processEmailQueue() {
    if (this.isProcessing || this.emailQueue.length === 0) {
      return;
    }

    this.isProcessing = true;

    try {
      while (this.emailQueue.length > 0) {
        const emailData = this.emailQueue.shift();
        await this.sendEmail(emailData);
      }
    } catch (error) {
      console.error('Error processing email queue:', error);
    } finally {
      this.isProcessing = false;
    }
  }

  /**
   * Send email notification
   */
  async sendEmail(emailData) {
    const { notificationId, recipientId, email } = emailData;

    try {
      // Get notification details
      const notificationQuery = `
        SELECT n.*, nt.type_key, nt.display_name
        FROM notifications n
        JOIN notification_types nt ON n.notification_type_id = nt.id
        WHERE n.id = ?
      `;

      const [notifications] = await db.execute(notificationQuery, [notificationId]);

      if (notifications.length === 0) {
        throw new Error('Notification not found');
      }

      const notification = notifications[0];

      // Get email template
      const template = await this.getEmailTemplate(notification.type_key);

      // Prepare email content
      const emailContent = this.prepareEmailContent(notification, template);

      // Send email
      const mailOptions = {
        from: process.env.SMTP_FROM || 'noreply@gemstone.com',
        to: email,
        subject: emailContent.subject,
        html: emailContent.html
      };

      const result = await this.transporter.sendMail(mailOptions);

      // Update delivery log
      await this.updateDeliveryLog(notificationId, 'DELIVERED', result.messageId);

      console.log(`Email sent successfully for notification ${notificationId}`);
    } catch (error) {
      console.error(`Failed to send email for notification ${notificationId}:`, error);

      // Update delivery log with failure
      await this.updateDeliveryLog(notificationId, 'FAILED', error.message);

      // Retry logic
      await this.retryEmail(notificationId, emailData);
    }
  }

  /**
   * Get email template
   */
  async getEmailTemplate(typeKey) {
    try {
      const query = `
        SELECT * FROM notification_templates
        WHERE notification_type_id = (
          SELECT id FROM notification_types WHERE type_key = ?
        ) AND language = 'mm' AND is_active = TRUE
        LIMIT 1
      `;

      const [templates] = await db.execute(query, [typeKey]);

      if (templates.length === 0) {
        // Return default template
        return this.getDefaultTemplate(typeKey);
      }

      return templates[0];
    } catch (error) {
      console.error('Failed to get email template:', error);
      return this.getDefaultTemplate(typeKey);
    }
  }

  /**
   * Get default template
   */
  getDefaultTemplate(typeKey) {
    const templates = {
      SALE_COMPLETED: {
        subject_template: 'ရောင်းချမှု အောင်မြင်ခြင်း',
        message_template: 'ရောင်းချမှု အောင်မြင်စွာ ပြီးစီးပါပြီ။',
        html_template: '<p>ရောင်းချမှု အောင်မြင်စွာ ပြီးစီးပါပြီ။</p>'
      },
      HIGH_VALUE_SALE: {
        subject_template: 'မြင့်မားသောတန်ဖိုးရှိသော ရောင်းချမှု သတိပေးချက်',
        message_template: 'မြင့်မားသောတန်ဖိုးရှိသော ရောင်းချမှု အောင်မြင်ခြင်း',
        html_template: '<p>မြင့်မားသောတန်ဖိုးရှိသော ရောင်းချမှု အောင်မြင်ခြင်း</p>'
      },
      LOW_STOCK_ALERT: {
        subject_template: 'စာအုပ်စာရင်း နည်းပါးသောအသိပေးချက်',
        message_template: 'စာအုပ်စာရင်း မျက်ရတနာ နည်းပါးနေပါသည်။',
        html_template: '<p>စာအုပ်စာရင်း မျက်ရတနာ နည်းပါးနေပါသည်။</p>'
      },
      BACKUP_COMPLETED: {
        subject_template: 'အရန်သိမ်းဆည်းမှု အောင်မြင်ခြင်း',
        message_template: 'ဒေတာဘေ့စ် အရန်သိမ်းဆည်းမှု အောင်မြင်စွာ ပြီးစီးပါပြီ။',
        html_template: '<p>ဒေတာဘေ့စ် အရန်သိမ်းဆည်းမှု အောင်မြင်စွာ ပြီးစီးပါပြီ။</p>'
      },
      BACKUP_FAILED: {
        subject_template: 'အရန်သိမ်းဆည်းမှု ပരាജယ်ခြင်း',
        message_template: 'ဒေတာဘေ့စ် အရန်သိမ်းဆည်းမှု ပരាជယ်ခြင်း။',
        html_template: '<p>ဒေတာဘေ့စ် အရန်သိမ်းဆည်းမှု ပരាជယ်ခြင်း။</p>'
      }
    };

    return templates[typeKey] || {
      subject_template: 'အသိပေးချက်',
      message_template: 'အသိပေးချက်',
      html_template: '<p>အသိပေးချက်</p>'
    };
  }

  /**
   * Prepare email content
   */
  prepareEmailContent(notification, template) {
    const data = JSON.parse(notification.data || '{}');

    // Replace variables in template
    let subject = template.subject_template || notification.title;
    let html = template.html_template || `<p>${notification.message}</p>`;

    // Replace placeholders
    Object.keys(data).forEach(key => {
      const regex = new RegExp(`{{${key}}}`, 'g');
      subject = subject.replace(regex, data[key]);
      html = html.replace(regex, data[key]);
    });

    // Add footer
    html += `
      <hr>
      <p style="font-size: 12px; color: #999;">
        ကျောက်မျက်ရတနာ စီမံခန့်ခွဲမှု စနစ်
      </p>
    `;

    return {
      subject,
      html
    };
  }

  /**
   * Update delivery log
   */
  async updateDeliveryLog(notificationId, status, details) {
    try {
      const query = `
        UPDATE notification_delivery_logs
        SET delivery_status = ?, delivered_at = NOW()
        WHERE notification_id = ? AND delivery_channel = 'EMAIL'
      `;

      await db.execute(query, [status, notificationId]);
    } catch (error) {
      console.error('Failed to update delivery log:', error);
    }
  }

  /**
   * Retry email
   */
  async retryEmail(notificationId, emailData) {
    try {
      const query = `
        SELECT retry_count, max_retries FROM notification_delivery_logs
        WHERE notification_id = ? AND delivery_channel = 'EMAIL'
      `;

      const [logs] = await db.execute(query, [notificationId]);

      if (logs.length === 0) {
        return;
      }

      const log = logs[0];

      if (log.retry_count < log.max_retries) {
        // Schedule retry
        const retryDelay = Math.pow(2, log.retry_count) * 60000; // Exponential backoff
        setTimeout(() => {
          this.addToQueue(emailData);
        }, retryDelay);

        // Update retry count
        const updateQuery = `
          UPDATE notification_delivery_logs
          SET retry_count = retry_count + 1
          WHERE notification_id = ? AND delivery_channel = 'EMAIL'
        `;

        await db.execute(updateQuery, [notificationId]);
      }
    } catch (error) {
      console.error('Failed to retry email:', error);
    }
  }

  /**
   * Send bulk emails
   */
  async sendBulkEmails(recipients, subject, htmlContent) {
    try {
      const results = [];

      for (const recipient of recipients) {
        try {
          const mailOptions = {
            from: process.env.SMTP_FROM || 'noreply@gemstone.com',
            to: recipient.email,
            subject: subject,
            html: htmlContent
          };

          const result = await this.transporter.sendMail(mailOptions);
          results.push({ email: recipient.email, status: 'SENT', messageId: result.messageId });
        } catch (error) {
          results.push({ email: recipient.email, status: 'FAILED', error: error.message });
        }
      }

      return results;
    } catch (error) {
      throw new Error(`Failed to send bulk emails: ${error.message}`);
    }
  }

  /**
   * Test email configuration
   */
  async testEmailConfiguration(testEmail) {
    try {
      const mailOptions = {
        from: process.env.SMTP_FROM || 'noreply@gemstone.com',
        to: testEmail,
        subject: 'ကျောက်မျက်ရတနာ - အီမေးလ် စမ်းသပ်ခြင်း',
        html: '<p>အီမေးလ် စမ်းသပ်မှု အောင်မြင်ခြင်း</p>'
      };

      const result = await this.transporter.sendMail(mailOptions);
      return { success: true, messageId: result.messageId };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Get email queue status
   */
  getQueueStatus() {
    return {
      queueLength: this.emailQueue.length,
      isProcessing: this.isProcessing,
      totalProcessed: 0
    };
  }
}

module.exports = new EmailNotificationService();
