import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Gemstone breakdown types
const List<String> gemstoneParts = [
  'ဖျက်စ',
  'လွာချက်',
  'လက်ကောက်',
  'လက်စွတ်',
  'ပုတီး',
  'ပန်းပု',
];

class GemstoneBreakdownWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onBreakdownChanged;
  final Map<String, dynamic>? initialBreakdown;
  final bool isForSale; // true for sales, false for purchase

  const GemstoneBreakdownWidget({
    Key? key,
    required this.onBreakdownChanged,
    this.initialBreakdown,
    this.isForSale = false,
  }) : super(key: key);

  @override
  State<GemstoneBreakdownWidget> createState() =>
      _GemstoneBreakdownWidgetState();
}

class _GemstoneBreakdownWidgetState extends State<GemstoneBreakdownWidget> {
  late Map<String, dynamic> breakdown;

  @override
  void initState() {
    super.initState();
    breakdown = widget.initialBreakdown ?? {};
    // Initialize all parts if not present
    for (var part in gemstoneParts) {
      if (!breakdown.containsKey(part)) {
        breakdown[part] = {
          'quantity': 0,
          if (widget.isForSale) 'price': 0,
        };
      }
    }
  }

  void _updateBreakdown(String part, String field, dynamic value) {
    setState(() {
      if (!breakdown.containsKey(part)) {
        breakdown[part] = {
          'quantity': 0,
          if (widget.isForSale) 'price': 0,
        };
      }
      breakdown[part][field] = value;
      widget.onBreakdownChanged(breakdown);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ကျောက်အစိတ်စိတ်ပိုင်း',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...gemstoneParts.map((part) {
            final data = breakdown[part] ?? {};
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      part,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'အရေ',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: AppTheme.primaryAccent.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: AppTheme.primaryAccent.withOpacity(0.3),
                          ),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      onChanged: (value) {
                        _updateBreakdown(
                          part,
                          'quantity',
                          int.tryParse(value) ?? 0,
                        );
                      },
                      controller: TextEditingController(
                        text: (data['quantity'] ?? 0).toString(),
                      ),
                    ),
                  ),
                  if (widget.isForSale) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'ဈေး',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: AppTheme.primaryAccent.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: AppTheme.primaryAccent.withOpacity(0.3),
                            ),
                          ),
                        ),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        onChanged: (value) {
                          _updateBreakdown(
                            part,
                            'price',
                            int.tryParse(value) ?? 0,
                          );
                        },
                        controller: TextEditingController(
                          text: (data['price'] ?? 0).toString(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
