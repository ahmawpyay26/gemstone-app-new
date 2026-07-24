import '../models/license_activation.dart';

/// Abstract repository interface for local license activation storage.
/// Defines the contract for storing and retrieving activation information.
abstract class LocalActivationRepository {
  /// Store activation information locally
  Future<void> saveActivation(LicenseActivation activation);

  /// Retrieve stored activation information
  Future<LicenseActivation?> getActivation();

  /// Clear stored activation information
  Future<void> clearActivation();

  /// Check if activation exists
  Future<bool> hasActivation();

  /// Update activation status
  Future<void> updateActivationStatus(String status);

  /// Get current activation status
  Future<String> getActivationStatus();
}
