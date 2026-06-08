/**
 * Logger Configuration
 * Simple logging utility for the Gemstone Management Backend
 */

const fs = require('fs');
const path = require('path');

// Create logs directory if it doesn't exist
const logsDir = path.join(__dirname, '../logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Log file paths
const errorLogPath = path.join(logsDir, 'error.log');
const infoLogPath = path.join(logsDir, 'info.log');

/**
 * Format timestamp for logs
 */
const getTimestamp = () => {
  return new Date().toISOString();
};

/**
 * Write to log file
 */
const writeToFile = (filePath, message) => {
  try {
    fs.appendFileSync(filePath, `${message}\n`, 'utf8');
  } catch (error) {
    console.error(`Failed to write to log file: ${filePath}`, error);
  }
};

/**
 * Logger object with methods for different log levels
 */
const logger = {
  /**
   * Log info level messages
   */
  info: (message) => {
    const logMessage = `[${getTimestamp()}] [INFO] ${message}`;
    console.log(logMessage);
    writeToFile(infoLogPath, logMessage);
  },

  /**
   * Log warning level messages
   */
  warn: (message) => {
    const logMessage = `[${getTimestamp()}] [WARN] ${message}`;
    console.warn(logMessage);
    writeToFile(infoLogPath, logMessage);
  },

  /**
   * Log error level messages
   */
  error: (message, error = null) => {
    let logMessage = `[${getTimestamp()}] [ERROR] ${message}`;
    if (error) {
      logMessage += `\n${error.stack || error.toString()}`;
    }
    console.error(logMessage);
    writeToFile(errorLogPath, logMessage);
  },

  /**
   * Log debug level messages (only in development)
   */
  debug: (message) => {
    if (process.env.NODE_ENV !== 'production') {
      const logMessage = `[${getTimestamp()}] [DEBUG] ${message}`;
      console.debug(logMessage);
      writeToFile(infoLogPath, logMessage);
    }
  },

  /**
   * Log success messages
   */
  success: (message) => {
    const logMessage = `[${getTimestamp()}] [SUCCESS] ${message}`;
    console.log(logMessage);
    writeToFile(infoLogPath, logMessage);
  },
};

module.exports = logger;
