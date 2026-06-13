import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _money = NumberFormat('#,##0', 'en_US');

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('ထွက်ခွာခြင်း'),
        content: const Text('အကောင့်မှ ထွက်ခွာလိုပါသလား။'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('မလုပ်တော့ပါ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ထွက်မည်',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      LocalDb.logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = LocalDb.currentUser();
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('ကျောက်မျက် စီမံခန့်ခွဲမှု'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'ဆက်တင်',
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ထွက်ရန်',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box(LocalDb.sessionBox).listenable(),
        builder: (context, _, __) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryAccent.withOpacity(0.25),
                        AppTheme.surfaceDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ကြိုဆိုပါသည်',
                          style: TextStyle(color: Colors.grey[300])),
                      const SizedBox(height: 4),
                      Text(
                        user['name'] ?? 'Admin',
                        style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(user['email'] ?? '',
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stat cards (live)
                _buildStats(),
                const SizedBox(height: 24),

                Text('အဓိက လုပ်ဆောင်ချက်များ',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                  children: [
                    _moduleCard(Icons.diamond, 'ပစ္စည်းစာရင်း',
                        'ကျောက်မျက် စာရင်း', () => context.go('/inventory')),
                    _moduleCard(Icons.shopping_cart, 'ရောင်းချမှု',
                        'အရောင်း မှတ်တမ်း', () => context.go('/sales')),
                    _moduleCard(Icons.receipt_long, 'အသုံးစရိတ်',
                        'ကုန်ကျစရိတ်', () => context.go('/expenses')),
                    _moduleCard(Icons.people, 'အလုပ်သမား',
                        'ဝန်ထမ်း စီမံ', () => context.go('/workers')),
                    _moduleCard(Icons.store, 'ဆိုင်ခွဲ', 'ဆိုင်ခွဲ အချက်အလက်',
                        () => context.go('/branches')),
                    _moduleCard(Icons.bar_chart, 'အစီရင်ခံစာ',
                        'စာရင်းချုပ်', () => context.go('/reports')),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStats() {
    // Rebuild whenever any data box changes.
    return ValueListenableBuilder(
      valueListenable: LocalDb.sales().listenable(),
      builder: (context, _, __) {
        return ValueListenableBuilder(
          valueListenable: LocalDb.expenses().listenable(),
          builder: (context, __2, ___) {
            return ValueListenableBuilder(
              valueListenable: LocalDb.gemstones().listenable(),
              builder: (context, __3, ____) {
                final sales = LocalDb.totalSales();
                final capitalInvested = LocalDb.totalCapitalInvested();
                final commissions = LocalDb.totalSalesCommission();
                final expenses = LocalDb.totalExpenses();
                final profit = LocalDb.netProfit();
                final invCostTotal = LocalDb.inventoryCostTotal() +
                    LocalDb.inventoryExtraCostTotal();
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
                                _money.format(capitalInvested), AppTheme.errorColor,
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
                                _money.format(profit),
                                profit >= 0
                                    ? AppTheme.primaryAccent
                                    : AppTheme.errorColor,
                                Icons.account_balance_wallet)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _statCard(
                                'ပစ္စည်း ကုန်ကျစရိတ်',
                                _money.format(invCostTotal),
                                Colors.orangeAccent,
                                Icons.inventory_2)),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: AppTheme.primaryAccent),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
