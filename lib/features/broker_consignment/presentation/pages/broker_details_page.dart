import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

class BrokerDetailsPage extends StatefulWidget {
  final String brokerId;

  const BrokerDetailsPage({
    Key? key,
    required this.brokerId,
  }) : super(key: key);

  @override
  State<BrokerDetailsPage> createState() => _BrokerDetailsPageState();
}

class _BrokerDetailsPageState extends State<BrokerDetailsPage> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat('#,##0.00', 'en_US');

  BrokerConsignment? _brokerConsignment;
  Gemstone? _gemstone;
  
  // Broker Sales Tracking
  late TextEditingController _quantitySoldController;
  late TextEditingController _unitPriceController;
  late TextEditingController _commissionController;
  late TextEditingController _buyerNameController;
  late TextEditingController _remarkController;
  DateTime? _selectedSaleDate;
  
  String? _quantitySoldError;
  String? _unitPriceError;
  String? _commissionError;
  
  // For history
  List<BrokerSaleRecord> _brokerSaleRecords = [];

  @override
  void initState() {
    super.initState();
    _quantitySoldController = TextEditingController();
    _unitPriceController = TextEditingController();
    _commissionController = TextEditingController();
    _buyerNameController = TextEditingController();
    _remarkController = TextEditingController();
    _selectedSaleDate = DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    _quantitySoldController.dispose();
    _unitPriceController.dispose();
    _commissionController.dispose();
    _buyerNameController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _loadData() {
    try {
      final box = Hive.box<BrokerConsignment>('brokerConsignments');
      _brokerConsignment = box.get(widget.brokerId);
      
      if (_brokerConsignment != null) {
        final gemstonesBox = Hive.box<Gemstone>('gemstones');
        _gemstone = gemstonesBox.get(_brokerConsignment!.purchaseId);
        
        // Load broker sale records for this consignment
        final saleRecordsBox = Hive.box<BrokerSaleRecord>('brokerSaleRecords');
        _brokerSaleRecords = saleRecordsBox.values
            .where((record) => record.brokerConsignmentId == widget.brokerId)
            .toList();
        // Sort by sale date descending (newest first)
        _brokerSaleRecords.sort((a, b) => b.saleDate.compareTo(a.saleDate));
      }
      setState(() {});
    } catch (e) {
      debugPrint('Error loading broker details: $e');
    }
  }

  void _validateQuantitySold(String value) {
    if (value.isEmpty) {
      setState(() => _quantitySoldError = null);
      return;
    }

    final qty = double.tryParse(value);
    if (qty == null || qty <= 0) {
      setState(() => _quantitySoldError = 'အရေအတွက်သည် ၀ထက်ကြီးရမည်ဖြစ်ပါသည်။');
      return;
    }

    if (_brokerConsignment != null && qty > _brokerConsignment!.remainingQuantity) {
      setState(() => _quantitySoldError = 'ကျန်ရှိအရေအတွက်ထက် မများရပါ။');
      return;
    }

    setState(() => _quantitySoldError = null);
  }

  void _validateUnitPrice(String value) {
    if (value.isEmpty) {
      setState(() => _unitPriceError = null);
      return;
    }

    final price = double.tryParse(value);
    if (price == null || price < 0) {
      setState(() => _unitPriceError = 'ယူနစ်စျေးသည် အနုတ်မဖြစ်ရပါ။');
      return;
    }

    setState(() => _unitPriceError = null);
  }

  void _validateCommission(String value) {
    if (value.isEmpty) {
      setState(() => _commissionError = null);
      return;
    }

    final commission = double.tryParse(value);
    if (commission == null || commission < 0) {
      setState(() => _commissionError = 'ကော်မရှင်သည် အနုတ်မဖြစ်ရပါ။');
      return;
    }

    setState(() => _commissionError = null);
  }

  double _calculateTotalAmount() {
    final qty = double.tryParse(_quantitySoldController.text) ?? 0;
    final price = double.tryParse(_unitPriceController.text) ?? 0;
    return qty * price;
  }

  double _calculateNetAmount() {
    final total = _calculateTotalAmount();
    final commission = double.tryParse(_commissionController.text) ?? 0;
    return total - commission;
  }

  Future<void> _recordBrokerSale() async {
    final qty = double.tryParse(_quantitySoldController.text);
    final unitPrice = double.tryParse(_unitPriceController.text);
    final commission = double.tryParse(_commissionController.text) ?? 0;
    final buyerName = _buyerNameController.text.trim();
    final remark = _remarkController.text.trim();
    
    if (qty == null || qty <= 0 || _quantitySoldError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('အရေအတွက်ကို စစ်ဆေးပါ။')),
      );
      return;
    }
    
    if (unitPrice == null || unitPrice < 0 || _unitPriceError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ယူနစ်စျေးကို စစ်ဆေးပါ။')),
      );
      return;
    }
    
    if (_commissionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ကော်မရှင်ကို စစ်ဆေးပါ။')),
      );
      return;
    }

    try {
      final totalAmount = qty * unitPrice;
      final netAmount = totalAmount - commission;
      
      // Create BrokerSaleRecord
      final saleRecord = BrokerSaleRecord(
        id: LocalDb.genId(),
        brokerConsignmentId: widget.brokerId,
        purchaseId: _brokerConsignment!.purchaseId,
        sourceType: _brokerConsignment!.historicalData.sourceType,
        breakdownItemName: _brokerConsignment!.historicalData.breakdownItemName,
        soldQuantity: qty,
        unitPrice: unitPrice,
        totalSaleAmount: totalAmount,
        brokerCommission: commission,
        netAmount: netAmount,
        buyerName: buyerName.isNotEmpty ? buyerName : null,
        remark: remark,
        saleDate: _selectedSaleDate!.millisecondsSinceEpoch,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      
      // Validate the record
      final validationError = saleRecord.validate();
      if (validationError != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('အမှားအယွင်း: $validationError')),
          );
        }
        return;
      }
      
      // Save to Hive
      final saleRecordsBox = Hive.box<BrokerSaleRecord>('brokerSaleRecords');
      await saleRecordsBox.add(saleRecord);
      
      // Update broker consignment
      _brokerConsignment!.soldQuantity += qty;
      final brokerBox = Hive.box<BrokerConsignment>('brokerConsignments');
      await brokerBox.put(widget.brokerId, _brokerConsignment!);
      
      // Update product ledger
      await LocalDb.updateGemstoneProductLedger(_brokerConsignment!.purchaseId);
      
      // Clear form
      _quantitySoldController.clear();
      _unitPriceController.clear();
      _commissionController.clear();
      _buyerNameController.clear();
      _remarkController.clear();
      _selectedSaleDate = DateTime.now();
      
      setState(() {
        _quantitySoldError = null;
        _unitPriceError = null;
        _commissionError = null;
      });
      
      _loadData(); // Refresh data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ရောင်းချမှု အောင်မြင်ပါသည်။')),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryAccent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[300], fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            errorText: errorText,
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('ပွဲစားအပ်စာရင်း အသေးစိတ်'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _brokerConsignment == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'မှတ်တမ်းမတွေ့ရှိပါ',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card with Status Badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        border: Border.all(color: AppTheme.primaryAccent, width: 2),
                        borderRadius: BorderRadius.circular(12),
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
                                      _brokerConsignment!.brokerName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ရက်စွဲ: ${_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(_brokerConsignment!.createdAt))}',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(_brokerConsignment!).withOpacity(0.2),
                                  border: Border.all(color: _getStatusColor(_brokerConsignment!)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusBadge(_brokerConsignment!),
                                  style: TextStyle(
                                    color: _getStatusColor(_brokerConsignment!),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Broker Information Section
                    _buildSectionHeader('ပွဲစားအချက်အလက်'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('အမည်', _brokerConsignment!.brokerName),
                          Divider(color: Colors.grey[700], height: 1),
                          _buildDetailRow('ဖုန်းနံပါတ်', _brokerConsignment!.brokerPhone),
                          Divider(color: Colors.grey[700], height: 1),
                          _buildDetailRow('လိပ်စာ', _brokerConsignment!.brokerAddress),
                          if (_brokerConsignment!.brokerSocialAccount != null && _brokerConsignment!.brokerSocialAccount!.isNotEmpty) ...[
                            Divider(color: Colors.grey[700], height: 1),
                            _buildDetailRow('ဆိုရှယ်မီဒီယာ', _brokerConsignment!.brokerSocialAccount ?? ''),
                          ],
                        ],
                      ),
                    ),

                    // Item Information Section
                    _buildSectionHeader('ကျောက်အချက်အလက်'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('အမည်', _brokerConsignment!.historicalData.purchaseName),
                          Divider(color: Colors.grey[700], height: 1),
                          _buildDetailRow('အမျိုးအစား', _brokerConsignment!.historicalData.gemstoneType),
                          Divider(color: Colors.grey[700], height: 1),
                          _buildDetailRow(
                            'အလေးချိန်',
                            '${_currencyFormat.format(_brokerConsignment!.historicalData.originalWeight)} ${_gemstone?.weightUnit ?? 'carat'}',
                          ),
                          Divider(color: Colors.grey[700], height: 1),
                          _buildDetailRow('မူရင်းနေရာ', _gemstone?.origin ?? '-'),
                          Divider(color: Colors.grey[700], height: 1),
                          _buildDetailRow('အရောင်', _gemstone?.color ?? '-'),
                          if (_brokerConsignment!.historicalData.sourceType == 'breakdown_item') ...[
                            Divider(color: Colors.grey[700], height: 1),
                            _buildDetailRow('အခွဲအမည်', _brokerConsignment!.historicalData.breakdownItemName ?? '-'),
                          ],
                        ],
                      ),
                    ),

                    // Quantity Status Section
                    _buildSectionHeader('အရေအတွက်အခြေအနေ'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('မူလအရေအတွက်', _brokerConsignment!.historicalData.originalQuantity.toStringAsFixed(0)),
                          Divider(color: Colors.grey[700], height: 1),
                          _buildDetailRow('အပ်ထားအရေအတွက်', _brokerConsignment!.consignedQuantity.toStringAsFixed(0)),
                          Divider(color: Colors.grey[700], height: 1),
                          _buildDetailRow('ရောင်းချအရေအတွက်', _brokerConsignment!.soldQuantity.toStringAsFixed(0)),
                          Divider(color: Colors.grey[700], height: 1),
                          _buildDetailRow('ပြန်လည်လက်ခံအရေအတွက်', _brokerConsignment!.returnedQuantity.toStringAsFixed(0)),
                          Divider(color: Colors.grey[700], height: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ကျန်ရှိအရေအတွက်',
                                style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _brokerConsignment!.remainingQuantity.toStringAsFixed(0),
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

                    // Broker Sales Recording Section
                    if (_brokerConsignment!.remainingQuantity > 0) ...[
                      _buildSectionHeader('ရောင်းချမှု မှတ်တမ်းတင်ခြင်း'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primaryAccent, width: 1),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withOpacity(0.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormField(
                              'ရောင်းချအရေအတွက်',
                              _quantitySoldController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              errorText: _quantitySoldError,
                              onChanged: _validateQuantitySold,
                            ),
                            _buildFormField(
                              'ယူနစ်စျေး',
                              _unitPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              errorText: _unitPriceError,
                              onChanged: _validateUnitPrice,
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'စုစုပေါင်းပမာဏ',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                  Text(
                                    _currencyFormat.format(_calculateTotalAmount()),
                                    style: const TextStyle(color: AppTheme.primaryAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFormField(
                              'ကော်မရှင်',
                              _commissionController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              errorText: _commissionError,
                              onChanged: _validateCommission,
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'စုစုပေါင်းငွေ',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                  Text(
                                    _currencyFormat.format(_calculateNetAmount()),
                                    style: const TextStyle(color: AppTheme.primaryAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFormField(
                              'ဝယ်ယူသူအမည်',
                              _buyerNameController,
                            ),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedSaleDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _selectedSaleDate = picked);
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ရောင်းချရက်စွဲ',
                                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[700]!),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedSaleDate != null
                                              ? _dateFormat.format(_selectedSaleDate!)
                                              : 'ရက်စွဲရွေးချယ်ပါ',
                                          style: TextStyle(
                                            color: _selectedSaleDate != null ? Colors.white : Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                        Icon(Icons.calendar_today, color: Colors.grey[500], size: 18),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFormField(
                              'မှတ်ချက်',
                              _remarkController,
                              maxLines: 3,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'အများဆုံး: ${_brokerConsignment!.remainingQuantity.toStringAsFixed(0)}',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                ),
                                ElevatedButton(
                                  onPressed: (_quantitySoldError == null && _unitPriceError == null && _commissionError == null &&
                                      _quantitySoldController.text.isNotEmpty && _unitPriceController.text.isNotEmpty)
                                      ? _recordBrokerSale
                                      : null,
                                  child: const Text('မှတ်တမ်းတင်'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Broker Sale History Section
                    if (_brokerSaleRecords.isNotEmpty) ...[
                      _buildSectionHeader('ရောင်းချမှု မှတ်တမ်းများ'),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withOpacity(0.2),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 12,
                            dataRowHeight: 50,
                            headingRowHeight: 45,
                            columns: [
                              DataColumn(label: Text('ရက်စွဲ', style: TextStyle(color: Colors.grey[300], fontSize: 11))),
                              DataColumn(label: Text('အရေအတွက်', style: TextStyle(color: Colors.grey[300], fontSize: 11))),
                              DataColumn(label: Text('ယူနစ်စျေး', style: TextStyle(color: Colors.grey[300], fontSize: 11))),
                              DataColumn(label: Text('စုစုပေါင်း', style: TextStyle(color: Colors.grey[300], fontSize: 11))),
                              DataColumn(label: Text('ကော်မရှင်', style: TextStyle(color: Colors.grey[300], fontSize: 11))),
                              DataColumn(label: Text('စုစုပေါင်းငွေ', style: TextStyle(color: Colors.grey[300], fontSize: 11))),
                              DataColumn(label: Text('ဝယ်ယူသူ', style: TextStyle(color: Colors.grey[300], fontSize: 11))),
                            ],
                            rows: _brokerSaleRecords.map((record) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                    _dateFormat.format(DateTime.fromMillisecondsSinceEpoch(record.saleDate)),
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  )),
                                  DataCell(Text(
                                    record.soldQuantity.toStringAsFixed(0),
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  )),
                                  DataCell(Text(
                                    _currencyFormat.format(record.unitPrice),
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  )),
                                  DataCell(Text(
                                    _currencyFormat.format(record.totalSaleAmount),
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  )),
                                  DataCell(Text(
                                    _currencyFormat.format(record.brokerCommission),
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  )),
                                  DataCell(Text(
                                    _currencyFormat.format(record.netAmount),
                                    style: const TextStyle(color: AppTheme.primaryAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                  )),
                                  DataCell(Text(
                                    record.buyerName ?? '-',
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  )),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],

                    // Source Information Section
                    _buildSectionHeader('ရင်းမြစ်အချက်အလက်'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('ရင်းမြစ်အမျိုးအစား', _brokerConsignment!.historicalData.sourceType == 'whole_stone' ? 'အပြည့်အစုံ' : 'အခွဲ'),
                          Divider(color: Colors.grey[700], height: 1),
                          _buildDetailRow('ရောင်းချသူ', _brokerConsignment!.historicalData.originalSeller),
                          Divider(color: Colors.grey[700], height: 1),
                          _buildDetailRow(
                            'ဝယ်ယူရက်စွဲ',
                            _dateFormat.format(DateTime.fromMillisecondsSinceEpoch(_brokerConsignment!.historicalData.purchaseDate)),
                          ),
                        ],
                      ),
                    ),

                    // Notes Section
                    if (_brokerConsignment!.notes.isNotEmpty) ...[
                      _buildSectionHeader('မှတ်ချက်'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _brokerConsignment!.notes,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],

                    // Timestamps Section
                    _buildSectionHeader('အချိန်အခြင်းအလက်'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'ဖန်တီးရက်စွဲ',
                            _dateFormat.format(DateTime.fromMillisecondsSinceEpoch(_brokerConsignment!.createdAt)),
                          ),
                          Divider(color: Colors.grey[700], height: 1),
                          _buildDetailRow(
                            'နောက်ဆုံးအဆင့်မြှင့်တင်ရက်စွဲ',
                            _dateFormat.format(DateTime.fromMillisecondsSinceEpoch(_brokerConsignment!.updatedAt)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
