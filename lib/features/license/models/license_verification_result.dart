/// Result of a license verification operation.
/// Provides structured information about verification success/failure.
///
/// Phase 1E: Format validation results only
/// - No server communication
/// - No expiration information
/// - No device binding information
class LicenseVerificationResult {
  /// Whether the verification passed
  final bool isValid;

  /// Verification status message
  final String message;

  /// Error code if verification failed
  final String? errorCode;

  /// Verification type (format, online, etc.)
  final String verificationType;

  /// Timestamp of verification
  final int verificationTime;

  LicenseVerificationResult({
    required this.isValid,
    required this.message,
    this.errorCode,
    required this.verificationType,
    required this.verificationTime,
  });

  /// Successful format validation result
  factory LicenseVerificationResult.validFormat({
    required String message,
  }) {
    return LicenseVerificationResult(
      isValid: true,
      message: message,
      errorCode: null,
      verificationType: 'format',
      verificationTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Failed format validation result
  factory LicenseVerificationResult.invalidFormat({
    required String message,
    required String errorCode,
  }) {
    return LicenseVerificationResult(
      isValid: false,
      message: message,
      errorCode: errorCode,
      verificationType: 'format',
      verificationTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Pending verification result (format passed, waiting for online verification)
  factory LicenseVerificationResult.pending({
    required String message,
  }) {
    return LicenseVerificationResult(
      isValid: false,
      message: message,
      errorCode: 'PENDING_VERIFICATION',
      verificationType: 'format',
      verificationTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  String toString() {
    return 'LicenseVerificationResult(isValid: $isValid, message: $message, errorCode: $errorCode, type: $verificationType)';
  }
}
