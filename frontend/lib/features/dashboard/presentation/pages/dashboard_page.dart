import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gemstone_app/core/local/local_db.dart';
import 'package:gemstone_app/core/theme/app_theme.dart';
import 'package:gemstone_app/features/inventory/presentation/pages/inventory_page.dart';
import 'package:gemstone_app/features/sales/presentation/pages/sales_page.dart';
import 'package:gemstone_app/features/expenses/presentation/pages/expenses_page.dart';
import 'package:gemstone_app/features/workers/presentation/pages/workers_page.dart';
import 'package:gemstone_app/features/branches/presentation/pages/branches_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final NumberFormat _money;

  @override
  void initState() {
    super.initState();
    _money = NumberFormat('#,##0', 'my_MM');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('အဓိကစာမျက်နှာ'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Stats
              _buildStatsSection(),
              const SizedBox(height: 24),
              // Module Cards
              _buildModuleSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return ValueListenableBuilder(
      valueListenable: LocalDb.expenses().listenable(),
      builder: (context, __1, ___) {
        return ValueListenableBuilder(
          valueListenable: LocalDb.sales().listenable(),
          builder: (context, __2, ___) {
            return ValueListenableBuilder(
              valueListenable: LocalDb.gemstones().listenable(),
              builder: (context, __3, ____) {
                final sales = LocalDb.netRevenue(); // ပွဲခ နှုတ်ပြီး အသားတင် အရောင်းရငွေ
                final originalCapital = LocalDb.totalOriginalCapital(); // မူလစုစုပေါင်းအရင်း (fixed)
                final commissions = LocalDb.totalSalesCommission();
                final expenses = LocalDb.totalExpenses();
                final displayProfit = LocalDb.netProfit(); // အရင်းကျေမှ +စိမ်း
                final remainingCapital = LocalDb.remainingCapital(); // ကျန်အရင်း (အနှုတ်မရှိ)
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _statCard('စုစုပေါင်း အရောင်း',
                                _money.format(sales), AppTheme.successColor,
                                Icons.trending_up)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _statCard('မူလစုစုပေါင်းအရင်း',
                                _money.format(originalCapital), AppTheme.errorColor,
                                Icons.shopping_bag)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _statCard('ပွဲခ စုစုပေါင်း',
                                _money.format(commissions), AppTheme.errorColor,
                                Icons.money_off)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _statCard('အသုံးစရိတ်',
                                _money.format(expenses), AppTheme.errorColor,
                                Icons.trending_down)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _statCard('အသားတင်အမြတ်',
                                _money.format(displayProfit),
                                displayProfit > 0
                                    ? AppTheme.primaryAccent
                                    : Colors.grey,
                                Icons.account_balance_wallet)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _statCard(
                                'ကျန်ရှိသော လက်ကျန်အရင်း',
                                _money.format(remainingCapital),
                                remainingCapital > 0 ? Colors.green : Colors.grey,
                                Icons.savings)),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          Text('ကျပ်', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
        ],
      ),
    );
  }

  Widget _moduleCard(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 32),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('အဓိကလုပ်ဆောင်ချက်များ',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _moduleCard(Icons.diamond, 'ပစ္စည်းများ', 'စာရင်းကိုင်တွယ်ခြင်း',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const InventoryPage()))),
            _moduleCard(Icons.shopping_cart, 'အရောင်းများ', 'အရောင်းစာရင်း',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SalesPage()))),
            _moduleCard(Icons.receipt, 'အသုံးစရိတ်များ', 'အသုံးစရိတ်စာရင်း',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExpensesPage()))),
            _moduleCard(Icons.people, 'အလုပ်သမားများ', 'အလုပ်သမားစာရင်း',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WorkersPage()))),
            _moduleCard(Icons.location_city, 'ခွဲခြင်းများ', 'ခွဲခြင်းစာရင်း',
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BranchesPage()))),
          ],
        ),
      ],
    );
  }
}
