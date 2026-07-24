import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'models/hive_license_identity.dart';

/// Helper class for managing license identity storage using JSON files.
///
/// This class provides a simple interface for reading and writing
/// license identity data to a JSON file in the app's documents directory.
///
/// LIMITATION: Installation ID is expected to survive normal launches and updates,
/// but may disappear after uninstall, clear app data, or factory reset.
/// Future online recovery will solve this limitation.
class LicenseStorage {
  static const String _fileName = 'license_identity.json';
  static File? _cachedFile;

  /// Get the path to the license identity file.
  static Future<File> _getFile() async {
    if (_cachedFile != null) {
      return _cachedFile!;
    }
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      _cachedFile = File('${dir.path}/$_fileName');
      return _cachedFile!;
    } catch (e) {
      // Fallback to temp directory if documents directory is not available
      final dir = await getTemporaryDirectory();
      _cachedFile = File('${dir.path}/$_fileName');
      return _cachedFile!;
    }
  }

  /// Initialize the license storage.
  /// This is a no-op for file-based storage, but kept for API compatibility.
  static Future<void> init() async {
    // No initialization needed for file-based storage
  }

  /// Read the stored license identity.
  /// Returns null if no identity has been stored yet.
  static HiveLicenseIdentity? read() {
    try {
      // Synchronous read is not ideal, but necessary for initialization
      // In production, this should be async
      return null; // Placeholder - will be called asynchronously
    } catch (e) {
      return null;
    }
  }

  /// Read the stored license identity asynchronously.
  static Future<HiveLicenseIdentity?> readAsync() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return null;
      }

      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      
      return HiveLicenseIdentity(
        installationId: json['installationId'] as String? ?? 'NOT_AVAILABLE',
        firstInstallTime: json['firstInstallTime'] as int? ?? 0,
        lastOpenedTime: json['lastOpenedTime'] as int? ?? 0,
        currentVersion: json['currentVersion'] as String? ?? '1.2.1',
        buildNumber: json['buildNumber'] as int? ?? 0,
        licenseStatus: json['licenseStatus'] as String? ?? 'UNKNOWN',
      );
    } catch (e) {
      return null;
    }
  }

  /// Write the license identity to storage.
  static Future<void> write(HiveLicenseIdentity identity) async {
    try {
      final file = await _getFile();
      
      final json = {
        'installationId': identity.installationId,
        'firstInstallTime': identity.firstInstallTime,
        'lastOpenedTime': identity.lastOpenedTime,
        'currentVersion': identity.currentVersion,
        'buildNumber': identity.buildNumber,
        'licenseStatus': identity.licenseStatus,
      };
      
      await file.writeAsString(jsonEncode(json));
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
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silently fail
    }
  }
}
