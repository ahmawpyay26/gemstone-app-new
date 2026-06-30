import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

class BrokerConsignmentPage extends StatefulWidget {
  const BrokerConsignmentPage({Key? key}) : super(key: key);

  @override
  State<BrokerConsignmentPage> createState() => _BrokerConsignmentPageState();
}

class _BrokerConsignmentPageState extends State<BrokerConsignmentPage> {
  final _money = NumberFormat('#,##0', 'en_US');
  final _date = DateFormat('yyyy-MM-dd');

  Future<void> _delete(dynamic key) async {
    // Check admin permission
    if (!LocalDb.canDeleteBrokerConsignment()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalDb.adminOnlyErrorMessage()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    final consignment = LocalDb.brokerConsignments().get(key);
    final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('ပွဲစားအပ်စာရင်း ဖျက်မည်'),
            content: const Text(
                'ဤပွဲစားအပ်စာရင်းကို ဖျက်မှာ သေချာပါသလား?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('မဖျက်တော့ပါ')),
              TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('ဖျက်မည်',
                      style: TextStyle(color: AppTheme.errorColor))),
            ],
          ),
        ) ??
        false;
    if (ok && consignment != null) {
      try {
        await LocalDb.deleteBrokerConsignment(key);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ပွဲစားအပ်စာရင်း ဖျက်ပြီးပါပြီ')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('အမှားအယွင်း: $e')),
          );
        }
      }
    }
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handshake_outlined,
              size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('ပွဲစားအပ်စာရင်းမရှိသေးပါ',
              style: TextStyle(color: Colors.grey[400], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('ပွဲစားအပ်စာရင်းများ'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/dashboard')),
      ),
      floatingActionButton: LocalDb.canCreateBrokerConsignment()
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryAccent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text('အပ်စာရင်းအသစ်'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ပွဲစားအပ်စာရင်း ဖန်တီးမှု - လာမည့်ကာလတွင်ပြီးမည်'),
                    backgroundColor: AppTheme.primaryAccent,
                  ),
                );
              },
            )
          : null,
      body: ValueListenableBuilder(
        valueListenable: LocalDb.brokerConsignments().listenable(),
        builder: (context, Box<BrokerConsignment> box, _) {
          final totalConsigned = LocalDb.brokerConsignments()
              .values
              .fold<int>(0, (sum, bc) => sum + (bc.consignedQuantity ?? 0));
          final totalSold = LocalDb.brokerConsignments()
              .values
              .fold<int>(0, (sum, bc) => sum + (bc.soldQuantity ?? 0));
          final totalRemaining = LocalDb.brokerConsignments()
              .values
              .fold<int>(0, (sum, bc) => sum + (bc.remainingQuantity ?? 0));

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _summaryCard(
                      'စုစုပေါင်း အပ်ထားသော',
                      '$totalConsigned ခု',
                      AppTheme.primaryAccent,
                    ),
                    _summaryCard(
                      'စုစုပေါင်း ရောင်းချ',
                      '$totalSold ခု',
                      AppTheme.successColor,
                    ),
                    _summaryCard(
                      'ကျန်ရှိသော',
                      '$totalRemaining ခု',
                      Colors.orange,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: box.isEmpty
                    ? _empty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                        itemCount: box.keys.length,
                        itemBuilder: (context, i) {
                          final keys = box.keys.toList().reversed.toList();
                          final key = keys[i];
                          final bc = box.get(key)!;

                          return Card(
                            color: AppTheme.surfaceDark,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              children: [
                                // Date box at the top
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryAccent.withOpacity(0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                        size: 16,
                                        color: AppTheme.primaryAccent,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _date.format(DateTime.fromMillisecondsSinceEpoch(bc.createdDate)),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppTheme.primaryAccent.withOpacity(0.2),
                                    child: const Icon(Icons.handshake,
                                        color: AppTheme.primaryAccent),
                                  ),
                                  title: Text(bc.brokerName ?? 'Unknown Broker',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'အပ်ထားသော: ${bc.consignedQuantity} • ရောင်းချ: ${bc.soldQuantity} • ကျန်: ${bc.remainingQuantity}',
                                          style:
                                              TextStyle(color: Colors.grey[400])),
                                      Text(bc.gemstoneName ?? 'Unknown Gemstone',
                                          style:
                                              TextStyle(color: Colors.grey[400])),
                                      Text(
                                          _date.format(DateTime.fromMillisecondsSinceEpoch(bc.createdDate)),
                                          style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12)),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    constraints: BoxConstraints(maxHeight: 200),
                                    icon: Icon(Icons.more_vert,
                                        color: LocalDb.canEditBrokerConsignment() ? Colors.white : Colors.grey[600]),
                                    enabled: LocalDb.canEditBrokerConsignment(),
                                    onSelected: (v) {
                                      if (v == 'delete') _delete(key);
                                      if (v == 'view') {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('အသေးစိတ်ကြည့်ရှုမှု - လာမည့်ကာလတွင်ပြီးမည်'),
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                          value: 'view',
                                          child: const Row(
                                            children: [
                                              Text('👁️'),
                                              SizedBox(width: 8),
                                              Text('အသေးစိတ်'),
                                            ],
                                          )),
                                      PopupMenuItem(
                                          value: 'delete',
                                          enabled: LocalDb.canDeleteBrokerConsignment(),
                                          child: const Row(
                                            children: [
                                              Text('🗑️'),
                                              SizedBox(width: 8),
                                              Text('ဖျက်ရန်',
                                                  style: TextStyle(
                                                      color: AppTheme.errorColor)),
                                            ],
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
