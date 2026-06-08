import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LotPage extends StatelessWidget {
  const LotPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('LOT MANAGEMENT'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) {
          return _buildLotCard(context, index);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryAccent,
        onPressed: () {},
        label: const Text('အစုလိုက်ဝယ်ယူမှုအသစ်', style: TextStyle(color: AppTheme.primaryDark)),
        icon: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryDark),
      ),
    );
  }

  Widget _buildLotCard(BuildContext context, int index) {
    bool isSplit = index == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceLight, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LOT-2026-0${index + 1}',
                      style: const TextStyle(
                        color: AppTheme.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isSplit ? AppTheme.successColor : AppTheme.warningColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isSplit ? 'ခွဲထုတ်ပြီး (Split)' : 'အသစ် (Active)',
                        style: TextStyle(
                          color: isSplit ? AppTheme.successColor : AppTheme.warningColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildLotInfoItem(Icons.diamond, 'ကျောက်အရေအတွက်', '${(index + 1) * 10} လုံး'),
                    const SizedBox(width: 24),
                    _buildLotInfoItem(Icons.scale, 'စုစုပေါင်းအလေးချိန်', '${(index + 2) * 5.5} Carats'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ဝယ်ယူသည့်ဈေးနှုန်း:', style: TextStyle(color: AppTheme.textSecondary)),
                    Text(
                      '${(index + 1) * 25000000} MMK',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.surfaceLight),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.info_outline, size: 20),
                  label: const Text('အသေးစိတ်'),
                ),
                if (!isSplit)
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.call_split, size: 20, color: AppTheme.primaryDark),
                    label: const Text('တစ်လုံးချင်းခွဲထုတ်ရန်', style: TextStyle(color: AppTheme.primaryDark)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                if (isSplit)
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.view_list, size: 20),
                    label: const Text('ခွဲထားသောစာရင်း'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
