/// Represents the installation identity for the License System.
///
/// This model holds the core identity information for a single installation.
/// It is used to uniquely identify and track an installation across sessions.
///
/// Fields:
/// - installationId: Unique identifier for this installation (generated once, never changed)
/// - firstInstallTime: Timestamp when the app was first installed
/// - currentVersion: Current app version (e.g., "1.2.1")
/// - lastOpenedTime: Timestamp of the last app open
/// - licenseStatus: Current license status (trial, active, revoked, unknown)
class LicenseIdentity {
  /// Unique identifier for this installation.
  /// Generated once on first app launch, never regenerated.
  final String installationId;

  /// Timestamp when the app was first installed (milliseconds since epoch).
  /// Set once on first app launch, never changed.
  final int firstInstallTime;

  /// Current app version (e.g., "1.2.1").
  /// Updated when the app version changes.
  final String currentVersion;

  /// Timestamp of the last app open (milliseconds since epoch).
  /// Updated on every app launch.
  final int lastOpenedTime;

  /// Current license status.
  /// Possible values: "trial", "active", "revoked", "unknown"
  final String licenseStatus;

  /// Creates a new [LicenseIdentity] instance.
  const LicenseIdentity({
    required this.installationId,
    required this.firstInstallTime,
    required this.currentVersion,
    required this.lastOpenedTime,
    required this.licenseStatus,
  });

  /// Creates a copy of this [LicenseIdentity] with optional field overrides.
  LicenseIdentity copyWith({
    String? installationId,
    int? firstInstallTime,
    String? currentVersion,
    int? lastOpenedTime,
    String? licenseStatus,
  }) {
    return LicenseIdentity(
      installationId: installationId ?? this.installationId,
      firstInstallTime: firstInstallTime ?? this.firstInstallTime,
      currentVersion: currentVersion ?? this.currentVersion,
      lastOpenedTime: lastOpenedTime ?? this.lastOpenedTime,
      licenseStatus: licenseStatus ?? this.licenseStatus,
    );
  }

  @override
  String toString() {
    return 'LicenseIdentity('
        'installationId: $installationId, '
        'firstInstallTime: $firstInstallTime, '
        'currentVersion: $currentVersion, '
        'lastOpenedTime: $lastOpenedTime, '
        'licenseStatus: $licenseStatus)';
  }
}
