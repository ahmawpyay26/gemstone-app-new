import '../domain/license_repository.dart';
import '../domain/license_status.dart';
import 'license_storage.dart';

/// Local implementation of [LicenseRepository] with real Hive storage.
///
/// This implementation reads and writes license status to local storage.
/// It provides the foundation for future license verification and activation logic.
///
/// LIMITATION: Currently only stores and retrieves license status.
/// Future phases will add device fingerprinting, online verification, and revocation checking.
class LocalLicenseRepository implements LicenseRepository {
  /// Creates a new instance of [LocalLicenseRepository].
  LocalLicenseRepository();

  @override
  Future<LicenseStatus> getStatus() async {
    try {
      final identity = LicenseStorage.read();
      if (identity == null) {
        return LicenseStatus.unknown;
      }

      // Map stored status string to enum
      switch (identity.licenseStatus.toLowerCase()) {
        case 'trial':
          return LicenseStatus.trial;
        case 'active':
          return LicenseStatus.active;
        case 'revoked':
          return LicenseStatus.revoked;
        default:
          return LicenseStatus.unknown;
      }
    } catch (e) {
      return LicenseStatus.unknown;
    }
  }

  @override
  Future<bool> isActivated() async {
    try {
      final status = await getStatus();
      return status == LicenseStatus.active;
    } catch (e) {
      return false;
    }
  }

  /// Update the license status in storage.
  /// Used by future license verification phases.
  Future<void> updateStatus(LicenseStatus status) async {
    try {
      var identity = LicenseStorage.read();
      if (identity != null) {
        final statusString = status.toString().split('.').last;
        identity = identity.copyWith(licenseStatus: statusString);
        await LicenseStorage.write(identity);
      }
    } catch (e) {
      // Silently fail - storage errors should not crash the app
    }
  }
}
