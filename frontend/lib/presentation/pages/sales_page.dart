import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('SALES & TRANSACTIONS'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return _buildSaleCard(context, index);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryAccent,
        onPressed: () {},
        label: const Text('အရောင်းအသစ်မှတ်ရန်', style: TextStyle(color: AppTheme.primaryDark)),
        icon: const Icon(Icons.point_of_sale, color: AppTheme.primaryDark),
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INV-2026-00${index + 1}',
                      style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold),
                    ),
                    const Text('27 May 2026', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Paid',
                    style: TextStyle(color: AppTheme.successColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.surfaceLight),
          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSaleItemRow('Ruby - 2.45ct (Red)', '၈,၅၀၀,၀၀၀ MMK'),
                const SizedBox(height: 8),
                _buildSaleItemRow('Sapphire - 1.2ct (Blue)', '၄,၀၀၀,၀၀၀ MMK'),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.surfaceLight, indent: 0, endIndent: 0),
                const SizedBox(height: 16),
                _buildSaleItemRow('စုစုပေါင်း အရောင်း', '၁၂,၅၀၀,၀၀၀ MMK', isBold: true),
                _buildSaleItemRow('ပွဲစားခ (Broker Commission)', '၆၂၅,၀၀၀ MMK', color: AppTheme.errorColor),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ဝယ်သူအမည်:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    Text('ဦးစိုးဝင်း (ရန်ကုန်)', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          // Footer Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share, size: 18, color: AppTheme.primaryAccent),
                  label: const Text('Share', style: TextStyle(color: AppTheme.primaryAccent)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print, size: 18, color: AppTheme.primaryAccent),
                  label: const Text('Print', style: TextStyle(color: AppTheme.primaryAccent)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleItemRow(String label, String amount, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: color ?? (isBold ? AppTheme.primaryAccent : AppTheme.textPrimary),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
