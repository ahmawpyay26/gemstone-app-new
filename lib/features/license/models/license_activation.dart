import 'package:hive/hive.dart';

part 'license_activation.g.dart';

/// License activation model for storing activation information locally.
/// This is the foundation for local license activation.
/// 
/// Fields:
/// - activationKey: The activation key provided by the user
/// - installationId: Unique identifier for this installation
/// - activatedAt: Timestamp when the license was activated
/// - activationStatus: Current activation status (pending, activated, revoked, unknown)
/// - appVersion: App version at the time of activation
/// - schemaVersion: Schema version for migration purposes
@HiveType(typeId: 19)
class HiveLicenseActivation {
  @HiveField(0)
  final String activationKey;

  @HiveField(1)
  final String installationId;

  @HiveField(2)
  final int activatedAt;

  @HiveField(3)
  final String activationStatus;

  @HiveField(4)
  final String appVersion;

  @HiveField(5)
  final int schemaVersion;

  HiveLicenseActivation({
    required this.activationKey,
    required this.installationId,
    required this.activatedAt,
    required this.activationStatus,
    required this.appVersion,
    required this.schemaVersion,
  });
}

/// Dart model for license activation (non-Hive).
/// Used throughout the application for type safety.
class LicenseActivation {
  final String activationKey;
  final String installationId;
  final int activatedAt;
  final String activationStatus;
  final String appVersion;
  final int schemaVersion;

  LicenseActivation({
    required this.activationKey,
    required this.installationId,
    required this.activatedAt,
    required this.activationStatus,
    required this.appVersion,
    required this.schemaVersion,
  });

  /// Convert from Hive model to Dart model
  factory LicenseActivation.fromHive(HiveLicenseActivation hive) {
    return LicenseActivation(
      activationKey: hive.activationKey,
      installationId: hive.installationId,
      activatedAt: hive.activatedAt,
      activationStatus: hive.activationStatus,
      appVersion: hive.appVersion,
      schemaVersion: hive.schemaVersion,
    );
  }

  /// Convert to Hive model for storage
  HiveLicenseActivation toHive() {
    return HiveLicenseActivation(
      activationKey: activationKey,
      installationId: installationId,
      activatedAt: activatedAt,
      activationStatus: activationStatus,
      appVersion: appVersion,
      schemaVersion: schemaVersion,
    );
  }

  /// Create a copy with optional field replacements
  LicenseActivation copyWith({
    String? activationKey,
    String? installationId,
    int? activatedAt,
    String? activationStatus,
    String? appVersion,
    int? schemaVersion,
  }) {
    return LicenseActivation(
      activationKey: activationKey ?? this.activationKey,
      installationId: installationId ?? this.installationId,
      activatedAt: activatedAt ?? this.activatedAt,
      activationStatus: activationStatus ?? this.activationStatus,
      appVersion: appVersion ?? this.appVersion,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }
}
