import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

class BrokerDetailPage extends StatefulWidget {
  final String brokerId;

  const BrokerDetailPage({Key? key, required this.brokerId}) : super(key: key);

  @override
  State<BrokerDetailPage> createState() => _BrokerDetailPageState();
}

class _BrokerDetailPageState extends State<BrokerDetailPage> {
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  late TextEditingController _soldQtyCtrl;
  late TextEditingController _returnedQtyCtrl;

  @override
  void initState() {
    super.initState();
    _soldQtyCtrl = TextEditingController();
    _returnedQtyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _soldQtyCtrl.dispose();
    _returnedQtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bc = LocalDb.getBrokerConsignment(widget.brokerId);
    if (bc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('အပ်စာရင်း')),
        body: const Center(child: Text('အပ်စာရင်းမတွေ့ရှိပါ')),
      );
    }

    final purchase = LocalDb.getGemstone(bc.purchaseId);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('အပ်စာရင်းအသေးစိတ်'),
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
            // Broker Information Card
            _buildCard(
              title: 'ပွဲစားအချက်အလက်',
              children: [
                _buildInfoRow('အမည်', bc.brokerName),
                _buildInfoRow('ဖုန်းနံပါတ်', bc.brokerPhone),
                _buildInfoRow('လိပ်စာ', bc.brokerAddress),
                if (bc.brokerSocialAccount != null && bc.brokerSocialAccount!.isNotEmpty)
                  _buildInfoRow('အချက်အလက်', bc.brokerSocialAccount!),
              ],
            ),
            const SizedBox(height: 16),

            // Historical Data Card (Full Traceability)
            _buildCard(
              title: 'ကျောက်အချက်အလက် (သမိုင်းအမှတ်တမ်း)',
              children: [
                _buildInfoRow('ကျောက်အမည်', bc.historicalData.purchaseName),
                _buildInfoRow('အမျိုးအစား', bc.historicalData.gemstoneType),
                _buildInfoRow('မူလအရေအတွက်', bc.historicalData.originalQuantity.toString()),
                _buildInfoRow('မူလအလေးချိန်', '${bc.historicalData.originalWeight} carat'),
                _buildInfoRow(
                  'အပ်ထားသည့်ရက်စွဲ',
                  _dateFormat.format(DateTime.fromMillisecondsSinceEpoch(bc.historicalData.capturedAt)),
                ),
                _buildInfoRow(
                  'ကျောက်ဝယ်ယူသည့်ရက်စွဲ',
                  DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(bc.historicalData.purchaseDate)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quantity Status Card
            _buildCard(
              title: 'အရေအတွက်အခြေအနေ',
              children: [
                _buildInfoRow('အပ်ထားသော', bc.consignedQuantity.toInt().toString(), Colors.blue),
                _buildInfoRow('ရောင်းချ', bc.soldQuantity.toInt().toString(), Colors.orange),
                _buildInfoRow('ပြန်လည်လက်ခံ', bc.returnedQuantity.toInt().toString(), Colors.green),
                _buildInfoRow('ကျန်ရှိ', bc.remainingQuantity.toInt().toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 16),

            // Update Quantities Section (Admin only)
            if (LocalDb.canUpdateBrokerConsignment()) ...[
              _buildCard(
                title: 'အရေအတွက်အဆင့်မြှင့်တင်ရန်',
                children: [
                  TextField(
                    controller: _soldQtyCtrl,
                    decoration: InputDecoration(
                      labelText: 'ရောင်းချသောအရေအတွက်',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _returnedQtyCtrl,
                    decoration: InputDecoration(
                      labelText: 'ပြန်လည်လက်ခံသောအရေအတွက်',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: AppTheme.surfaceDark,
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          onPressed: () => _updateSoldQuantity(bc),
                          child: const Text('ရောင်းချအဆင့်မြှင့်တင်ရန်'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _updateReturnedQuantity(bc),
                          child: const Text('ပြန်လည်လက်ခံရန်'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            if (bc.notes.isNotEmpty)
              _buildCard(
                title: 'မှတ်ချက်များ',
                children: [
                  Text(
                    bc.notes,
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Audit Log
            _buildCard(
              title: 'ကျောက်မှတ်တမ်း',
              children: [
                Text(
                  'ဖန်တီးသည့်ရက်စွဲ: ${_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(bc.createdAt))}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                Text(
                  'နောက်ဆုံးအဆင့်မြှင့်တင်သည့်ရက်စွဲ: ${_dateFormat.format(DateTime.fromMillisecondsSinceEpoch(bc.updatedAt))}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSoldQuantity(BrokerConsignment bc) async {
    try {
      final qty = double.tryParse(_soldQtyCtrl.text) ?? 0;
      if (qty < 0 || qty > bc.remainingQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('မမှန်သောအရေအတွက်')),
        );
        return;
      }

      await LocalDb.updateBrokerSoldQuantity(widget.brokerId, qty);
      _soldQtyCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('အဆင့်မြှင့်တင်အောင်မြင်ပါသည်')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('အမှားအယွင်း: $e')),
      );
    }
  }

  Future<void> _updateReturnedQuantity(BrokerConsignment bc) async {
    try {
      final qty = double.tryParse(_returnedQtyCtrl.text) ?? 0;
      if (qty < 0 || qty > bc.remainingQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('မမှန်သောအရေအတွက်')),
        );
        return;
      }

      await LocalDb.updateBrokerReturnedQuantity(widget.brokerId, qty);
      _returnedQtyCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('အဆင့်မြှင့်တင်အောင်မြင်ပါသည်')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('အမှားအယွင်း: $e')),
      );
    }
  }
}
