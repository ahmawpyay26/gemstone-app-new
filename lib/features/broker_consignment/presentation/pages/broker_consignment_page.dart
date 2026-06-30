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
  final _date = DateFormat('yyyy-MM-dd');

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
      ),
      body: ValueListenableBuilder(
        valueListenable: LocalDb.brokerConsignments().listenable(),
        builder: (context, Box<BrokerConsignment> box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.handshake_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('ပွဲစားအပ်စာရင်းမရှိသေးပါ',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: box.keys.length,
            itemBuilder: (context, i) {
              final keys = box.keys.toList().reversed.toList();
              final key = keys[i];
              final bc = box.get(key);
              
              if (bc == null) return const SizedBox.shrink();

              return Card(
                color: AppTheme.surfaceDark,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
                    child: const Icon(Icons.handshake, color: AppTheme.primaryAccent),
                  ),
                  title: Text(bc.brokerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('အပ်ထားသော: ${bc.consignedQuantity.toInt()} • ရောင်းချ: ${(bc.soldQuantity ?? 0).toInt()} • ကျန်: ${bc.remainingQuantity.toInt()}',
                        style: TextStyle(color: Colors.grey[400])),
                      Text(bc.historicalData.gemstoneType, style: TextStyle(color: Colors.grey[400])),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
