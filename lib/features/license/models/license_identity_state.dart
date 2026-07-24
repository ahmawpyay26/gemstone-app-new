import 'license_identity.dart';

/// Immutable state model for installation identity.
///
/// Represents the current state of the installation identity system.
/// Used for state management and UI updates.
class LicenseIdentityState {
  /// The current license identity.
  final LicenseIdentity? identity;

  /// Whether the identity is currently being loaded.
  final bool isLoading;

  /// Error message if identity loading failed.
  final String? error;

  /// Creates a new [LicenseIdentityState] instance.
  const LicenseIdentityState({
    this.identity,
    this.isLoading = false,
    this.error,
  });

  /// Creates a copy of this state with optional field overrides.
  LicenseIdentityState copyWith({
    LicenseIdentity? identity,
    bool? isLoading,
    String? error,
  }) {
    return LicenseIdentityState(
      identity: identity ?? this.identity,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  /// Creates an initial loading state.
  factory LicenseIdentityState.loading() {
    return const LicenseIdentityState(isLoading: true);
  }

  /// Creates a state with an error.
  factory LicenseIdentityState.error(String message) {
    return LicenseIdentityState(error: message);
  }

  /// Creates a state with a loaded identity.
  factory LicenseIdentityState.loaded(LicenseIdentity identity) {
    return LicenseIdentityState(identity: identity);
  }

  @override
  String toString() {
    return 'LicenseIdentityState('
        'identity: $identity, '
        'isLoading: $isLoading, '
        'error: $error)';
  }
}
