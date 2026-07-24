import 'package:uuid/uuid.dart';
import '../models/activation_result.dart';
import '../models/license_activation.dart';
import '../data/hive_activation_repository.dart';
import 'installation_identity_service.dart';

/// Service for handling license activation.
/// This is the foundation for local license activation.
/// 
/// Phase 1D: Placeholder implementation only
/// - No real activation verification
/// - No server communication
/// - No expiration logic
/// - No application locking
class ActivationService {
  final HiveActivationRepository _repository;
  final InstallationIdentityService _identityService;

  ActivationService({
    required HiveActivationRepository repository,
    required InstallationIdentityService identityService,
  })  : _repository = repository,
        _identityService = identityService;

  /// Initialize the activation service
  Future<void> init() async {
    try {
      await _repository.init();
    } catch (e) {
      // TODO: Handle initialization error in Phase 2
      print('Error initializing ActivationService: $e');
    }
  }

  /// Activate license with provided activation key
  /// 
  /// Phase 1D: This is a placeholder implementation.
  /// It stores the activation information locally but does NOT:
  /// - Verify the activation key format
  /// - Communicate with a server
  /// - Check expiration
  /// - Lock/unlock the application
  /// - Perform any real validation
  /// 
  /// TODO: Implement real activation verification in Phase 2
  Future<ActivationResult> activateLicense(String activationKey) async {
    try {
      // TODO: Add activation key format validation in Phase 2
      if (activationKey.isEmpty) {
        return ActivationResult.failure(
          message: 'Activation key cannot be empty',
          errorCode: 'EMPTY_KEY',
        );
      }

      // Get installation ID
      final installationId = await _identityService.getInstallationId();
      if (installationId == null || installationId.isEmpty) {
        return ActivationResult.failure(
          message: 'Installation ID not found',
          errorCode: 'NO_INSTALLATION_ID',
        );
      }

      // TODO: Implement real activation verification in Phase 2
      // For now, just store the activation information locally
      final now = DateTime.now().millisecondsSinceEpoch;
      const appVersion = '1.2.1';
      const schemaVersion = 1;

      final activation = LicenseActivation(
        activationKey: activationKey,
        installationId: installationId,
        activatedAt: now,
        activationStatus: 'pending', // TODO: Set to 'activated' after verification in Phase 2
        appVersion: appVersion,
        schemaVersion: schemaVersion,
      );

      // Store activation locally
      await _repository.saveActivation(activation);

      return ActivationResult.success(
        message: 'Activation stored locally (Phase 1D: placeholder only)',
        data: activation,
      );
    } catch (e) {
      // TODO: Add proper error handling in Phase 2
      return ActivationResult.failure(
        message: 'Activation failed: $e',
        errorCode: 'ACTIVATION_ERROR',
      );
    }
  }

  /// Get current activation status
  Future<String> getActivationStatus() async {
    try {
      return await _repository.getActivationStatus();
    } catch (e) {
      // TODO: Handle error in Phase 2
      print('Error getting activation status: $e');
      return 'unknown';
    }
  }

  /// Get stored activation information
  Future<LicenseActivation?> getActivation() async {
    try {
      return await _repository.getActivation();
    } catch (e) {
      // TODO: Handle error in Phase 2
      print('Error getting activation: $e');
      return null;
    }
  }

  /// Check if license is activated
  Future<bool> isActivated() async {
    try {
      return await _repository.hasActivation();
    } catch (e) {
      // TODO: Handle error in Phase 2
      print('Error checking activation: $e');
      return false;
    }
  }

  /// Clear activation (for testing or reset)
  /// 
  /// TODO: Add authorization check in Phase 2
  Future<void> clearActivation() async {
    try {
      await _repository.clearActivation();
    } catch (e) {
      // TODO: Handle error in Phase 2
      print('Error clearing activation: $e');
    }
  }

  /// Generate a test activation key (for development only)
  /// 
  /// TODO: Remove this method before production in Phase 2
  String generateTestActivationKey() {
    const uuid = Uuid();
    return 'TEST-${uuid.v4().replaceAll('-', '').substring(0, 16).toUpperCase()}';
  }
}
