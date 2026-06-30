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
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('ပွဲစားအပ်စာရင်းများ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        actions: [
          // Add new broker button
          if (LocalDb.canCreateBrokerConsignment())
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/broker-consignment/form'),
              tooltip: 'အသစ်ထည့်သွင်းရန်',
            ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<BrokerConsignment>('brokerConsignments').listenable(),
        builder: (context, Box<BrokerConsignment> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.handshake_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'ပွဲစားအပ်စာရင်းမရှိသေးပါ',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Get all active broker consignments, sorted by newest first
          final brokers = box.values
              .where((b) => b.isActive)
              .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: brokers.length,
            itemBuilder: (context, index) {
              final bc = brokers[index];
              final purchase = LocalDb.getGemstone(bc.purchaseId);

              return Card(
                color: AppTheme.surfaceDark,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
                    child: const Icon(Icons.handshake, color: AppTheme.primaryAccent),
                  ),
                  title: Text(
                    bc.brokerName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ကျောက်: ${bc.historicalData.purchaseName} (${bc.historicalData.gemstoneType})',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      Text(
                        'အပ်ထားသော: ${bc.consignedQuantity.toInt()} • ရောင်းချ: ${bc.soldQuantity.toInt()} • ကျန်: ${bc.remainingQuantity.toInt()}',
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                      ),
                      Text(
                        'ရက်စွဲ: ${_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(bc.createdAt))}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) => _handleMenuAction(context, action, bc),
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('အသေးစိတ်ကြည့်ရှုရန်'),
                      ),
                      if (LocalDb.canUpdateBrokerConsignment())
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('ပြုပြင်ရန်'),
                        ),
                      if (LocalDb.canDeleteBrokerConsignment() && bc.soldQuantity == 0)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('ဖျက်ရန်'),
                        ),
                      if (LocalDb.canExportBrokerConsignment())
                        const PopupMenuItem(
                          value: 'export_pdf',
                          child: Text('PDF ထုတ်ရန်'),
                        ),
                    ],
                  ),
                  onTap: () => _handleMenuAction(context, 'view', bc),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, BrokerConsignment bc) {
    switch (action) {
      case 'view':
        context.push('/broker-consignment/detail/${bc.id}');
        break;
      case 'edit':
        if (LocalDb.canUpdateBrokerConsignment()) {
          context.push('/broker-consignment/form/${bc.id}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ဤလုပ်ဆောင်ချက်ကို Admin သာ ပြုလုပ်နိုင်ပါသည်။')),
          );
        }
        break;
      case 'delete':
        if (LocalDb.canDeleteBrokerConsignment()) {
          _showDeleteConfirmation(context, bc);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ဤလုပ်ဆောင်ချက်ကို Admin သာ ပြုလုပ်နိုင်ပါသည်။')),
          );
        }
        break;
      case 'export_pdf':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF ထုတ်ခြင်း လုပ်ဆောင်နေသည်...')),
        );
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, BrokerConsignment bc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ဖျက်ရန်အတည်ပြုခြင်း'),
        content: Text('${bc.brokerName} ၏ အပ်စာရင်းကို ဖျက်မည်ဆိုသည် သေချာပါသလား?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ပယ်ဖျက်ရန်'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await LocalDb.deleteBrokerConsignment(bc.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ဖျက်ခြင်းအောင်မြင်ပါသည်')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('အမှားအယွင်း: $e')),
                );
              }
            },
            child: const Text('ဖျက်ရန်'),
          ),
        ],
      ),
    );
  }
}
