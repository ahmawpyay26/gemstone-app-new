import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import 'inline_selector.dart';

/// Fragment Item Selector - Step 2
/// Displays fragment inventory items for the selected gemstone
/// Shows: Fragment name, Remaining quantity, Remaining weight, Weight unit
class FragmentItemSelector extends StatelessWidget {
  final String? selectedGemstoneId;
  final String? selectedFragmentName;
  final ValueChanged<String?> onChanged;

  const FragmentItemSelector({
    Key? key,
    required this.selectedGemstoneId,
    required this.selectedFragmentName,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show if a gemstone has been selected
    if (selectedGemstoneId == null || selectedGemstoneId!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get the selected gemstone
    final selectedGemstone = LocalDb.gemstoneById(selectedGemstoneId!);
    if (selectedGemstone == null || selectedGemstone.breakdownItems == null) {
      return const SizedBox.shrink();
    }

    // Get available fragment items (quantity > 0)
    final availableItems = _getAvailableFragmentItems(selectedGemstone);
    if (availableItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'ရောင်းမည့် အစိတ်စိတ်ပိုင်း',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InlineSelector<String>(
            value: selectedFragmentName,
            hint: 'အစိတ်စိတ်ပိုင်း ရွေးချယ်မည်',
            borderColor: AppTheme.primaryAccent,
            backgroundColor: AppTheme.surfaceDark,
            style: const TextStyle(color: Colors.white),
            items: availableItems.map((item) {
              final fragmentName = item['name'] as String;
              final quantity = item['quantity'] as int;
              final weight = item['weight'] as double?;
              final weightUnit = item['weightUnit'] as String?;

              final displayText = weight != null && weight > 0
                  ? '$fragmentName\nQty: $quantity • Weight: ${weight.toStringAsFixed(2)} $weightUnit'
                  : '$fragmentName\nQty: $quantity';

              return DropdownMenuItem<String>(
                value: fragmentName,
                child: Text(
                  displayText,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// Get available fragment items with their details
  /// Returns list of maps with: name, quantity, weight, weightUnit
  List<Map<String, dynamic>> _getAvailableFragmentItems(dynamic gemstone) {
    final items = <Map<String, dynamic>>[];

    gemstone.breakdownItems!.forEach((fragmentName, itemData) {
      final data = itemData as Map<String, dynamic>?;
      if (data == null) return;

      // Extract values from the nested map (NEVER cast directly to int)
      final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
      final weight = (data['weight'] as num?)?.toDouble();
      final weightUnit = data['weightUnit'] as String?;

      // Only include items with quantity > 0
      if (quantity > 0) {
        items.add({
          'name': fragmentName,
          'quantity': quantity,
          'weight': weight,
          'weightUnit': weightUnit ?? 'kg',
        });
      }
    });

    return items;
  }
}
