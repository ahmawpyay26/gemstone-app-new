import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('REPORTS & ANALYTICS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ကာလအပိုင်းအခြား: ယခုလ', style: TextStyle(color: AppTheme.textPrimary)),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: AppTheme.primaryAccent, size: 20),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profit/Loss Chart Placeholder
            Text('အမြတ်/အရှုံး ပြရပ်', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.show_chart, color: AppTheme.primaryAccent, size: 64),
              ),
            ),
            const SizedBox(height: 24),

            // Report Categories
            _buildReportCategory(context, 'အရောင်းအစီရင်ခံစာ', Icons.assignment, 'Sales Summary'),
            _buildReportCategory(context, 'ကုန်ကျစရိတ်အစီရင်ခံစာ', Icons.pie_chart, 'Expense Breakdown'),
            _buildReportCategory(context, 'လက်ကျန်ကျောက်စာရင်း', Icons.inventory, 'Stock Valuation'),
            _buildReportCategory(context, 'ပွဲစားခပေးချေမှုများ', Icons.handshake, 'Broker Commissions'),
            _buildReportCategory(context, 'လုပ်သားစွမ်းဆောင်ရည်', Icons.engineering, 'Worker Performance'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCategory(BuildContext context, String title, IconData icon, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {},
        tileColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryAccent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      ),
    );
  }
}
