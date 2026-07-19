/// Weight conversion helper for converting various units to kilograms
class WeightConverter {
  /// Conversion factors to kilograms
  static const Map<String, double> _conversionFactors = {
    'kg': 1.0,
    'g': 0.001,
    'lb': 0.453592,
    'oz': 0.0283495,
    'ပိသာ': 1.63293, // viss (ပိဿာ) - Burmese unit
    'ကျပ်သား': 0.408233, // kyattha (ကျပ်သား) - Burmese unit
    'ကာရက်': 0.0002, // carat (ကာရက်)
  };

  /// Convert weight from any supported unit to kilograms
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
}
