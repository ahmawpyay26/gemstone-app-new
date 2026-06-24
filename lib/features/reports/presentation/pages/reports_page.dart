import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';

class ReportsPage extends StatelessWidget {
  ReportsPage({Key? key}) : super(key: key);

  final _money = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('အစီရင်ခံစာ'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/dashboard')),
      ),
      body: ValueListenableBuilder(
        valueListenable: LocalDb.sales().listenable(),
        builder: (context, _, __) {
          return ValueListenableBuilder(
            valueListenable: LocalDb.expenses().listenable(),
            builder: (context, ___, ____) {
              return ValueListenableBuilder(
                valueListenable: LocalDb.gemstones().listenable(),
                builder: (context, _____, ______) {
                  return ValueListenableBuilder(
                    valueListenable: LocalDb.workers().listenable(),
                    builder: (context, _______, ________) {
                      final totalCommission = LocalDb.totalSalesCommission();
                      final sales = LocalDb.totalSales() - totalCommission; // Deduct commission
                      final expenses = LocalDb.totalExpenses();
                      final cogs = LocalDb.totalCostOfGoodsSold();
                      final grossProfit = LocalDb.grossProfit();
                      final netProfit = LocalDb.netProfit();
                      final profit = netProfit;
                      final invValue = LocalDb.inventoryValue();
                      final invCount = LocalDb.inventoryCount();
                      final salary = LocalDb.totalSalary();
                      final activeWorkers = LocalDb.activeWorkers();
                      final salesCount = LocalDb.sales().length;
                      final expenseCount = LocalDb.expenses().length;
                      final invCost = LocalDb.inventoryCostTotal();
                      final invCommission =
                          LocalDb.inventoryCommissionTotal();
                      final invProcessing =
                          LocalDb.inventoryProcessingTotal();
                      final invRepair = LocalDb.inventoryRepairTotal();
                      final invBreakage = LocalDb.inventoryBreakageTotal();
                      final invBlood = LocalDb.inventoryBloodTotal();
                      final invLabor = LocalDb.inventoryLaborTotal();
                      final invMisc = LocalDb.inventoryMiscTotal();
                      final invExtraCost = LocalDb.inventoryExtraCostTotal();
                      final invGrandTotal = invCost + invExtraCost;

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _section('ဘဏ္ဍာရေး အကျဉ်းချုပ်'),
                          _bigCard(
                            'အသားတင် အမြတ်/အရှုံး (အဆုံးသတ်)',
                            '${_money.format(profit)} ကျပ်',
                            profit >= 0
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            profit >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                                child: _miniCard(
                                    'အရောင်း (ရောင်းရငွေ)',
                                    _money.format(sales),
                                    AppTheme.successColor)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _miniCard(
                                    'အရင်း (COGS)',
                                    _money.format(cogs),
                                    Colors.orangeAccent)),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                                child: _miniCard(
                                    'ကုန်သည်အမြတ် (အရင်းနုတ်)',
                                    _money.format(grossProfit),
                                    grossProfit >= 0
                                        ? AppTheme.primaryAccent
                                        : AppTheme.errorColor)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _miniCard(
                                    'အသုံးစရိတ်',
                                    _money.format(expenses),
                                    AppTheme.errorColor)),
                          ]),
                          const SizedBox(height: 20),
                          _section('ပစ္စည်းစာရင်း'),
                          _row('ကျောက်မျက် အရေအတွက်', '$invCount ခု'),
                          if (invValue > 0)
                            _row('ရောင်းဆေး စုစုပေါင်း',
                                '${_money.format(invValue)} ကျပ်'),
                          const SizedBox(height: 20),
                          _section('ပစ္စည်း ကုန်ကျစရိတ် အကျဥ်းချုပ်'),
                          _bigCard(
                            'စုစုပေါင်း အရင်းအနှီး (ဝယ်ဈေး + ကုန်ကျစရိတ်)',
                            '${_money.format(invGrandTotal)} ကျပ်',
                            AppTheme.primaryAccent,
                            Icons.account_balance_wallet,
                          ),
                          const SizedBox(height: 12),
                          _row('ဝယ်ဈေး (အရင်း)',
                              '${_money.format(invCost)} ကျပ်'),
                          _row('ပွဲခ',
                              '${_money.format(invCommission)} ကျပ်'),
                          _row('ဆီဖိုး',
                              '${_money.format(invProcessing)} ကျပ်'),
                          _row('ပြုပြင်ခ',
                              '${_money.format(invRepair)} ကျပ်'),
                          _row('ဖျက်ခ',
                              '${_money.format(invBreakage)} ကျပ်'),
                          _row('သွေးခ',
                              '${_money.format(invBlood)} ကျပ်'),
                          _row('အလုပ်သမားခ',
                              '${_money.format(invLabor)} ကျပ်'),
                          _row('အထွေထွေ',
                              '${_money.format(invMisc)} ကျပ်'),
                          const SizedBox(height: 20),
                          _section('လုပ်ငန်းဆောင်ရွက်မှု'),
                          _row('အရောင်း မှတ်တမ်း', '$salesCount ကြိမ်'),
                          _row('အသုံးစရိတ် မှတ်တမ်း', '$expenseCount ကြိမ်'),
                          const SizedBox(height: 20),
                          _section('ဝန်ထမ်း'),
                          _row('အလုပ်ဆင်း ဝန်ထမ်း', '$activeWorkers ဦး'),
                          _row('လစာ စုစုပေါင်း',
                              '${_money.format(salary)} ကျပ်'),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: AppTheme.primaryAccent, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ဤအစီရင်ခံစာသည် device အတွင်းရှိ data များမှ တိုက်ရိုက်တွက်ချက်ထားသည်။ အင်တာနက် မလိုအပ်ပါ။',
                                    style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      );

  Widget _bigCard(String label, String value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[300])),
                  const SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _miniCard(String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[300])),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
