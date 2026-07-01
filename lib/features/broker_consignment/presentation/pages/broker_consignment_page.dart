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
  final _currencyFormat = NumberFormat('#,##0.00', 'en_US');
  
  // Task 5: Filtering
  String _selectedFilter = 'All';
  
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

  String _getStatusKey(BrokerConsignment bc) {
    if (bc.remainingQuantity == 0) {
      return 'Completed';
    } else if (bc.returnedQuantity > 0) {
      return 'Partial Return';
    } else {
      return 'Active';
    }
  }

  bool _matchesFilter(BrokerConsignment bc) {
    if (_selectedFilter == 'All') return true;
    return _getStatusKey(bc) == _selectedFilter;
  }

  Widget _buildSummaryItem(String label, String value, {bool isSmall = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: isSmall ? 11 : 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.primaryAccent,
              fontSize: isSmall ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAccent : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryAccent : Colors.grey[700]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
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
          final allBrokers = box.values
              .where((b) => b.isActive)
              .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Filter brokers based on selected filter
          final brokers = allBrokers.where((b) => _matchesFilter(b)).toList();

          // Calculate totals from ALL brokers (not filtered)
          final totalRecords = allBrokers.length;
          final totalDifferentGemstones = allBrokers.toSet().length;
          final totalConsigned = allBrokers.fold<double>(0, (sum, bc) => sum + bc.consignedQuantity);
          final totalSold = allBrokers.fold<double>(0, (sum, bc) => sum + bc.soldQuantity);
          final totalRemaining = allBrokers.fold<double>(0, (sum, bc) => sum + bc.remainingQuantity);
          final totalReturned = allBrokers.fold<double>(0, (sum, bc) => sum + bc.returnedQuantity);

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: brokers.length + 2,
            itemBuilder: (context, index) {
              // Summary dashboard at the top
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main summary cards
                      Container(
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
                            // First row: Records, Gemstones, Consigned
                            Row(
                              children: [
                                _buildSummaryItem('📦 စုစုပေါင်း\nပွဲစားအပ်မှတ်တမ်း', totalRecords.toString(), isSmall: true),
                                const SizedBox(width: 8),
                                _buildSummaryItem('💎 စုစုပေါင်း\nအပ်ထားသော ကျောက်', totalDifferentGemstones.toString(), isSmall: true),
                                const SizedBox(width: 8),
                                _buildSummaryItem('🔢 စုစုပေါင်း\nအပ်ထားသော အရေအတွက်', totalConsigned.toStringAsFixed(0), isSmall: true),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Second row: Sold, Returned, Remaining
                            Row(
                              children: [
                                _buildSummaryItem('💰 စုစုပေါင်း\nရောင်းပြီး', totalSold.toStringAsFixed(0), isSmall: true),
                                const SizedBox(width: 8),
                                _buildSummaryItem('📥 စုစုပေါင်း\nပြန်ရရှိပြီး', totalReturned.toStringAsFixed(0), isSmall: true),
                                const SizedBox(width: 8),
                                _buildSummaryItem('📦 ပွဲစားထံ\nကျန်ရှိ', totalRemaining.toStringAsFixed(0), isSmall: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Filter chips
              if (index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'All'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Active', 'Active'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Completed', 'Completed'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Partial Return', 'Partial Return'),
                      ],
                    ),
                  ),
                );
              }

              final bc = brokers[index - 2];
              
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
                            Row(
                              children: [
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
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Edit feature coming soon')),
                                      );
                                    } else if (value == 'delete') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Delete feature coming soon')),
                                      );
                                    } else if (value == 'print') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Print feature coming soon')),
                                      );
                                    } else if (value == 'export_image') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Export image feature coming soon')),
                                      );
                                    } else if (value == 'export_pdf') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Export PDF feature coming soon')),
                                      );
                                    } else if (value == 'photos') {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('View photos feature coming soon')),
                                      );
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Text('✏️'),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Text('🗑️'),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'print',
                                      child: Row(
                                        children: [
                                          Text('🖨️'),
                                          SizedBox(width: 8),
                                          Text('Print'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'export_image',
                                      child: Row(
                                        children: [
                                          Text('🖼️'),
                                          SizedBox(width: 8),
                                          Text('Export Image'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'export_pdf',
                                      child: Row(
                                        children: [
                                          Text('📄'),
                                          SizedBox(width: 8),
                                          Text('Export PDF'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'photos',
                                      child: Row(
                                        children: [
                                          Text('📷'),
                                          SizedBox(width: 8),
                                          Text('View Photos'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Task 5: Enhanced card details with all metrics
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'ကျောက်',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '1',
                                    style: const TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'အပ်ထား',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bc.consignedQuantity.toInt().toString(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'ရောင်းချ',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bc.soldQuantity.toInt().toString(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'ပြန်လည်',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bc.returnedQuantity.toInt().toString(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'ကျန်',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bc.remainingQuantity.toInt().toString(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontSize: 13,
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
