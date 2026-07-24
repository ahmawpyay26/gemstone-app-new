import '../domain/license_repository.dart';
import '../domain/license_status.dart';

/// Local implementation of [LicenseRepository].
///
/// This is a compile-safe placeholder implementation that returns
/// safe default values. Future phases will integrate actual license
/// verification, storage, and device binding logic.
///
/// TODO(License Phase 2): Integrate Hive-based license storage
/// TODO(License Phase 3): Implement device fingerprinting
/// TODO(License Phase 4): Add online license verification
/// TODO(License Phase 5): Implement revocation checking
class LocalLicenseRepository implements LicenseRepository {
  /// Creates a new instance of [LocalLicenseRepository].
  LocalLicenseRepository();

  @override
  Future<LicenseStatus> getStatus() async {
    // TODO(License Phase 2): Replace with actual license status lookup
    // from local storage or online verification
    return LicenseStatus.unknown;
  }

  @override
  Future<bool> isActivated() async {
    // TODO(License Phase 2): Replace with actual activation check
    // This should verify license validity and device binding
    return false;
  }
}
