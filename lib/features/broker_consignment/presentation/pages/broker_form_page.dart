import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../../../core/theme/app_theme.dart';

class BrokerFormPage extends StatefulWidget {
  final String? brokerId;

  const BrokerFormPage({Key? key, this.brokerId}) : super(key: key);

  @override
  State<BrokerFormPage> createState() => _BrokerFormPageState();
}

class _BrokerFormPageState extends State<BrokerFormPage> {
  late TextEditingController _brokerNameCtrl;
  late TextEditingController _brokerPhoneCtrl;
  late TextEditingController _brokerAddressCtrl;
  late TextEditingController _consignmentQuantityCtrl;
  
  final _money = NumberFormat('#,##0', 'en_US');
  final _date = DateFormat('dd/MM/yyyy');
  
  Gemstone? _selectedPurchase;
  List<Gemstone> _purchaseRecords = [];
  String? _quantityErrorMessage;

  @override
  void initState() {
    super.initState();
    _brokerNameCtrl = TextEditingController();
    _brokerPhoneCtrl = TextEditingController();
    _brokerAddressCtrl = TextEditingController();
    _consignmentQuantityCtrl = TextEditingController();
    _purchaseRecords = LocalDb.gemstones().values.toList();
  }

  @override
  void dispose() {
    _brokerNameCtrl.dispose();
    _brokerPhoneCtrl.dispose();
    _brokerAddressCtrl.dispose();
    _consignmentQuantityCtrl.dispose();
    super.dispose();
  }

  void _validateQuantity(String value) {
    if (_selectedPurchase == null) {
      _quantityErrorMessage = null;
      return;
    }

    if (value.isEmpty) {
      _quantityErrorMessage = null;
      return;
    }

    final quantity = int.tryParse(value);
    if (quantity == null || quantity <= 0) {
      _quantityErrorMessage = 'အရေအတွက်သည် ၀ထက်ကြီးရမည်ဖြစ်ပါသည်။';
      return;
    }

    if (quantity > _selectedPurchase!.remainingQuantity) {
      _quantityErrorMessage = 'ထည့်သွင်းသောအရေအတွက်သည် ကျန်ရှိအရေအတွက်ထက် မကျော်လွန်ရပါ။';
      return;
    }

    _quantityErrorMessage = null;
  }

  bool _isFormValid() {
    if (_selectedPurchase == null) return false;
    if (_consignmentQuantityCtrl.text.isEmpty) return false;
    if (_quantityErrorMessage != null) return false;
    return true;
  }

  Future<void> _saveBrokerConsignment() async {
    if (!_isFormValid() || _selectedPurchase == null) return;

    try {
      final quantity = int.parse(_consignmentQuantityCtrl.text);
      
      await LocalDb.createBrokerConsignment(
        purchaseId: _selectedPurchase!.id,
        consignedQuantity: quantity.toDouble(),
        sourceType: 'whole_stone',
        brokerName: _brokerNameCtrl.text,
        brokerPhone: _brokerPhoneCtrl.text,
        brokerAddress: _brokerAddressCtrl.text,
      );

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

  void _showPurchaseSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('ဝယ်ယူမှုမှတ်တမ်းရွေးချယ်ပါ'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _purchaseRecords.length,
              itemBuilder: (context, index) {
                final gemstone = _purchaseRecords[index];
                final purchaseDate = _date.format(
                  DateTime.fromMillisecondsSinceEpoch(gemstone.createdAt),
                );
                return ListTile(
                  title: Text(
                    gemstone.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'အမျိုးအစား: ${gemstone.type}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        'ဝယ်ယူမှုရက်စွဲ: $purchaseDate',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        'ကျန်ရှိအရေအတွက်: ${gemstone.remainingQuantity}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      Text(
                        'ID: ${gemstone.id}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedPurchase = gemstone;
                      _consignmentQuantityCtrl.clear();
                      _quantityErrorMessage = null;
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ပိတ်ရန်'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(widget.brokerId != null ? 'ပွဲစားအပ်စာရင်းပြင်ဆင်ရန်' : 'ပွဲစားအပ်စာရင်းထည့်သွင်းရန်'),
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
            // Purchase Selection Card
            GestureDetector(
              onTap: () => _showPurchaseSelector(),
              child: Card(
                color: AppTheme.surfaceDark,
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    // Header with date/icon
                    if (_selectedPurchase != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shopping_bag,
                              size: 16,
                              color: AppTheme.primaryAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _date.format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  _selectedPurchase!.createdAt,
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Content
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
                        child: Icon(
                          Icons.shopping_cart,
                          color: AppTheme.primaryAccent,
                        ),
                      ),
                      title: Text(
                        _selectedPurchase?.name ?? 'ဝယ်ယူမှုမှတ်တမ်းရွေးချယ်ပါ',
                        style: TextStyle(
                          color: _selectedPurchase == null ? Colors.grey : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: _selectedPurchase == null
                          ? null
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'အမျိုးအစား: ${_selectedPurchase!.type}',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                Text(
                                  'ကျန်ရှိအရေအတွက်: ${_selectedPurchase!.remainingQuantity}',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                      trailing: Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Consignment Quantity Input
            if (_selectedPurchase != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'အပ်စာရင်းအရေအတွက်',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _consignmentQuantityCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'အရေအတွက်ထည့်သွင်းပါ',
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
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.errorColor),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                      errorText: _quantityErrorMessage,
                      errorStyle: const TextStyle(color: AppTheme.errorColor),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _validateQuantity(value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Broker Information Section
            Text(
              'ပွဲစားအချက်အလက်',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brokerNameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'ပွဲစားအမည်',
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
            TextField(
              controller: _brokerPhoneCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'ဖုန်းနံပါတ်',
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
            TextField(
              controller: _brokerAddressCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'လိပ်စာ',
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
              maxLines: 3,
            ),
            const SizedBox(height: 24),
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
}
