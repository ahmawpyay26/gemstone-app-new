import 'package:hive/hive.dart';

part 'hive_license_identity.g.dart';

/// Hive model for persisting installation identity locally.
///
/// This model stores the core identity information for a single installation.
/// It is used to uniquely identify and track an installation across sessions.
///
/// Hive TypeId: 18 (next available after existing adapters)
@HiveType(typeId: 18)
class HiveLicenseIdentity {
  /// Unique identifier for this installation.
  /// Generated once on first launch and never changed.
  @HiveField(0)
  final String installationId;

  /// Timestamp (milliseconds since epoch) when the app was first installed.
  /// Set once on first launch and never changed.
  @HiveField(1)
  final int firstInstallTime;

  /// Timestamp (milliseconds since epoch) of the last time the app was opened.
  /// Updated on every launch.
  @HiveField(2)
  int lastOpenedTime;

  /// Current app version (e.g., "1.2.1").
  /// Updated on every launch.
  @HiveField(3)
  String currentVersion;

  /// Current app build number (e.g., 74).
  /// Updated on every launch.
  @HiveField(4)
  int buildNumber;

  /// Current license status.
  /// Defaults to "UNKNOWN" and updated by license verification logic.
  @HiveField(5)
  String licenseStatus;

  /// Creates a new [HiveLicenseIdentity].
  HiveLicenseIdentity({
    required this.installationId,
    required this.firstInstallTime,
    required this.lastOpenedTime,
    required this.currentVersion,
    required this.buildNumber,
    this.licenseStatus = 'UNKNOWN',
  });

  /// Creates a copy of this object with optional field overrides.
  HiveLicenseIdentity copyWith({
    String? installationId,
    int? firstInstallTime,
    int? lastOpenedTime,
    String? currentVersion,
    int? buildNumber,
    String? licenseStatus,
  }) {
    return HiveLicenseIdentity(
      installationId: installationId ?? this.installationId,
      firstInstallTime: firstInstallTime ?? this.firstInstallTime,
      lastOpenedTime: lastOpenedTime ?? this.lastOpenedTime,
      currentVersion: currentVersion ?? this.currentVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      licenseStatus: licenseStatus ?? this.licenseStatus,
    );
  }

  @override
  String toString() => 'HiveLicenseIdentity('
      'installationId: $installationId, '
      'firstInstallTime: $firstInstallTime, '
      'lastOpenedTime: $lastOpenedTime, '
      'currentVersion: $currentVersion, '
      'buildNumber: $buildNumber, '
      'licenseStatus: $licenseStatus)';
}
