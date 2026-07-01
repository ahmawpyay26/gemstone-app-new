import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../../../core/theme/app_theme.dart';

/// Temporary model for consignment items during form editing
class ConsignmentItemTemp {
  String id;
  Gemstone? gemstone;
  double consignedQuantity;
  String sourceType; // 'whole_stone' or 'breakdown_item'
  Gemstone? selectedPurchase; // For breakdown_item source type
  String? selectedBreakdownItem; // Selected breakdown item name
  Map<String, int> availableBreakdownItems; // Filtered breakdown items from purchase

  ConsignmentItemTemp({
    required this.id,
    this.gemstone,
    this.consignedQuantity = 0,
    this.sourceType = 'whole_stone',
    this.selectedPurchase,
    this.selectedBreakdownItem,
    this.availableBreakdownItems = const {},
  });
}

class BrokerFormPage extends StatefulWidget {
  final String? brokerId;

  const BrokerFormPage({Key? key, this.brokerId}) : super(key: key);

  @override
  State<BrokerFormPage> createState() => _BrokerFormPageState();
}

class _BrokerFormPageState extends State<BrokerFormPage> {
  // Header fields
  late TextEditingController _brokerNameCtrl;
  late TextEditingController _brokerPhoneCtrl;
  late TextEditingController _brokerAddressCtrl;
  late TextEditingController _brokerSocialCtrl;
  late TextEditingController _notesCtrl;
  
  DateTime _consignmentDate = DateTime.now();
  late String _brokerConsignmentNumber;
  
  // Items list
  List<ConsignmentItemTemp> _items = [];
  List<Gemstone> _availableGemstones = [];
  
  final _date = DateFormat('dd/MM/yyyy');
  final _dateNum = DateFormat('yyyyMMdd');

  @override
  void initState() {
    super.initState();
    _brokerNameCtrl = TextEditingController();
    _brokerPhoneCtrl = TextEditingController();
    _brokerAddressCtrl = TextEditingController();
    _brokerSocialCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    
    _availableGemstones = LocalDb.gemstones().values.toList();
    _generateBrokerConsignmentNumber();
  }

  void _generateBrokerConsignmentNumber() {
    final dateStr = _dateNum.format(_consignmentDate);
    final randomSuffix = DateTime.now().millisecondsSinceEpoch % 10000;
    _brokerConsignmentNumber = 'BC-$dateStr-${randomSuffix.toString().padLeft(4, '0')}';
  }

  double _getTotalConsignmentQuantity() {
    return _items.fold<double>(0, (sum, item) => sum + item.consignedQuantity);
  }

  @override
  void dispose() {
    _brokerNameCtrl.dispose();
    _brokerPhoneCtrl.dispose();
    _brokerAddressCtrl.dispose();
    _brokerSocialCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _isHeaderValid() {
    return _brokerNameCtrl.text.isNotEmpty &&
        _brokerPhoneCtrl.text.isNotEmpty &&
        _brokerAddressCtrl.text.isNotEmpty;
  }

  bool _isFormValid() {
    if (!_isHeaderValid()) return false;
    if (_items.isEmpty) return false;
    
    // All items must have gemstone and quantity > 0
    for (final item in _items) {
      if (item.gemstone == null || item.consignedQuantity <= 0) {
        return false;
      }
      // For breakdown items, must select purchase and breakdown item
      if (item.sourceType == 'breakdown_item') {
        if (item.selectedPurchase == null || item.selectedBreakdownItem == null) {
          return false;
        }
        // Check quantity against breakdown item available quantity
        if (item.selectedBreakdownItem != null && item.availableBreakdownItems.containsKey(item.selectedBreakdownItem)) {
          final availableQty = item.availableBreakdownItems[item.selectedBreakdownItem]!;
          if (item.consignedQuantity > availableQty) {
            return false;
          }
        }
      } else {
        // For whole stone, check against gemstone remaining quantity
        if (item.consignedQuantity > item.gemstone!.remainingQuantity) {
          return false;
        }
      }
    }
    
    return true;
  }

  void _addItem() {
    setState(() {
      _items.add(ConsignmentItemTemp(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      ));
    });
  }

  void _removeItem(String itemId) {
    setState(() {
      _items.removeWhere((item) => item.id == itemId);
    });
  }

  void _updateItemGemstone(String itemId, Gemstone? gemstone) {
    setState(() {
      final item = _items.firstWhere((i) => i.id == itemId);
      item.gemstone = gemstone;
      // Reset quantity if gemstone changed
      item.consignedQuantity = 0;
    });
  }

  void _updateItemQuantity(String itemId, double quantity) {
    setState(() {
      final item = _items.firstWhere((i) => i.id == itemId);
      item.consignedQuantity = quantity;
    });
  }

  void _updateItemSourceType(String itemId, String sourceType) {
    setState(() {
      final item = _items.firstWhere((i) => i.id == itemId);
      item.sourceType = sourceType;
      item.consignedQuantity = 0;
      if (sourceType == 'whole_stone') {
        item.selectedPurchase = null;
        item.selectedBreakdownItem = null;
        item.availableBreakdownItems = {};
      }
    });
  }

  void _updateItemPurchase(String itemId, Gemstone? purchase) {
    setState(() {
      final item = _items.firstWhere((i) => i.id == itemId);
      item.selectedPurchase = purchase;
      item.selectedBreakdownItem = null;
      if (purchase != null && purchase.breakdownItems.isNotEmpty) {
        item.availableBreakdownItems = Map.from(purchase.breakdownItems);
        item.availableBreakdownItems.removeWhere((_, qty) => qty <= 0);
      } else {
        item.availableBreakdownItems = {};
      }
    });
  }

  void _updateItemBreakdownItem(String itemId, String? breakdownItemName) {
    setState(() {
      final item = _items.firstWhere((i) => i.id == itemId);
      item.selectedBreakdownItem = breakdownItemName;
      item.consignedQuantity = 0;
    });
  }

  Future<void> _saveBrokerConsignment() async {
    if (!_isFormValid()) return;

    try {
      // For now, save each item as a separate BrokerConsignment record
      // (backward compatible with existing model)
      // TODO: Refactor to use new multi-item model in future steps
      
      for (final item in _items) {
        if (item.gemstone == null) continue;
        
        await LocalDb.createBrokerConsignment(
          purchaseId: item.gemstone!.id,
          consignedQuantity: item.consignedQuantity,
          sourceType: item.sourceType,
          breakdownItemName: item.selectedBreakdownItem,
          brokerName: _brokerNameCtrl.text,
          brokerPhone: _brokerPhoneCtrl.text,
          brokerAddress: _brokerAddressCtrl.text,
          brokerSocialAccount: _brokerSocialCtrl.text.isEmpty ? null : _brokerSocialCtrl.text,
        );
      }

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('အမှားအယွင်း: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('ပွဲစားအပ်စာရင်း'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HEADER SECTION =====
            Text(
              'ပွဲစားအချက်အလက်',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Broker Consignment Number
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryAccent),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[900],
              ),
              child: Row(
                children: [
                  Icon(Icons.tag, color: AppTheme.primaryAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'အပ်စာရင်းအမှတ်',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        Text(
                          _brokerConsignmentNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Date picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _consignmentDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _consignmentDate = picked;
                    _generateBrokerConsignmentNumber();
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[900],
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppTheme.primaryAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _date.format(_consignmentDate),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Broker name
            TextField(
              controller: _brokerNameCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'ပွဲစားအမည် *',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryAccent),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            
            // Phone
            TextField(
              controller: _brokerPhoneCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'ဖုန်းနံပါတ် *',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryAccent),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            
            // Address
            TextField(
              controller: _brokerAddressCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'လိပ်စာ *',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryAccent),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            
            // Social account
            TextField(
              controller: _brokerSocialCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'လူမှုကွန်ယက်အကောင့်',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryAccent),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            
            // Notes
            TextField(
              controller: _notesCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'မှတ်ချက်များ',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryAccent),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 24),
            
            // ===== ITEMS SECTION =====
            // Running totals card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryAccent),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[900],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'စုစုပေါင်းအရေအတွက်',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_items.length}',
                        style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'စုစုပေါင်းအပ်စာရင်းအရေအတွက်',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getTotalConsignmentQuantity().toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section title
            Text(
              'အပ်မည့်ကျောက်စာရင်းများ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Add button (prominent)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('+ ကျောက်ထည့်ရန်'),
                onPressed: _addItem,
              ),
            ),
            const SizedBox(height: 12),
            
            // Items list
            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[900],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, color: Colors.grey[600], size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'ကျောက်မထည့်သွင်းရသေးပါ',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _buildItemRow(item);
                },
              ),
            
            const SizedBox(height: 24),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid() 
                    ? AppTheme.primaryAccent 
                    : Colors.grey[700],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isFormValid() ? _saveBrokerConsignment : null,
                child: const Text(
                  'သိမ်းဆည်းရန်',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(ConsignmentItemTemp item) {
    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'အရေအတွက် ${_items.indexOf(item) + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                  onPressed: () => _removeItem(item.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Source Type selector (Step 1: Whole Stone / Breakdown Item)
            Text(
              'အရင်းအမြစ်အမျိုးအစား',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 4),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'whole_stone',
                  label: Text('အပြည့်အစုံ'),
                ),
                ButtonSegment<String>(
                  value: 'breakdown_item',
                  label: Text('အခွဲ'),
                ),
              ],
              selected: <String>{item.sourceType},
              onSelectionChanged: (Set<String> newSelection) {
                _updateItemSourceType(item.id, newSelection.first);
              },
            ),
            const SizedBox(height: 12),
            
            // Gemstone selection dropdown (Task 1: Improved selector)
            DropdownButtonFormField<String?>(
              value: item.gemstone?.id,
              isExpanded: true,
              dropdownColor: AppTheme.surfaceDark,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'ကျောက်ရွေးချယ်ပါ',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryAccent),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('— ကျောက်မျက်ရွေးချယ်ပါ —'),
                ),
                ..._availableGemstones.map((g) => DropdownMenuItem<String?>(
                  value: g.id,
                  child: Text(
                    '${g.name} (${g.type} • ကျန်: ${g.remainingQuantity} • ID: ${g.id.substring(0, 8)}...)',
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
              ],
              onChanged: (String? gemstoneId) {
                if (gemstoneId != null) {
                  final gemstone = _availableGemstones.firstWhere(
                    (g) => g.id == gemstoneId,
                    orElse: () => _availableGemstones.first,
                  );
                  _updateItemGemstone(item.id, gemstone);
                } else {
                  _updateItemGemstone(item.id, null);
                }
              },
            ),
            const SizedBox(height: 8),

            // Display selected gemstone details
            if (item.gemstone != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.source_outlined,
                            color: AppTheme.primaryAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'အရင်းအမြစ်: ${item.sourceType == 'whole_stone' ? 'အပြည့်အစုံ' : 'အခွဲ'}',
                            style: const TextStyle(
                                color: AppTheme.primaryAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            color: AppTheme.primaryAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ကျန်ရှိအရေအတွက်: ${item.gemstone!.remainingQuantity}',
                            style: const TextStyle(
                                color: AppTheme.primaryAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppTheme.primaryAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ဝယ်ယူမှုရက်စွဲ: ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(item.gemstone!.createdAt))}',
                            style: const TextStyle(
                                color: AppTheme.primaryAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (item.gemstone!.weightCarat > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.scale,
                                color: AppTheme.primaryAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'အလေးချိန်: ${item.gemstone!.weightCarat} ${LocalDb.unitLabel(item.gemstone!.weightUnit)}',
                                style: const TextStyle(
                                    color: AppTheme.primaryAccent, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Purchase Record selector (for breakdown items)
            if (item.sourceType == 'breakdown_item')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ဝယ်ယူမှုမှတ်တမ်းရွေးချယ်ပါ',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String?>(
                    value: item.selectedPurchase?.id,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'မှတ်တမ်းရွေးချယ်ပါ',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryAccent),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— မှတ်တမ်းရွေးချယ်ပါ —'),
                      ),
                      ..._availableGemstones.map((g) => DropdownMenuItem<String?>(
                        value: g.id,
                        child: Text(
                          '${g.name} (${g.type} • ID: ${g.id.substring(0, 8)}...)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                    ],
                    onChanged: (String? gemstoneId) {
                      if (gemstoneId != null) {
                        final gemstone = _availableGemstones.firstWhere(
                          (g) => g.id == gemstoneId,
                          orElse: () => _availableGemstones.first,
                        );
                        _updateItemPurchase(item.id, gemstone);
                      } else {
                        _updateItemPurchase(item.id, null);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            
            // Breakdown Item selector (only show if purchase selected)
            if (item.sourceType == 'breakdown_item' && item.selectedPurchase != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ကျောက်အစိတ်စိတ်ရွေးချယ်ပါ',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  if (item.availableBreakdownItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[900],
                      ),
                      child: Text(
                        'အစိတ်စိတ်မရှိသေးပါ',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  else
                    DropdownButtonFormField<String?>(
                      value: item.selectedBreakdownItem,
                      isExpanded: true,
                      dropdownColor: AppTheme.surfaceDark,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'အစိတ်စိတ်ရွေးချယ်ပါ',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.primaryAccent),
                        ),
                        filled: true,
                        fillColor: Colors.grey[900],
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('— အစိတ်စိတ်ရွေးချယ်ပါ —'),
                        ),
                        ...item.availableBreakdownItems.entries.map((e) => DropdownMenuItem<String?>(
                          value: e.key,
                          child: Text('${e.key} (ကျန်: ${e.value})'),
                        )).toList(),
                      ],
                      onChanged: (String? breakdownItem) {
                        _updateItemBreakdownItem(item.id, breakdownItem);
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            
            // Quantity input
            if (item.gemstone != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'အပ်စာရင်းအရေအတွက်',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: item.sourceType == 'breakdown_item' && item.selectedBreakdownItem != null
                          ? 'အရေအတွက် (ကျန်ရှိ: ${item.availableBreakdownItems[item.selectedBreakdownItem] ?? 0})'
                          : 'အရေအတွက် (ကျန်ရှိ: ${item.gemstone!.remainingQuantity})',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryAccent),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                    ),
                      onChanged: (value) {
                      final qty = double.tryParse(value) ?? 0;
                      
                      // Validate quantity
                      if (item.sourceType == 'breakdown_item' && item.selectedBreakdownItem != null) {
                        final maxQty = item.availableBreakdownItems[item.selectedBreakdownItem] ?? 0;
                        if (qty > maxQty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('ထည့်သွင်းသောအရေအတွက်သည် ရွေးချယ်ထားသော ပစ္စည်း၏ လက်ကျန်အရေအတွက်ထက် မများရပါ။'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }
                      } else {
                        if (qty > item.gemstone!.remainingQuantity) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('ထည့်သွင်းသောအရေအတွက်သည် ကျန်ရှိအရေအတွက်ထက် မများရပါ။'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }
                      }
                      
                      _updateItemQuantity(item.id, qty);
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
