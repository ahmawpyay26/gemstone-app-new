import 'license_activation.dart';

/// Immutable state model for license activation.
/// Represents the current state of the activation system.
class LicenseActivationState {
  final LicenseActivation? activation;
  final bool isLoading;
  final String? error;
  final String activationStatus;

  const LicenseActivationState({
    this.activation,
    this.isLoading = false,
    this.error,
    this.activationStatus = 'unknown',
  });

  /// Create initial state
  factory LicenseActivationState.initial() {
    return const LicenseActivationState(
      activation: null,
      isLoading: false,
      error: null,
      activationStatus: 'unknown',
    );
  }

  /// Create loading state
  LicenseActivationState copyWithLoading() {
    return LicenseActivationState(
      activation: activation,
      isLoading: true,
      error: null,
      activationStatus: activationStatus,
    );
  }

  /// Create success state
  LicenseActivationState copyWithSuccess(LicenseActivation activation) {
    return LicenseActivationState(
      activation: activation,
      isLoading: false,
      error: null,
      activationStatus: activation.activationStatus,
    );
  }

  /// Create error state
  LicenseActivationState copyWithError(String error) {
    return LicenseActivationState(
      activation: activation,
      isLoading: false,
      error: error,
      activationStatus: activationStatus,
    );
  }

  @override
  String toString() {
    return 'LicenseActivationState(isLoading: $isLoading, error: $error, status: $activationStatus)';
  }
}
