import '../models/license_identity.dart';
import '../data/license_storage.dart';

/// Service for managing installation identity with real local persistence.
///
/// Responsibilities:
/// - Generate Installation ID if one does not already exist
/// - Never regenerate automatically
/// - Read existing Installation ID
/// - Read first installation date
/// - Update last opened time
/// - Read current app version
///
/// This implementation uses Hive for persistent local storage.
/// Installation ID is stored once and never changed.
/// Last opened time and version are updated on every launch.
class InstallationIdentityService {
  /// Current app version (read from package_info).
  static String? _cachedAppVersion;

  /// Current build number (read from package_info).
  static int? _cachedBuildNumber;

  /// Private constructor to prevent instantiation.
  InstallationIdentityService._();

  /// Initialize the service.
  /// Must be called once during app startup after Hive is initialized.
  static Future<void> init() async {
    try {
      await LicenseStorage.init();
      // Use static defaults (read from pubspec.yaml)
      _cachedAppVersion = '1.2.1';
      _cachedBuildNumber = 74;
    } catch (e) {
      // Fallback to defaults
      _cachedAppVersion = '1.2.1';
      _cachedBuildNumber = 74;
    }
  }

  /// Get or create the installation identity.
  ///
  /// On first call, generates a new installation ID and stores it.
  /// On subsequent calls, returns the existing installation ID.
  /// Updates last opened time and version on every call.
  ///
  /// Returns a [LicenseIdentity] with real stored values.
  static Future<LicenseIdentity> getOrCreateIdentity() async {
    try {
      // Try to read existing identity
      var identity = LicenseStorage.read();

      if (identity == null) {
        // First launch: create new identity
        identity = LicenseStorage.create(
          appVersion: _cachedAppVersion ?? '1.2.1',
          buildNumber: _cachedBuildNumber ?? 0,
        );
        await LicenseStorage.write(identity);
      } else {
        // Subsequent launches: update last opened time and version
        final now = DateTime.now().millisecondsSinceEpoch;
        identity = identity.copyWith(
          lastOpenedTime: now,
          currentVersion: _cachedAppVersion ?? '1.2.1',
          buildNumber: _cachedBuildNumber ?? 0,
        );
        await LicenseStorage.write(identity);
      }

      return LicenseIdentity(
        installationId: identity.installationId,
        firstInstallTime: identity.firstInstallTime,
        currentVersion: identity.currentVersion,
        lastOpenedTime: identity.lastOpenedTime,
        licenseStatus: identity.licenseStatus,
      );
    } catch (e) {
      // Fallback to placeholder if storage fails
      return LicenseIdentity(
        installationId: 'ERROR-STORAGE-FAILED',
        firstInstallTime: 0,
        currentVersion: _cachedAppVersion ?? '1.2.1',
        lastOpenedTime: DateTime.now().millisecondsSinceEpoch,
        licenseStatus: 'unknown',
      );
    }
  }

  /// Get the existing installation identity.
  ///
  /// Returns the stored installation identity if it exists.
  /// Returns null if no installation identity has been created yet.
  static Future<LicenseIdentity?> getIdentity() async {
    try {
      final identity = LicenseStorage.read();
      if (identity == null) return null;

      return LicenseIdentity(
        installationId: identity.installationId,
        firstInstallTime: identity.firstInstallTime,
        currentVersion: identity.currentVersion,
        lastOpenedTime: identity.lastOpenedTime,
        licenseStatus: identity.licenseStatus,
      );
    } catch (e) {
      return null;
    }
  }

  /// Update the last opened time.
  ///
  /// Called on every app launch to track the most recent app open time.
  /// Persists to Hive storage.
  static Future<void> updateLastOpenedTime() async {
    try {
      var identity = LicenseStorage.read();
      if (identity != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        identity = identity.copyWith(lastOpenedTime: now);
        await LicenseStorage.write(identity);
      }
    } catch (e) {
      // Silently fail - storage errors should not crash the app
    }
  }

  /// Get the current app version.
  ///
  /// Returns the version string (e.g., "1.2.1").
  static String getCurrentVersion() {
    return _cachedAppVersion ?? '1.2.1';
  }

  /// Get the first installation time.
  ///
  /// Returns the timestamp (milliseconds since epoch) of the first app install.
  /// Returns 0 if no identity has been created yet.
  static Future<int> getFirstInstallTime() async {
    try {
      final identity = LicenseStorage.read();
      return identity?.firstInstallTime ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get the last opened time.
  ///
  /// Returns the timestamp (milliseconds since epoch) of the last app open.
  /// Returns 0 if no identity has been created yet.
  static Future<int> getLastOpenedTime() async {
    try {
      final identity = LicenseStorage.read();
      return identity?.lastOpenedTime ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get the installation ID.
  ///
  /// Returns the unique identifier for this installation.
  /// Never regenerates automatically.
  /// Returns 'NOT_AVAILABLE' if no identity has been created yet.
  static Future<String> getInstallationId() async {
    try {
      final identity = LicenseStorage.read();
      return identity?.installationId ?? 'NOT_AVAILABLE';
    } catch (e) {
      return 'NOT_AVAILABLE';
    }
  }

  /// Get the build number.
  ///
  /// Returns the current build number.
  static int getBuildNumber() {
    return _cachedBuildNumber ?? 0;
  }
}
