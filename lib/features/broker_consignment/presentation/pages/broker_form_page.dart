import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/photo_media_box.dart';

/// Temporary model for consignment items during form editing
class ConsignmentItemTemp {
  String id;
  Gemstone? gemstone;
  double consignedQuantity;
  String sourceType; // 'whole_stone' or 'breakdown_item'
  Gemstone? selectedPurchase; // For breakdown_item source type
  String? selectedBreakdownItem; // Selected breakdown item name
  Map<String, int> availableBreakdownItems; // Filtered breakdown items from purchase
  List<String> photoPaths; // Independent photo list for this item

  ConsignmentItemTemp({
    required this.id,
    this.gemstone,
    this.consignedQuantity = 0,
    this.sourceType = 'whole_stone',
    this.selectedPurchase,
    this.selectedBreakdownItem,
    this.availableBreakdownItems = const {},
    this.photoPaths = const [],
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
  late String _tempBrokerId; // Temporary ID for form photos
  List<String> _formPhotoPaths = []; // Photos collected during form
  int _photoPickerResetKey = 0; // Key to force PhotoMediaBox rebuild
  
  // Items list - confirmed items ready to save
  List<ConsignmentItemTemp> _confirmedItems = [];
  // Currently editing item
  late ConsignmentItemTemp _currentEditingItem;
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
    _tempBrokerId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentEditingItem = ConsignmentItemTemp(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  void _generateBrokerConsignmentNumber() {
    final dateStr = _dateNum.format(_consignmentDate);
    final randomSuffix = DateTime.now().millisecondsSinceEpoch % 10000;
    _brokerConsignmentNumber = 'BC-$dateStr-${randomSuffix.toString().padLeft(4, '0')}';
  }

  void _updateFormPhotoPaths() {
    // Callback when photos are updated in the media box
    setState(() {});
  }

  double _getTotalConsignmentQuantity() {
    return _confirmedItems.fold<double>(0, (sum, item) => sum + item.consignedQuantity);
  }

  /// Get purchases that have breakdown items with quantity > 0
  List<Gemstone> _getPurchasesWithBreakdownItems() {
    return _availableGemstones.where((gemstone) {
      if (gemstone.breakdownItems.isEmpty) return false;
      return gemstone.breakdownItems.values.any((item) {
        // Extract quantity from nested map (new format: Map<String, dynamic>)
        final itemData = item as Map<String, dynamic>?;
        if (itemData == null) return false;
        final quantity = (itemData['quantity'] as num?)?.toInt() ?? 0;
        return quantity > 0;
      });
    }).toList();
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

  bool _isCurrentItemValid() {
    // Validate quantity first
    if (_currentEditingItem.consignedQuantity <= 0) {
      return false;
    }
    
    // Branch validation by sourceType
    if (_currentEditingItem.sourceType == 'breakdown_item') {
      // For breakdown items: require purchase, breakdown item, and quantity
      if (_currentEditingItem.selectedPurchase == null || _currentEditingItem.selectedBreakdownItem == null) {
        return false;
      }
      // Check quantity against breakdown item available quantity
      if (_currentEditingItem.availableBreakdownItems.containsKey(_currentEditingItem.selectedBreakdownItem)) {
        final availableQty = _currentEditingItem.availableBreakdownItems[_currentEditingItem.selectedBreakdownItem]!;
        if (_currentEditingItem.consignedQuantity > availableQty) {
          return false;
        }
      }
    } else {
      // For whole stone: require gemstone and quantity
      if (_currentEditingItem.gemstone == null) {
        return false;
      }
      // Check quantity against gemstone remaining quantity
      if (_currentEditingItem.consignedQuantity > _currentEditingItem.gemstone!.remainingQuantity) {
        return false;
      }
    }
    return true;
  }

  bool _isFormValid() {
    if (!_isHeaderValid()) return false;
    if (_confirmedItems.isEmpty) return false;
    
    // Validate all confirmed items
    for (final item in _confirmedItems) {
      // Validate quantity first
      if (item.consignedQuantity <= 0) {
        return false;
      }
      
      // Branch validation by sourceType
      if (item.sourceType == 'breakdown_item') {
        // For breakdown items: require purchase, breakdown item, and quantity
        if (item.selectedPurchase == null || item.selectedBreakdownItem == null) {
          return false;
        }
        // Check quantity against breakdown item available quantity
        if (item.availableBreakdownItems.containsKey(item.selectedBreakdownItem)) {
          final availableQty = item.availableBreakdownItems[item.selectedBreakdownItem]!;
          if (item.consignedQuantity > availableQty) {
            return false;
          }
        }
      } else {
        // For whole stone: require gemstone and quantity
        if (item.gemstone == null) {
          return false;
        }
        // Check quantity against gemstone remaining quantity
        if (item.consignedQuantity > item.gemstone!.remainingQuantity) {
          return false;
        }
      }
    }
    
    return true;
  }

  void _confirmCurrentItem() {
    if (!_isCurrentItemValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ကျောက်ရွေးချယ်ခြင်း၊ အရင်းအမြစ်အမျိုးအစား နှင့် အရေအတွက်ကို ဖြည့်သွင်းပါ။'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    setState(() {
      // Copy current form photos to the item (independent copy)
      _currentEditingItem.photoPaths = List<String>.from(_formPhotoPaths);
      
      // Add current item to confirmed list
      _confirmedItems.add(_currentEditingItem);
      
      // Reset the form completely
      _resetCurrentItemForm();
    });
  }

  void _resetCurrentItemForm() {
    setState(() {
      // Reset all form fields
      _currentEditingItem = ConsignmentItemTemp(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      // Create NEW empty list instance (not cleared reference)
      _formPhotoPaths = <String>[];
      // Force PhotoMediaBox rebuild by changing ValueKey
      _photoPickerResetKey++;
    });
  }

  void _removeConfirmedItem(String itemId) {
    setState(() {
      _confirmedItems.removeWhere((item) => item.id == itemId);
    });
  }

  void _updateCurrentItemGemstone(Gemstone? gemstone) {
    setState(() {
      _currentEditingItem.gemstone = gemstone;
      // Reset quantity if gemstone changed
      _currentEditingItem.consignedQuantity = 0;
    });
  }

  void _updateCurrentItemQuantity(double quantity) {
    setState(() {
      _currentEditingItem.consignedQuantity = quantity;
    });
  }

  void _updateCurrentItemSourceType(String sourceType) {
    setState(() {
      _currentEditingItem.sourceType = sourceType;
      _currentEditingItem.consignedQuantity = 0;
      if (sourceType == 'whole_stone') {
        _currentEditingItem.selectedPurchase = null;
        _currentEditingItem.selectedBreakdownItem = null;
        _currentEditingItem.availableBreakdownItems = {};
      }
    });
  }

  void _updateCurrentItemPurchase(Gemstone? purchase) {
    setState(() {
      _currentEditingItem.selectedPurchase = purchase;
      _currentEditingItem.selectedBreakdownItem = null;
      if (purchase != null && purchase.breakdownItems.isNotEmpty) {
        _currentEditingItem.availableBreakdownItems = {};
        purchase.breakdownItems.forEach((name, item) {
          // Extract quantity from nested map (new format: Map<String, dynamic>)
          final itemData = item as Map<String, dynamic>?;
          final qty = (itemData?['quantity'] as num?)?.toInt() ?? 0;
          if (qty > 0) {
            _currentEditingItem.availableBreakdownItems[name] = qty;
          }
        });
      } else {
        _currentEditingItem.availableBreakdownItems = {};
      }
    });
  }

  void _updateCurrentItemBreakdownItem(String? breakdownItemName) {
    setState(() {
      _currentEditingItem.selectedBreakdownItem = breakdownItemName;
      _currentEditingItem.consignedQuantity = 0;
    });
  }

  Future<void> _saveBrokerConsignment() async {
    if (!_isFormValid()) return;

    try {
      // PHASE B: Generate shared voucher IDs for this batch submission
      // Generate ONCE before the loop to ensure all items in this submission share the same voucher
      final voucherId = const Uuid().v4(); // Collision-safe UUID
      final voucherNumber = LocalDb.generateNextVoucherNumber(); // BC-YYYYMMDD-NNNN
      
      // For now, save each item as a separate BrokerConsignment record
      // (backward compatible with existing model)
      // All items in this submission will share the same voucherId and voucherNumber
      
      for (final item in _confirmedItems) {
        // Determine purchaseId based on sourceType
        String purchaseId;
        if (item.sourceType == 'whole_stone') {
          if (item.gemstone == null) continue; // Skip invalid whole stone items
          purchaseId = item.gemstone!.id;
        } else {
          if (item.selectedPurchase == null) continue; // Skip invalid breakdown items
          purchaseId = item.selectedPurchase!.id;
        }
        
        await LocalDb.createBrokerConsignment(
          purchaseId: purchaseId,
          consignedQuantity: item.consignedQuantity,
          sourceType: item.sourceType,
          breakdownItemName: item.selectedBreakdownItem,
          brokerName: _brokerNameCtrl.text,
          brokerPhone: _brokerPhoneCtrl.text,
          brokerAddress: _brokerAddressCtrl.text,
          brokerSocialAccount: _brokerSocialCtrl.text.isEmpty ? null : _brokerSocialCtrl.text,
          photoPaths: item.photoPaths,
          voucherId: voucherId, // Assign shared voucher ID
          voucherNumber: voucherNumber, // Assign shared voucher number
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
                        '${_confirmedItems.length}',
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

            // ===== EDITING SECTION =====
            Text(
              'ကျောက်ထည့်သွင်းခြင်း',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildEditingItemForm(),
            const SizedBox(height: 12),
            
            // Add Item button
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
                label: const Text('ထည့်ရန်'),
                onPressed: _confirmCurrentItem,
              ),
            ),
            const SizedBox(height: 24),
            
            // ===== CONFIRMED ITEMS SECTION =====
            if (_confirmedItems.isNotEmpty)
              Text(
                'ထည့်သွင်းထားသောကျောက်များ (${_confirmedItems.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (_confirmedItems.isNotEmpty)
              const SizedBox(height: 12),
            
            // Items list
            if (_confirmedItems.isEmpty)
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
                        'ထည့်သွင်းထားသောကျောက်မရှိသေးပါ',
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
                itemCount: _confirmedItems.length,
                itemBuilder: (context, index) {
                  final item = _confirmedItems[index];
                  return _buildConfirmedItemRow(item);
                },
              ),
            
            const SizedBox(height: 24),
            
            // Photo section title
            if (_currentEditingItem.gemstone != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'လက\u1031\u1038ယ\u1010\u103d\u1000\u103aအ\u1015\u103c\u102f\u1014\u102d\u102f\u1004\u103a: ${_currentEditingItem.gemstone!.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            
            // Photo Media Box
            _buildPhotoMediaBox(),
            
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

  Widget _buildEditingItemForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryAccent, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[900],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ကျောက်ထည့်သွင်းခြင်း',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Source Type selector
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
            selected: <String>{_currentEditingItem.sourceType},
            onSelectionChanged: (Set<String> newSelection) {
              _updateCurrentItemSourceType(newSelection.first);
            },
          ),
          const SizedBox(height: 12),
          
          // Gemstone selection dropdown - only for whole stone mode
          if (_currentEditingItem.sourceType == 'whole_stone')
            DropdownButtonFormField<String?>(
              value: _currentEditingItem.gemstone?.id,
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
                _updateCurrentItemGemstone(gemstone);
              } else {
                _updateCurrentItemGemstone(null);
              }
            },
            ),
            const SizedBox(height: 8),

            // Display selected gemstone details
            if (_currentEditingItem.gemstone != null)
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
                          'အရင်းအမြစ်: ${_currentEditingItem.sourceType == 'whole_stone' ? 'အပြည့်အစုံ' : 'အခွဲ'}',
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
                          'ကျန်ရှိအရေအတွက်: ${_currentEditingItem.gemstone!.remainingQuantity}',
                          style: const TextStyle(
                              color: AppTheme.primaryAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
          
          const SizedBox(height: 8),
          
          // Purchase Record selector (for breakdown items)
          if (_currentEditingItem.sourceType == 'breakdown_item')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ဝယ်ယူမှုမှတ်တမ်းရွေးချယ်ပါ',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String?>(
                  value: _currentEditingItem.selectedPurchase?.id,
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
                    ..._getPurchasesWithBreakdownItems().map((g) {
                      final fragmentCount = g.breakdownItems?.length ?? 0;
                      final fragmentDisplay = fragmentCount > 0 ? ' • အစိတ်စိတ်: $fragmentCount' : '';
                      return DropdownMenuItem<String?>(
                        value: g.id,
                        child: Text(
                          '${g.name} (${g.type}$fragmentDisplay • ID: ${g.id.substring(0, 8)}...)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (String? gemstoneId) {
                    if (gemstoneId != null) {
                      final gemstone = _getPurchasesWithBreakdownItems().firstWhere(
                        (g) => g.id == gemstoneId,
                        orElse: () => _getPurchasesWithBreakdownItems().first,
                      );
                      _updateCurrentItemPurchase(gemstone);
                    } else {
                      _updateCurrentItemPurchase(null);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          
          // Breakdown Item selector
          if (_currentEditingItem.sourceType == 'breakdown_item' && _currentEditingItem.selectedPurchase != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ကျောက်အစိတ်စိတ်ရွေးချယ်ပါ',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 4),
                if (_currentEditingItem.availableBreakdownItems.isEmpty)
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
                    value: _currentEditingItem.selectedBreakdownItem,
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
                      ..._currentEditingItem.availableBreakdownItems.entries.map((e) {
                        final gemstone = _currentEditingItem.gemstone;
                        final itemData = gemstone?.breakdownItems?[e.key] as Map<String, dynamic>?;
                        final weight = (itemData?['weight'] as num?)?.toDouble() ?? 0;
                        final weightUnit = itemData?['weightUnit'] as String? ?? '';
                        final weightDisplay = weight > 0 ? ' — $weight $weightUnit' : '';
                        return DropdownMenuItem<String?>(
                          value: e.key,
                          child: Text('${e.key} (ကျန်: ${e.value}$weightDisplay)'),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? breakdownItem) {
                      _updateCurrentItemBreakdownItem(breakdownItem);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          
          // Display remaining weight for breakdown items
          if (_currentEditingItem.sourceType == 'breakdown_item' && _currentEditingItem.selectedBreakdownItem != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Builder(
                builder: (context) {
                  final gemstone = _currentEditingItem.gemstone;
                  final itemData = gemstone?.breakdownItems?[_currentEditingItem.selectedBreakdownItem] as Map<String, dynamic>?;
                  final weight = (itemData?['weight'] as num?)?.toDouble() ?? 0;
                  final weightUnit = itemData?['weightUnit'] as String? ?? '';
                  return Text(
                    'ကျန်ရှိအလေးချိန်: $weight $weightUnit',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  );
                },
              ),
            ),
          
          // Quantity input
          if (_currentEditingItem.gemstone != null || _currentEditingItem.selectedBreakdownItem != null)
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
                    hintText: _currentEditingItem.sourceType == 'breakdown_item' && _currentEditingItem.selectedBreakdownItem != null
                        ? 'အရေအတွက် (ကျန်ရှိ: ${_currentEditingItem.availableBreakdownItems[_currentEditingItem.selectedBreakdownItem] ?? 0})'
                        : 'အရေအတွက် (ကျန်ရှိ: ${_currentEditingItem.gemstone!.remainingQuantity})',
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
                    if (_currentEditingItem.sourceType == 'breakdown_item' && _currentEditingItem.selectedBreakdownItem != null) {
                      final maxQty = _currentEditingItem.availableBreakdownItems[_currentEditingItem.selectedBreakdownItem] ?? 0;
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
                      if (qty > _currentEditingItem.gemstone!.remainingQuantity) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('ထည့်သွင်းသောအရေအတွက်သည် ကျန်ရှိအရေအတွက်ထက် မများရပါ။'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                        return;
                      }
                    }
                    
                    _updateCurrentItemQuantity(qty);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmedItemRow(ConsignmentItemTemp item) {
    String gemName = 'Unknown';
    double? weight;
    
    if (item.sourceType == 'whole_stone' && item.gemstone != null) {
      gemName = item.gemstone!.name;
      weight = item.gemstone!.weightCarat;
    } else if (item.sourceType == 'breakdown_item' && item.selectedBreakdownItem != null) {
      gemName = '${item.selectedPurchase?.name ?? "Unknown"} / ${item.selectedBreakdownItem}';
      weight = item.selectedPurchase?.weightCarat;
    }
    
    final photoCount = item.photoPaths.length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey[900],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gemName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (weight != null && weight > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'အလေးချိန်: $weight viss',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (photoCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '📷 $photoCount',
                      style: const TextStyle(
                        color: AppTheme.primaryAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'အရေအတွက်: ${item.consignedQuantity}',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.primaryAccent, size: 18),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('အပ်ဒိတ်ဖိုင်ချ မကြာမီ အသုံးပြုနိုင်မည်')),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.errorColor, size: 18),
                    onPressed: () => _removeConfirmedItem(item.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build compact summary text for confirmed items
  String _buildConfirmedItemSummary(ConsignmentItemTemp item) {
    if (item.sourceType == 'whole_stone' && item.gemstone != null) {
      return '${item.gemstone!.name} — ${item.consignedQuantity}';
    } else if (item.sourceType == 'breakdown_item' && item.selectedBreakdownItem != null && item.selectedPurchase != null) {
      return '${item.selectedPurchase!.name} / ${item.selectedBreakdownItem} — ${item.consignedQuantity}';
    } else {
      return 'Unknown — ${item.consignedQuantity}';
    }
  }

  /// Build photo media box widget
  Widget _buildPhotoMediaBox() {
    // Show title indicating these are current item photos
    final itemDescription = _currentEditingItem.gemstone != null
        ? _currentEditingItem.gemstone!.name
        : 'လက်ရှိကျောက်';

    // Create a temporary broker consignment for the form
    // This will be replaced with the real one after save
    final now = DateTime.now().millisecondsSinceEpoch;
    final tempHistoricalData = BrokerHistoricalData(
      purchaseName: 'ယာယီ',
      purchaseDate: now,
      originalSeller: '',
      gemstoneType: '',
      sourceType: 'whole_stone',
      originalQuantity: 0,
      originalWeight: 0,
      capturedAt: now,
    );

    final tempBrokerConsignment = BrokerConsignment(
      id: _tempBrokerId,
      purchaseId: '',
      consignedQuantity: 0,
      historicalData: tempHistoricalData,
      brokerName: _brokerNameCtrl.text,
      brokerPhone: _brokerPhoneCtrl.text,
      brokerAddress: _brokerAddressCtrl.text,
      brokerSocialAccount: _brokerSocialCtrl.text.isEmpty ? null : _brokerSocialCtrl.text,
      photoPaths: _formPhotoPaths,
      createdAt: now,
    );

    return PhotoMediaBox(
      key: ValueKey(_photoPickerResetKey),
      brokerId: _tempBrokerId,
      brokerConsignment: tempBrokerConsignment,
      onPhotosUpdated: () {
        // Update the form photo paths when photos change
        setState(() {
          _formPhotoPaths = tempBrokerConsignment.photoPaths;
        });
      },
    );
  }

}
