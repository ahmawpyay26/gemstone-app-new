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
  
  // Step 9: Returned quantity tracking
  final Map<String, TextEditingController> _returnedQtyControllers = {};
  final Map<String, String?> _returnedQtyErrors = {};

  @override
  void dispose() {
    for (var controller in _returnedQtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _validateReturnedQuantity(BrokerConsignment bc, String value) {
    if (value.isEmpty) {
      _returnedQtyErrors[bc.id] = null;
      return;
    }

    final quantity = int.tryParse(value);
    if (quantity == null || quantity <= 0) {
      _returnedQtyErrors[bc.id] = 'အရေအတွက်သည် ၀ထက်ကြီးရမည်ဖြစ်ပါသည်။';
      return;
    }

    if (quantity > bc.remainingQuantity) {
      _returnedQtyErrors[bc.id] = 'ပြန်လည်လက်ခံသော အရေအတွက်သည် ပွဲစားထံရှိ လက်ကျန်ထက် မများရပါ။';
      return;
    }

    _returnedQtyErrors[bc.id] = null;
  }

  Future<void> _processReturn(BrokerConsignment bc) async {
    final returnedQty = int.parse(_returnedQtyControllers[bc.id]?.text ?? '0');
    if (returnedQty <= 0) return;

    try {
      // Step 9: Restore inventory
      await LocalDb.processBrokerReturn(
        brokerConsignmentId: bc.id,
        returnedQuantity: returnedQty.toDouble(),
      );

      // Clear input
      _returnedQtyControllers[bc.id]?.clear();
      _returnedQtyErrors[bc.id] = null;

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ပြန်လည်လက်ခံမှု အောင်မြင်ပါသည်။')),
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

  String _getStatusBadge(BrokerConsignment bc) {
    if (bc.remainingQuantity == 0) {
      return 'အပြီးစီး';
    } else if (bc.returnedQuantity > 0) {
      return 'အခြေခံ ပြန်လည်လက်ခံ';
    } else {
      return 'လုပ်ဆောင်ခြင်းတွင်';
    }
  }

  Color _getStatusColor(BrokerConsignment bc) {
    if (bc.remainingQuantity == 0) {
      return Colors.green;
    } else if (bc.returnedQuantity > 0) {
      return Colors.orange;
    } else {
      return AppTheme.primaryAccent;
    }
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primaryAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/broker-consignment/form');
          if (result == true && mounted) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
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

          // Calculate totals
          final totalRecords = brokers.length;
          final totalPurchaseRecords = brokers.fold<int>(0, (sum, bc) => sum + 1); // Each broker has at least 1 record
          final totalConsigned = brokers.fold<double>(0, (sum, bc) => sum + bc.consignedQuantity);
          final totalRemaining = brokers.fold<double>(0, (sum, bc) => sum + bc.remainingQuantity);
          final totalReturned = brokers.fold<double>(0, (sum, bc) => sum + bc.returnedQuantity);

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: brokers.length + 1,
            itemBuilder: (context, index) {
              // Summary box at the top
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryAccent, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[900],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'စုစုပေါင်း ပွဲစားအပ်စာရင်း',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem('မှတ်တမ်း', totalRecords.toString()),
                            _buildSummaryItem('ကျောက်', totalPurchaseRecords.toString()),
                            _buildSummaryItem('အပ်ထား', totalConsigned.toStringAsFixed(0)),
                            _buildSummaryItem('ကျန်', totalRemaining.toStringAsFixed(0)),
                            _buildSummaryItem('ပြန်လည်', totalReturned.toStringAsFixed(0)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              final bc = brokers[index - 1];
              
              // Initialize controller if not exists
              if (!_returnedQtyControllers.containsKey(bc.id)) {
                _returnedQtyControllers[bc.id] = TextEditingController();
                _returnedQtyErrors[bc.id] = null;
              }

              final statusBadge = _getStatusBadge(bc);
              final statusColor = _getStatusColor(bc);

              return GestureDetector(
                onTap: () async {
                  // Task 3: Tap to open details page
                  final result = await context.push('/broker-consignment/${bc.id}');
                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
                child: Card(
                  color: AppTheme.surfaceDark,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
                                  child: const Icon(Icons.handshake, color: AppTheme.primaryAccent),
                                ),
                                title: Text(
                                  bc.brokerName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'ရက်စွဲ: ${_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(bc.createdAt))}',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                border: Border.all(color: statusColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusBadge,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Task 3: Enhanced card details
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'ကျောက်',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '1',
                                    style: const TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'အပ်ထား',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bc.consignedQuantity.toInt().toString(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'ကျန်',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bc.remainingQuantity.toInt().toString(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'ပြန်လည်',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bc.returnedQuantity.toInt().toString(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Step 9: Returned quantity input
                        if (bc.remainingQuantity > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ပြန်လည်လက်ခံသောအရေအတွက်',
                                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _returnedQtyControllers[bc.id],
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: '0',
                                          hintStyle: TextStyle(color: Colors.grey[600]),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.grey[700]!),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          errorText: _returnedQtyErrors[bc.id],
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _validateReturnedQuantity(bc, value);
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _returnedQtyErrors[bc.id] == null && (_returnedQtyControllers[bc.id]?.text.isNotEmpty ?? false)
                                          ? () => _processReturn(bc)
                                          : null,
                                      child: const Text('လက်ခံ'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
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
