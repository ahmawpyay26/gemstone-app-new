import '../models/license_identity.dart';

/// Abstract repository interface for installation identity management.
///
/// This interface defines the contract for installation identity operations.
/// Implementation details are deferred to the data layer.
///
/// TODO(License Phase 1B): Implement with Hive-backed storage
abstract class LicenseIdentityRepository {
  /// Get or create the installation identity.
  ///
  /// On first call, generates a new installation ID and stores it.
  /// On subsequent calls, returns the existing installation ID.
  ///
  /// Returns a [Future] that resolves to the [LicenseIdentity].
  Future<LicenseIdentity> getOrCreateIdentity();

  /// Get the existing installation identity.
  ///
  /// Returns the stored installation identity if it exists.
  /// Returns null if no installation identity has been created yet.
  Future<LicenseIdentity?> getIdentity();

  /// Update the last opened time.
  ///
  /// Called on every app launch to track the most recent app open time.
  Future<void> updateLastOpenedTime();

  /// Get the current app version.
  ///
  /// Returns the version string (e.g., "1.2.1").
  String getCurrentVersion();

  /// Get the first installation time.
  ///
  /// Returns the timestamp (milliseconds since epoch) of the first app install.
  Future<int> getFirstInstallTime();

  /// Get the last opened time.
  ///
  /// Returns the timestamp (milliseconds since epoch) of the last app open.
  Future<int> getLastOpenedTime();

  /// Get the installation ID.
  ///
  /// Returns the unique identifier for this installation.
  /// Never regenerates automatically.
  Future<String> getInstallationId();
}
