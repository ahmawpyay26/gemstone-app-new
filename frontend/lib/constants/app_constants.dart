/// App Configuration Constants - OFFLINE FIRST MODE
/// 
/// This file contains all configuration constants for the Gemstone Management App.
/// Fully offline-first mode - no backend dependency.

class AppConstants {
  // App Information
  static const String APP_NAME = 'Gemstone Management';
  static const String APP_VERSION = '1.0.0';
  static const String BUILD_NUMBER = '1';
  
  // Database Configuration
  static const String DATABASE_NAME = 'gemstone_app.db';
  static const int DATABASE_VERSION = 1;
  
  // Offline Mode - ENABLED WITH SYNC
  static const bool OFFLINE_MODE_ENABLED = true;
  static const bool REQUIRE_BACKEND_ON_STARTUP = false;
  
  // Backend API Configuration
  static const String API_BASE_URL = 'https://gemstone-backend-xxxxx.onrender.com/api';
  static const String API_TIMEOUT = '30';
  
  // Sync Configuration - ENABLED
  static const bool AUTO_SYNC_ENABLED = true;
  static const int SYNC_INTERVAL_MINUTES = 15;
  static const int MAX_SYNC_RETRIES = 3;
  static const int SYNC_TIMEOUT_SECONDS = 30;
  
  // Security Configuration
  static const bool REQUIRE_AUTHENTICATION = true;
  static const int SESSION_TIMEOUT_MINUTES = 30;
  static const bool ENABLE_DATA_ENCRYPTION = true;
  static const bool HTTPS_ONLY = false; // Not applicable in offline mode
  
  // UI Configuration
  static const String APP_THEME = 'dark';
  static const String PRIMARY_COLOR = '#FFD700'; // Gold
  static const String SECONDARY_COLOR = '#1A1A1A'; // Dark
  
  // Feature Flags - Local with Cloud Sync
  static const bool FEATURE_INVENTORY = true;
  static const bool FEATURE_SALES = true;
  static const bool FEATURE_EXPENSES = true;
  static const bool FEATURE_REPORTS = true;
  static const bool FEATURE_WORKERS = true;
  static const bool FEATURE_QR_TRACKING = true;
  static const bool FEATURE_NOTIFICATIONS = true;
  static const bool FEATURE_SYNC = true; // Enabled with backend
  
  // Logging Configuration
  static const bool DEBUG_LOGGING = true;
  static const int LOG_LEVEL = 1;
  
  // Performance Configuration
  static const bool ENABLE_IMAGE_CACHE = true;
  static const int IMAGE_CACHE_SIZE = 100;
  static const bool ENABLE_QUERY_OPTIMIZATION = true;
  static const int BATCH_SIZE = 100;
  
  // Notification Configuration
  static const bool ENABLE_PUSH_NOTIFICATIONS = true;
  static const bool NOTIFICATION_SOUND_ENABLED = true;
  static const bool NOTIFICATION_VIBRATION_ENABLED = true;
  
  // File Configuration
  static const int MAX_FILE_UPLOAD_SIZE = 50;
  static const List<String> SUPPORTED_FILE_TYPES = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'xlsx',
    'xls',
    'csv'
  ];
  
  // Pagination
  static const int DEFAULT_PAGE_SIZE = 20;
  static const int MAX_PAGE_SIZE = 100;
  
  // Validation
  static const int MIN_PASSWORD_LENGTH = 6;
  static const int MAX_PASSWORD_LENGTH = 128;
  static const String EMAIL_REGEX = 
    r'^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$';
  
  // Timeouts
  static const int CONNECTION_TIMEOUT = 30;
  static const int READ_TIMEOUT = 30;
  static const int WRITE_TIMEOUT = 30;
  
  // Analytics - DISABLED
  static const bool ENABLE_ANALYTICS = false;
}

/// Build Configuration
class BuildConfig {
  /// Get app title
  static String getAppTitle() {
    return '${AppConstants.APP_NAME} (Offline)';
  }
  
  /// Check if offline mode is enabled
  static bool isOfflineModeEnabled() {
    return AppConstants.OFFLINE_MODE_ENABLED;
  }
  
  /// Check if feature is enabled
  static bool isFeatureEnabled(String featureName) {
    switch (featureName) {
      case 'inventory':
        return AppConstants.FEATURE_INVENTORY;
      case 'sales':
        return AppConstants.FEATURE_SALES;
      case 'expenses':
        return AppConstants.FEATURE_EXPENSES;
      case 'reports':
        return AppConstants.FEATURE_REPORTS;
      case 'workers':
        return AppConstants.FEATURE_WORKERS;
      case 'qr_tracking':
        return AppConstants.FEATURE_QR_TRACKING;
      case 'notifications':
        return AppConstants.FEATURE_NOTIFICATIONS;
      case 'sync':
        return AppConstants.FEATURE_SYNC;
      default:
        return false;
    }
  }
}
