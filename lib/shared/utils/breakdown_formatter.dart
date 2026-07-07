/// Shared formatter for breakdown items display
/// Supports both old format (Map<String, int>) and new format (Map<String, Map<String, dynamic>>)
/// Do not display raw breakdownItems Map directly.
class BreakdownFormatter {
  /// Format a single breakdown item for display
  /// Supports:
  /// - Old format: int value → "50 ခု"
  /// - New format: Map with quantity/weight → "50 ခု" or "50 ခု — 9 kg"
  static String formatItem(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is int) {
      // Old format: just quantity
      return '$value ခု';
    }

    if (value is Map<String, dynamic>) {
      // New format: {quantity, weight, weightUnit}
      final qty = (value['quantity'] as int?) ?? 0;
      final weight = (value['weight'] as num?)?.toDouble();
      final unit = value['weightUnit'] as String?;

      if (weight != null && weight > 0) {
        final weightStr = weight.toStringAsFixed(1);
        final unitStr = unit ?? 'kg';
        return '$qty ခု — $weightStr $unitStr';
      } else {
        return '$qty ခု';
      }
    }

    // Fallback: should never reach here
    return '';
  }

  /// Format breakdown items for display in a list
  /// Returns formatted entries with name and display text
  static List<MapEntry<String, String>> formatItems(
    Map<String, dynamic> breakdownItems,
  ) {
    return breakdownItems.entries
        .map((entry) {
          final displayText = formatItem(entry.value);
          return MapEntry(entry.key, displayText);
        })
        .toList();
  }

  /// Format breakdown items for collapsed summary display
  /// Example: "ပုတီး — 50 ခု\nကာရက် — 30 ခု — 5 kg"
  static String formatSummary(
    Map<String, dynamic> breakdownItems, {
    bool filterByQuantity = true,
  }) {
    final entries = breakdownItems.entries.where((e) {
      if (!filterByQuantity) return true;

      final itemData = e.value as Map<String, dynamic>?;
      if (itemData == null) return false;
      final quantity = (itemData['quantity'] as num?)?.toInt() ?? 0;
      return quantity > 0;
    }).toList();

    return entries
        .map((e) => '${e.key} — ${formatItem(e.value)}')
        .join('\n');
  }
}
