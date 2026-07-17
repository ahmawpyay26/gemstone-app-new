import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../../../shared/widgets/photo_viewer.dart';
import '../widgets/voucher_group_widgets.dart';
import 'dart:developer' as developer;

class BrokerConsignmentPage extends StatefulWidget {
  const BrokerConsignmentPage({Key? key}) : super(key: key);

  @override
  State<BrokerConsignmentPage> createState() => _BrokerConsignmentPageState();
}

class _BrokerConsignmentPageState extends State<BrokerConsignmentPage> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat('#,##0.00', 'en_US');
  
  // Task 5: Filtering
  String _selectedFilter = 'အားလုံး';
  
  // Step 9: Returned quantity tracking
  final Map<String, TextEditingController> _returnedQtyControllers = {};
  final Map<String, String?> _returnedQtyErrors = {};
  final Map<String, int> _restoreDialogRebuildCount = {}; // Track dialog rebuilds

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
      return 'ပြီးစီး';
    } else if (bc.returnedQuantity > 0) {
      return 'တစ်စိတ်တစ်ပိုင်း ပြန်လည်အပ်';
    } else {
      return 'လုပ်ဆောင်ဆဲ';
    }
  }

  bool _matchesFilter(BrokerConsignment bc) {
    if (_selectedFilter == 'အားလုံး') return true;
    return _getStatusKey(bc) == _selectedFilter;
  }

  void _showDeleteConfirmation(BrokerConsignment bc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ပွဲစားအပ်စာရင်း ဖျက်ရန်'),
        content: Text('"${bc.brokerName}" ၏ ပွဲစားအပ်စာရင်းကို ဖျက်မည်ဖြစ်ပါသည်။\nဤလုပ်ဆောင်ချက်ကို ပြန်လည်ပြင်ဆင်၍ မရပါ။'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ပယ်ဖျက်ရန်'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await LocalDb.deleteBrokerConsignment(bc.id);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ပွဲစားအပ်စာရင်း ဖျက်ပြီးပါပြီ။')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('အမှားအယွင်း: $e')),
                  );
                }
              }
            },
            child: const Text('ဖျက်ရန်', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
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

          // Phase C.3: Get all active broker consignments
          final allBrokers = box.values
              .where((b) => b.isActive)
              .toList();

          // Phase C.3: Filter items first, then group by voucherId
          final filteredBrokers = allBrokers.where((b) => _matchesFilter(b)).toList();
          final groupedVouchers = LocalDb.getGroupedBrokerConsignments();
          
          // Phase C.3: Filter groups: keep only groups that have at least one matching item
          final filteredGroups = groupedVouchers.entries
              .where((entry) => entry.value.any((item) => filteredBrokers.contains(item)))
              .toList();

          // Calculate totals from FILTERED brokers
          // totalRecords = distinct vouchers (voucherId or legacy record)
          final voucherIds = filteredBrokers
              .map((b) => b.voucherId ?? b.id) // Use voucherId or id for legacy
              .toSet();
          final totalRecords = voucherIds.length;
          
          // totalDifferentGemstones = count of distinct gemstone items
          final totalDifferentGemstones = filteredBrokers.length;
          // CRITICAL: Use filteredBrokers to respect the current filter (All/Active/Completed/Partial Return)
          final totalConsigned = filteredBrokers.fold<double>(0, (sum, bc) => sum + bc.consignedQuantity);
          final totalSold = filteredBrokers.fold<double>(0, (sum, bc) => sum + bc.soldQuantity);
          final totalRemaining = filteredBrokers.fold<double>(0, (sum, bc) => sum + bc.remainingQuantity);
          final totalReturned = filteredBrokers.fold<double>(0, (sum, bc) => sum + bc.returnedQuantity);

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredGroups.length + 2,
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
                        _buildFilterChip('အားလုံး', 'အားလုံး'),
                        const SizedBox(width: 8),
                        _buildFilterChip('လုပ်ဆောင်ဆဲ', 'လုပ်ဆောင်ဆဲ'),
                        const SizedBox(width: 8),
                        _buildFilterChip('ပြီးစီး', 'ပြီးစီး'),
                        const SizedBox(width: 8),
                        _buildFilterChip('တစ်စိတ်တစ်ပိုင်း ပြန်လည်အပ်', 'တစ်စိတ်တစ်ပိုင်း ပြန်လည်အပ်'),
                      ],
                    ),
                  ),
                );
              }

              // Phase C.3: Render grouped voucher card
              final groupEntry = filteredGroups[index - 2];
              final groupKey = groupEntry.key;
              final items = groupEntry.value;
              final summary = LocalDb.getVoucherSummary(groupKey);
              final isLegacy = LocalDb.isLegacyGroup(groupKey);

              // Initialize controllers for all items in this group
              for (final item in items) {
                if (!_returnedQtyControllers.containsKey(item.id)) {
                  _returnedQtyControllers[item.id] = TextEditingController();
                  _returnedQtyErrors[item.id] = null;
                }
              }

              return VoucherGroupCard(
                groupKey: groupKey,
                items: items,
                summary: summary,
                isLegacy: isLegacy,
                // Item-level callbacks
                onViewPhotos: (item) {
                  if (item.photoPaths.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ဓာတ်ပုံ မရှိသေးပါ။')),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PhotoViewer(
                          photoUrls: item.photoPaths,
                        ),
                      ),
                    );
                  }
                },
                onEdit: (item) async {
                  final result = await context.push('/broker-consignment/form', extra: item);
                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
                onDelete: (item) => _showDeleteConfirmation(item),
                onReturn: (item) {
                  developer.log('[RESTORE-DIALOG-OPEN] item.id=${item.id} | remainingQty=${item.remainingQuantity}');
                  
                  // Show return dialog with quantity input
                  showDialog(
                    context: context,
                    builder: (context) {
                      // Capture item in local scope for the dialog
                      final brokerItem = item;
                      developer.log('[RESTORE-DIALOG-BUILD] brokerItem.id=${brokerItem.id}');
                      
                      return AlertDialog(
                        title: const Text('ပြန်လည်လက်ခံရန်'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('လက်ကျန်အရေအတွက်: ${brokerItem.remainingQuantity.toStringAsFixed(0)}'),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _returnedQtyControllers[brokerItem.id],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'အရေအတွက်ထည့်သွင်းရန်',
                                errorText: _returnedQtyErrors[brokerItem.id],
                              ),
                              onChanged: (value) {
                                final controller = _returnedQtyControllers[brokerItem.id];
                                final error = _returnedQtyErrors[brokerItem.id];
                                final canRestore = controller != null &&
                                    controller.text.trim().isNotEmpty &&
                                    error == null;
                                
                                developer.log(
                                  '[RESTORE-ONCHANGED-BEFORE] brokerItem.id=${brokerItem.id} | enteredValue=$value | controller=${controller != null ? "EXISTS" : "NULL"} | controller.text="${controller?.text ?? "NULL"}" | text.isNotEmpty=${controller?.text.isNotEmpty ?? false} | text.trim().isNotEmpty=${controller?.text.trim().isNotEmpty ?? false} | error=$error | remainingQty=${brokerItem.remainingQuantity} | canRestore=$canRestore',
                                  level: 1000,
                                );
                                
                                setState(() {
                                  _validateReturnedQuantity(brokerItem, value);
                                  
                                  final errorAfter = _returnedQtyErrors[brokerItem.id];
                                  final canRestoreAfter = controller != null &&
                                      controller.text.trim().isNotEmpty &&
                                      errorAfter == null;
                                  
                                  developer.log(
                                    '[RESTORE-ONCHANGED-AFTER] brokerItem.id=${brokerItem.id} | enteredValue=$value | errorAfter=$errorAfter | canRestoreAfter=$canRestoreAfter',
                                    level: 1000,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('ပယ်ဖျက်ရန်'),
                          ),
                          Builder(
                            builder: (buttonContext) {
                              final controller = _returnedQtyControllers[brokerItem.id];
                              final error = _returnedQtyErrors[brokerItem.id];
                              final canRestore = controller != null &&
                                  controller.text.trim().isNotEmpty &&
                                  error == null;
                              
                              developer.log(
                                '[RESTORE-BUTTON-BUILD] brokerItem.id=${brokerItem.id} | controller=${controller != null ? "EXISTS" : "NULL"} | controller.text="${controller?.text ?? "NULL"}" | text.isNotEmpty=${controller?.text.isNotEmpty ?? false} | text.trim().isNotEmpty=${controller?.text.trim().isNotEmpty ?? false} | error=$error | canRestore=$canRestore',
                                level: 1000,
                              );
                              
                              return TextButton(
                                onPressed: canRestore
                                    ? () {
                                        developer.log('[RESTORE-BUTTON-PRESSED] brokerItem.id=${brokerItem.id}');
                                        Navigator.pop(context);
                                        _processReturn(brokerItem);
                                      }
                                    : null,
                                child: const Text('လက်ခံရန်'),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('ပယ်ဖျက်ရန်'),
                        ),
                        TextButton(
                          onPressed: _returnedQtyErrors[item.id] == null && (_returnedQtyControllers[item.id]?.text.isNotEmpty ?? false)
                              ? () {
                                  Navigator.pop(context);
                                  _processReturn(item);
                                }
                              : null,
                          child: const Text('လက်ခံရန်'),
                        ),
                      ],
                    ),
                  );
                },
                onSale: (item) async {
                  final result = await context.push('/broker-consignment/${item.id}');
                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
                // Voucher-level callbacks
                onViewAllPhotos: () {
                  final allPhotos = <String>[];
                  for (final item in items) {
                    allPhotos.addAll(item.photoPaths);
                  }
                  if (allPhotos.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ဓာတ်ပုံ မရှိသေးပါ။')),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PhotoViewer(
                          photoUrls: allPhotos,
                        ),
                      ),
                    );
                  }
                },
                onPrint: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ပရင့်ထုတ်ရန် လုပ်ဆောင်ချက် မပြီးသေးပါ။')),
                  );
                },
                onExport: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF ထုတ်ရန် လုပ်ဆောင်ချက် မပြီးသေးပါ။')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
