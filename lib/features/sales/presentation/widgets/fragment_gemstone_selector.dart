import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import 'inline_selector.dart';

/// Fragment Gemstone Selector - Step 1
/// Displays only gemstones that have fragment inventory
/// Does NOT show quantity, weight, or breakdown items
class FragmentGemstoneSelector extends StatelessWidget {
  final String? selectedGemstoneId;
  final ValueChanged<String?> onChanged;

  const FragmentGemstoneSelector({
    Key? key,
    required this.selectedGemstoneId,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get all gemstones with fragment inventory
    final gemsWithFragments = _getGemstonesWithFragments();

    if (gemsWithFragments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryAccent.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Center(
            child: Text(
              'အစိတ်စိတ်ပိုင်း ရွေးချယ်မှု မတ်ရိတ်မောရေ',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'ကျောက်အမည်',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InlineSelector<String>(
            value: selectedGemstoneId,
            hint: 'ကျောက်အမည် ရွေးချယ်မည်',
            borderColor: AppTheme.primaryAccent,
            backgroundColor: AppTheme.surfaceDark,
            style: const TextStyle(color: Colors.white),
            items: gemsWithFragments.map((gem) {
              return DropdownMenuItem<String>(
                value: gem.id,
                child: Text(
                  gem.name,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// Get all gemstones that have fragment inventory (breakdownItems with quantity > 0)
  List<dynamic> _getGemstonesWithFragments() {
    final gems = LocalDb.gemstones().values.toList();
    return gems.where((g) {
      if (g.breakdownItems == null || g.breakdownItems!.isEmpty) return false;
      // Check if any breakdown item has quantity > 0
      return g.breakdownItems!.values.any((item) {
        final itemData = item as Map<String, dynamic>?;
        if (itemData == null) return false;
        final quantity = (itemData['quantity'] as num?)?.toInt() ?? 0;
        return quantity > 0;
      });
    }).toList();
  }
}
