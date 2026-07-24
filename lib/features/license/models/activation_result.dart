/// Result of an activation operation.
/// Used to communicate success/failure and error details.
class ActivationResult {
  final bool success;
  final String message;
  final String? errorCode;
  final dynamic data;

  ActivationResult({
    required this.success,
    required this.message,
    this.errorCode,
    this.data,
  });

  /// Successful activation result
  factory ActivationResult.success({
    required String message,
    dynamic data,
  }) {
    return ActivationResult(
      success: true,
      message: message,
      errorCode: null,
      data: data,
    );
  }

  /// Failed activation result
  factory ActivationResult.failure({
    required String message,
    required String errorCode,
  }) {
    return ActivationResult(
      success: false,
      message: message,
      errorCode: errorCode,
      data: null,
    );
  }

  @override
  String toString() {
    return 'ActivationResult(success: $success, message: $message, errorCode: $errorCode)';
  }
}
