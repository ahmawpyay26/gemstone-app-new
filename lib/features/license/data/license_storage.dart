import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'models/hive_license_identity.dart';

/// Helper class for managing license identity storage in Hive.
///
/// This class provides a simple interface for reading and writing
/// license identity data to a dedicated Hive box.
///
/// LIMITATION: Installation ID is expected to survive normal launches and updates,
/// but may disappear after uninstall, clear app data, or factory reset.
/// Future online recovery will solve this limitation.
class LicenseStorage {
  static const String boxName = 'license_identity_box';
  static const String _key = 'identity';

  /// Initialize the license storage box.
  /// Must be called after Hive.initFlutter() and before using this class.
  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(HiveLicenseIdentityAdapter());
    }
    await Hive.openBox<HiveLicenseIdentity>(boxName);
  }

  /// Get the license identity box.
  static Box<HiveLicenseIdentity> _getBox() {
    return Hive.box<HiveLicenseIdentity>(boxName);
  }

  /// Read the stored license identity.
  /// Returns null if no identity has been stored yet.
  static HiveLicenseIdentity? read() {
    try {
      final box = _getBox();
      return box.get(_key);
    } catch (e) {
      return null;
    }
  }

  /// Write the license identity to storage.
  static Future<void> write(HiveLicenseIdentity identity) async {
    try {
      final box = _getBox();
      await box.put(_key, identity);
    } catch (e) {
      // Silently fail - storage errors should not crash the app
    }
  }

  /// Create a new license identity with a generated installation ID.
  static HiveLicenseIdentity create({
    required String appVersion,
    required int buildNumber,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return HiveLicenseIdentity(
      installationId: _generateInstallationId(),
      firstInstallTime: now,
      lastOpenedTime: now,
      currentVersion: appVersion,
      buildNumber: buildNumber,
      licenseStatus: 'UNKNOWN',
    );
  }

  /// Generate a unique installation ID.
  /// Uses UUID v4 for uniqueness.
  static String _generateInstallationId() {
    return const Uuid().v4().replaceAll('-', '').substring(0, 16).toUpperCase();
  }

  /// Clear all stored license identity data.
  /// Used for testing or manual reset.
  static Future<void> clear() async {
    try {
      final box = _getBox();
      await box.clear();
    } catch (e) {
      // Silently fail
    }
  }
}
