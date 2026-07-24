/// Diagnostic information for the License System.
///
/// This model holds diagnostic and telemetry data about the installation
/// and license status. Used for debugging and monitoring purposes.
///
/// Fields:
/// - installationId: Unique identifier for this installation
/// - appVersion: Current app version (e.g., "1.2.1")
/// - buildNumber: Build number (e.g., "74")
/// - firstInstallDate: Human-readable first install date
/// - lastOpenedDate: Human-readable last opened date
/// - licenseStatus: Current license status (trial, active, revoked, unknown)
class DiagnosticInfo {
  /// Unique identifier for this installation.
  final String installationId;

  /// Current app version (e.g., "1.2.1").
  final String appVersion;

  /// Build number (e.g., "74").
  final String buildNumber;

  /// Human-readable first install date (e.g., "2026-07-24 09:47:00").
  /// "Not Available" if not set.
  final String firstInstallDate;

  /// Human-readable last opened date (e.g., "2026-07-24 09:47:00").
  /// "Not Available" if not set.
  final String lastOpenedDate;

  /// Current license status (trial, active, revoked, unknown).
  final String licenseStatus;

  /// Creates a new [DiagnosticInfo] instance.
  const DiagnosticInfo({
    required this.installationId,
    required this.appVersion,
    required this.buildNumber,
    required this.firstInstallDate,
    required this.lastOpenedDate,
    required this.licenseStatus,
  });

  /// Creates a copy of this [DiagnosticInfo] with optional field overrides.
  DiagnosticInfo copyWith({
    String? installationId,
    String? appVersion,
    String? buildNumber,
    String? firstInstallDate,
    String? lastOpenedDate,
    String? licenseStatus,
  }) {
    return DiagnosticInfo(
      installationId: installationId ?? this.installationId,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      firstInstallDate: firstInstallDate ?? this.firstInstallDate,
      lastOpenedDate: lastOpenedDate ?? this.lastOpenedDate,
      licenseStatus: licenseStatus ?? this.licenseStatus,
    );
  }

  /// Creates placeholder diagnostic info with default values.
  factory DiagnosticInfo.placeholder() {
    return const DiagnosticInfo(
      installationId: 'INST-PLACEHOLDER-001',
      appVersion: '1.2.1',
      buildNumber: '74',
      firstInstallDate: 'Not Available',
      lastOpenedDate: 'Not Available',
      licenseStatus: 'UNKNOWN',
    );
  }

  @override
  String toString() {
    return 'DiagnosticInfo('
        'installationId: $installationId, '
        'appVersion: $appVersion, '
        'buildNumber: $buildNumber, '
        'firstInstallDate: $firstInstallDate, '
        'lastOpenedDate: $lastOpenedDate, '
        'licenseStatus: $licenseStatus)';
  }
}
