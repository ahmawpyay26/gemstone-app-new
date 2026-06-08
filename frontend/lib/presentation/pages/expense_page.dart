import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ExpensePage extends StatelessWidget {
  const ExpensePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('EXPENSE TRACKING'),
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'ယခုလ စုစုပေါင်း ကုန်ကျစရိတ်',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '၄,၅၀၀,၀၀၀ MMK',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppTheme.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('လုပ်သားခ', '၂,၀၀၀,၀၀၀'),
                    _buildStatItem('စက်ပစ္စည်း', '၁,၅၀၀,၀၀၀'),
                    _buildStatItem('အထွေထွေ', '၁,၀၀၀,၀၀၀'),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Expense List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 8,
              itemBuilder: (context, index) {
                return _buildExpenseTile(context, index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryAccent,
        onPressed: () {},
        label: const Text('စရိတ်အသစ်ထည့်ရန်', style: TextStyle(color: AppTheme.primaryDark)),
        icon: const Icon(Icons.add, color: AppTheme.primaryDark),
      ),
    );
  }

  Widget _buildStatItem(String label, String amount) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(amount, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildExpenseTile(BuildContext context, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              index % 2 == 0 ? Icons.engineering : Icons.build,
              color: AppTheme.primaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  index % 2 == 0 ? 'လုပ်သားခ - ဦးမောင်မောင်' : 'စက်ဆီနှင့် အရောင်တင်မှုန့်',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '24 May 2026 • Ruby-004 အတွက်',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${(index + 1) * 50000} MMK',
            style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
