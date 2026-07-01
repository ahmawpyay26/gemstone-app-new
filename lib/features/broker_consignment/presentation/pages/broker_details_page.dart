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
  late TextEditingController _soldQtyController;
  late TextEditingController _saleAmountController;
  String? _soldQtyError;
  String? _saleAmountError;

  @override
  void initState() {
    super.initState();
    _soldQtyController = TextEditingController();
    _saleAmountController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _soldQtyController.dispose();
    _saleAmountController.dispose();
    super.dispose();
  }

  void _loadData() {
    try {
      final box = Hive.box<BrokerConsignment>('brokerConsignments');
      _brokerConsignment = box.get(widget.brokerId);
      
      if (_brokerConsignment != null) {
        final gemstonesBox = Hive.box<Gemstone>('gemstones');
        _gemstone = gemstonesBox.get(_brokerConsignment!.purchaseId);
      }
      setState(() {});
    } catch (e) {
      debugPrint('Error loading broker details: $e');
    }
  }

  void _validateSoldQuantity(String value) {
    if (value.isEmpty) {
      setState(() => _soldQtyError = null);
      return;
    }

    final soldQty = int.tryParse(value);
    if (soldQty == null || soldQty <= 0) {
      setState(() => _soldQtyError = 'အရေအတွက်သည် ၀ထက်ကြီးရမည်ဖြစ်ပါသည်။');
      return;
    }

    // Validation: Sold + Returned must not exceed Consigned
    final totalUsed = soldQty + _brokerConsignment!.returnedQuantity.toInt();
    if (totalUsed > _brokerConsignment!.consignedQuantity) {
      setState(() => _soldQtyError = 'ရောင်းချ + ပြန်လည်လက်ခံ သည် အပ်ထားအရေအတွက်ထက် မများရပါ။');
      return;
    }

    setState(() => _soldQtyError = null);
  }

  void _validateSaleAmount(String value) {
    if (value.isEmpty) {
      setState(() => _saleAmountError = null);
      return;
    }

    final saleAmount = double.tryParse(value);
    if (saleAmount == null || saleAmount <= 0) {
      setState(() => _saleAmountError = 'ရောင်းရငွေသည် ၀ထက်ကြီးရမည်ဖြစ်ပါသည်။');
      return;
    }

    setState(() => _saleAmountError = null);
  }

  Future<void> _recordBrokerSale() async {
    final soldQty = int.tryParse(_soldQtyController.text);
    final saleAmount = double.tryParse(_saleAmountController.text);
    
    if (soldQty == null || soldQty <= 0 || _soldQtyError != null) return;
    if (saleAmount == null || saleAmount <= 0 || _saleAmountError != null) return;

    try {
      await LocalDb.recordBrokerSale(
        brokerConsignmentId: widget.brokerId,
        soldQuantity: soldQty.toDouble(),
        saleAmount: saleAmount,
      );

      _soldQtyController.clear();
      _saleAmountController.clear();
      setState(() {
        _soldQtyError = null;
        _saleAmountError = null;
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

                    // Item Information Section (Historical Data)
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
                            Text(
                              'ရောင်းချမှုအရေအတွက်',
                              style: TextStyle(color: Colors.grey[300], fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _soldQtyController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      hintStyle: TextStyle(color: Colors.grey[600]),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.grey[700]!),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      errorText: _soldQtyError,
                                    ),
                                    onChanged: _validateSoldQuantity,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'ရောင်းချငွေ',
                              style: TextStyle(color: Colors.grey[300], fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _saleAmountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey[700]!),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                errorText: _saleAmountError,
                              ),
                              onChanged: _validateSaleAmount,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'အများဆုံး: ${_brokerConsignment!.remainingQuantity.toStringAsFixed(0)}',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                ),
                                ElevatedButton(
                                  onPressed: (_soldQtyError == null && _saleAmountError == null && 
                                      _soldQtyController.text.isNotEmpty && _saleAmountController.text.isNotEmpty)
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
