import 'package:hive/hive.dart';
import '../models/license_activation.dart';
import '../repositories/local_activation_repository.dart';

/// Hive-based implementation of LocalActivationRepository.
/// Stores license activation information in a local Hive box.
class HiveActivationRepository implements LocalActivationRepository {
  static const String _boxName = 'license_activation_box';
  static const String _activationKey = 'activation';

  late Box<HiveLicenseActivation> _box;

  /// Initialize the repository with Hive box
  Future<void> init() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _box = await Hive.openBox<HiveLicenseActivation>(_boxName);
      } else {
        _box = Hive.box<HiveLicenseActivation>(_boxName);
      }
    } catch (e) {
      // TODO: Handle Hive initialization error in Phase 2
      // For now, silently fail and return placeholder values
      print('Error initializing Hive activation box: $e');
    }
  }

  @override
  Future<void> saveActivation(LicenseActivation activation) async {
    try {
      await _box.put(_activationKey, activation.toHive());
    } catch (e) {
      // TODO: Handle save error in Phase 2
      print('Error saving activation: $e');
    }
  }

  @override
  Future<LicenseActivation?> getActivation() async {
    try {
      final hiveActivation = _box.get(_activationKey);
      if (hiveActivation != null) {
        return LicenseActivation.fromHive(hiveActivation);
      }
      return null;
    } catch (e) {
      // TODO: Handle retrieval error in Phase 2
      print('Error getting activation: $e');
      return null;
    }
  }

  @override
  Future<void> clearActivation() async {
    try {
      await _box.delete(_activationKey);
    } catch (e) {
      // TODO: Handle delete error in Phase 2
      print('Error clearing activation: $e');
    }
  }

  @override
  Future<bool> hasActivation() async {
    try {
      return _box.containsKey(_activationKey);
    } catch (e) {
      // TODO: Handle check error in Phase 2
      print('Error checking activation: $e');
      return false;
    }
  }

  @override
  Future<void> updateActivationStatus(String status) async {
    try {
      final activation = await getActivation();
      if (activation != null) {
        final updated = activation.copyWith(activationStatus: status);
        await saveActivation(updated);
      }
    } catch (e) {
      // TODO: Handle update error in Phase 2
      print('Error updating activation status: $e');
    }
  }

  @override
  Future<String> getActivationStatus() async {
    try {
      final activation = await getActivation();
      return activation?.activationStatus ?? 'unknown';
    } catch (e) {
      // TODO: Handle status retrieval error in Phase 2
      print('Error getting activation status: $e');
      return 'unknown';
    }
  }
}
