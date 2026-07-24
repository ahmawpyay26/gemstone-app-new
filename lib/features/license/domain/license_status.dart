/// License status enumeration.
///
/// Represents the possible states of a license in the system.
enum LicenseStatus {
  /// Trial license (time-limited)
  trial,

  /// Active license (verified and valid)
  active,

  /// Revoked license (no longer valid)
  revoked,

  /// Unknown license status
  unknown,
}
