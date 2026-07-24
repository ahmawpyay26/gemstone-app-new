import 'license_status.dart';

/// Abstract repository interface for license management.
///
/// This interface defines the contract for license-related operations.
/// Implementation details are deferred to the data layer.
abstract class LicenseRepository {
  /// Get the current license status.
  ///
  /// Returns a [Future] that resolves to the current [LicenseStatus].
  Future<LicenseStatus> getStatus();

  /// Check if the license is currently activated.
  ///
  /// Returns a [Future] that resolves to `true` if the license is active,
  /// `false` otherwise.
  Future<bool> isActivated();
}
