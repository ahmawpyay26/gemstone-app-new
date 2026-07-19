/// Weight conversion helper for converting various units to kilograms
class WeightConverter {
  /// Conversion factors to kilograms
  static const Map<String, double> _conversionFactors = {
    'kg': 1.0,
    'g': 0.001,
    'lb': 0.4536,
    'oz': 0.02835,
    'ပိသာ': 1.63293, // viss (ပိဿာ) - Burmese unit: 1 viss = 1.63293 kg
    'ကျပ်သား': 0.01633, // kyattha (ကျပ်သား) - Burmese unit: 1 kyattha = 0.01633 kg
    'ကာရက်': 0.0002, // carat (ကာရက်): 1 carat = 0.0002 kg
  };

  /// Convert weight from any supported unit to kilograms
  /// 
  /// Conversion formulas:
  /// - 1 viss (ပိသာ) = 1.63293 kg
  /// - 1 kyattha (ကျပ်သား) = 0.01633 kg
  /// - 1 carat (ကာရက်) = 0.0002 kg
  /// - 1 gram (g) = 0.001 kg
  /// - 1 pound (lb) = 0.4536 kg
  /// - 1 ounce (oz) = 0.02835 kg
  /// 
  /// Parameters:
  /// - [weight]: The weight value to convert
  /// - [unit]: The unit of the weight (kg, g, lb, oz, ပိသာ, ကျပ်သား, ကာရက်)
  /// 
  /// Returns:
  /// - The weight in kilograms
  /// - Returns 0 if weight is null, negative, or unit is not supported
  static double convertToKg(double? weight, String? unit) {
    // Return 0 if weight is null or invalid
    if (weight == null || weight <= 0) {
      return 0.0;
    }

    // Return 0 if unit is null or empty
    if (unit == null || unit.isEmpty) {
      return 0.0;
    }

    // Get conversion factor, default to 1.0 if unit not found
    final factor = _conversionFactors[unit] ?? 1.0;

    // Calculate and return weight in kg
    return weight * factor;
  }

  /// Format weight in kilograms to 2 decimal places
  /// 
  /// Parameters:
  /// - [weightKg]: The weight in kilograms
  /// 
  /// Returns:
  /// - Formatted string with 2 decimal places (e.g., "31.99 kg")
  static String formatKg(double weightKg) {
    return '${weightKg.toStringAsFixed(2)} kg';
  }

  /// Check if a weight value is valid (not null, not zero, not negative)
  static bool isValidWeight(double? weight) {
    return weight != null && weight > 0;
  }

  /// Check if a unit string is supported
  static bool isSupportedUnit(String? unit) {
    return unit != null && _conversionFactors.containsKey(unit);
  }

  /// Get list of all supported units
  static List<String> getSupportedUnits() {
    return _conversionFactors.keys.toList();
  }

  /// Normalize unit name to standard form
  /// Treats similar units as identical
  static String normalizeUnit(String? unit) {
    if (unit == null || unit.isEmpty) return '';
    
    final normalized = unit.toLowerCase().trim();
    
    // kg variants
    if (normalized == 'kg' || normalized == 'kilogram') {
      return 'kg';
    }
    
    // g variants
    if (normalized == 'g' || normalized == 'gram') {
      return 'g';
    }
    
    // viss variants
    if (normalized == 'viss' || normalized == 'ပိဿာ' || normalized == 'ပိသာ') {
      return 'ပိသာ';
    }
    
    // kyattha variants
    if (normalized == 'kyattha' || normalized == 'ကျပ်သား') {
      return 'ကျပ်သား';
    }
    
    // carat variants
    if (normalized == 'carat' || normalized == 'ကာရက်') {
      return 'ကာရက်';
    }
    
    // lb variants
    if (normalized == 'lb' || normalized == 'pound') {
      return 'lb';
    }
    
    // oz variants
    if (normalized == 'oz' || normalized == 'ounce') {
      return 'oz';
    }
    
    return unit; // Return original if not recognized
  }

  /// Check if all units in list are the same (after normalization)
  static bool areAllUnitsSame(List<String> units) {
    if (units.isEmpty) return true;
    
    final normalized = units.map((u) => normalizeUnit(u)).toList();
    final first = normalized.first;
    
    return normalized.every((unit) => unit == first);
  }

  /// Get the common unit if all are the same, otherwise return null
  static String? getCommonUnit(List<String> units) {
    if (units.isEmpty) return null;
    
    if (areAllUnitsSame(units)) {
      return normalizeUnit(units.first);
    }
    
    return null;
  }
}
