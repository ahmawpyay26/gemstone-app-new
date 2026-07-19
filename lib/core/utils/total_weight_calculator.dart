import '../local/models.dart';
import 'weight_converter.dart';

/// Shared service for calculating total weight across the application
/// Ensures consistent calculation in Voucher Detail, PDF, and other places
class TotalWeightCalculator {
  /// Calculate total weight with smart unit handling
  /// Returns total weight in original unit if all items use same unit
  /// Returns total weight in kg if mixed units are detected
  /// 
  /// Parameters:
  /// - [items]: List of BrokerConsignment items to calculate weight from
  /// 
  /// Returns:
  /// - Map with keys: 'weight' (double), 'unit' (String), 'hasWeight' (bool)
  static Map<String, dynamic> calculateTotalWeight(List<BrokerConsignment> items) {
    // Collect all valid items with weight
    final validItems = items.where((item) {
      return item.weight != null && item.weight! > 0 && item.weightUnit != null && item.weightUnit!.isNotEmpty;
    }).toList();

    if (validItems.isEmpty) {
      return {'weight': 0.0, 'unit': '', 'hasWeight': false};
    }

    // Get all units from valid items
    final units = validItems.map((item) => item.weightUnit!).toList();

    // Check if all units are the same
    if (WeightConverter.areAllUnitsSame(units)) {
      // All same unit - sum directly in original unit (no conversion needed)
      final commonUnit = WeightConverter.normalizeUnit(units.first);
      double totalWeight = 0.0;
      for (final item in validItems) {
        // Sum original values since all units are the same
        totalWeight += item.displayWeight;
      }
      return {'weight': totalWeight, 'unit': commonUnit, 'hasWeight': true};
    } else {
      // Mixed units - convert all to kg
      double totalWeightKg = 0.0;
      for (final item in validItems) {
        // Convert each item to kg and sum
        totalWeightKg += item.totalWeightKg;
      }
      return {'weight': totalWeightKg, 'unit': 'kg', 'hasWeight': true};
    }
  }

  /// Get total weight value from calculation result
  static double getTotalWeightValue(Map<String, dynamic> result) {
    return result['weight'] as double? ?? 0.0;
  }

  /// Get total weight unit from calculation result
  static String getTotalWeightUnit(Map<String, dynamic> result) {
    return result['unit'] as String? ?? '';
  }

  /// Check if calculation has valid weight
  static bool hasValidWeight(Map<String, dynamic> result) {
    return result['hasWeight'] as bool? ?? false;
  }
}
