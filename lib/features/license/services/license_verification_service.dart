import '../models/license_verification_result.dart';
import 'license_key_validator.dart';

/// Service for verifying license activation keys.
/// This is the foundation for offline license verification.
///
/// Phase 1E: Format validation only
/// - No server communication
/// - No expiration checks
/// - No blacklist verification
/// - No device fingerprinting
/// - No application locking
class LicenseVerificationService {
  /// Verify an activation key offline.
  ///
  /// Phase 1E: This performs format validation only.
  /// It does NOT:
  /// - Contact any server
  /// - Check expiration
  /// - Verify against blacklist
  /// - Check device fingerprint
  /// - Lock or unlock the application
  ///
  /// TODO: Implement online verification in Phase 2
  /// TODO: Implement expiration checks in Phase 3
  /// TODO: Implement blacklist in Phase 4
  Future<LicenseVerificationResult> verifyActivationKey(
    String activationKey,
  ) async {
    try {
      // Sanitize input
      final sanitizedKey = LicenseKeyValidator.sanitizeInput(activationKey);

      // Validate format
      final error = LicenseKeyValidator.getValidationError(sanitizedKey);
      if (error != null) {
        return LicenseVerificationResult.invalidFormat(
          message: error,
          errorCode: 'INVALID_FORMAT',
        );
      }

      // Format is valid, but real verification is pending
      return LicenseVerificationResult.pending(
        message: 'Activation key format is valid. Pending online verification (Phase 2).',
      );
    } catch (e) {
      return LicenseVerificationResult.invalidFormat(
        message: 'Verification error: $e',
        errorCode: 'VERIFICATION_ERROR',
      );
    }
  }

  /// Validate key format without async overhead (for UI validation)
  LicenseVerificationResult validateKeyFormatSync(String activationKey) {
    try {
      // Sanitize input
      final sanitizedKey = LicenseKeyValidator.sanitizeInput(activationKey);

      // Validate format
      final error = LicenseKeyValidator.getValidationError(sanitizedKey);
      if (error != null) {
        return LicenseVerificationResult.invalidFormat(
          message: error,
          errorCode: 'INVALID_FORMAT',
        );
      }

      return LicenseVerificationResult.validFormat(
        message: 'Activation key format is valid.',
      );
    } catch (e) {
      return LicenseVerificationResult.invalidFormat(
        message: 'Validation error: $e',
        errorCode: 'VALIDATION_ERROR',
      );
    }
  }

  /// Check if a key passes format validation
  bool isValidFormat(String activationKey) {
    final sanitizedKey = LicenseKeyValidator.sanitizeInput(activationKey);
    return LicenseKeyValidator.isValidFormat(sanitizedKey);
  }

  /// Get validation error message if key is invalid
  String? getValidationError(String activationKey) {
    final sanitizedKey = LicenseKeyValidator.sanitizeInput(activationKey);
    return LicenseKeyValidator.getValidationError(sanitizedKey);
  }
}
