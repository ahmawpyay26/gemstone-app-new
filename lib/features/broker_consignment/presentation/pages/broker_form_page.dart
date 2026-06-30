import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

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
  
  // Purchase Record reference
  Gemstone? _selectedPurchase;

  // Step 6.4: list of purchase records loaded from LocalDb
  List<Gemstone> _purchaseRecords = [];
  
  // Step 7: Consignment quantity input
  late TextEditingController _consignmentQuantityCtrl;
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
      
      // Step 8: Create broker consignment with auto deduction
      await LocalDb.createBrokerConsignment(
        purchaseId: _selectedPurchase!.id,
        consignedQuantity: quantity.toDouble(),
        sourceType: 'whole_stone',
        brokerName: _brokerNameCtrl.text,
        brokerPhone: _brokerPhoneCtrl.text,
        brokerAddress: _brokerAddressCtrl.text,
      );

      // Navigate back on success
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
          title: const Text('ဝယ်ယူမှုမှတ်တမ်းရွေးချယ်ပါ'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _purchaseRecords.length,
              itemBuilder: (context, index) {
                final gemstone = _purchaseRecords[index];
                final purchaseDate = DateFormat('dd/MM/yyyy').format(
                  DateTime.fromMillisecondsSinceEpoch(gemstone.createdAt),
                );
                return ListTile(
                  title: Text(
                    gemstone.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('အမျိုးအစား: ${gemstone.type}'),
                      Text('ဝယ်ယူမှုရက်စွဲ: $purchaseDate'),
                      Text('ကျန်ရှိအရေအတွက်: ${gemstone.remainingQuantity}'),
                      Text('ID: ${gemstone.id}'),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _selectedPurchase = gemstone;
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
            Text('ပွဲစားအချက်အလက်', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showPurchaseSelector(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedPurchase == null
                            ? 'ဝယ်ယူမှုမှတ်တမ်းရွေးချယ်ပါ'
                            : _selectedPurchase!.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedPurchase == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedPurchase != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ရွေးချယ်ထားသည့်ဝယ်ယူမှုမှတ်တမ်း: ${_selectedPurchase!.name}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ဝယ်ယူမှုရက်စွဲ: ${DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(_selectedPurchase!.createdAt))}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ကျန်ရှိအရေအတွက်: ${_selectedPurchase!.remainingQuantity}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            const SizedBox(height: 12),
            if (_selectedPurchase != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _consignmentQuantityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'အပ်စာရင်းအရေအတွက်',
                      border: const OutlineInputBorder(),
                      errorText: _quantityErrorMessage,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _validateQuantity(value);
                      });
                    },
                  ),
                  if (_quantityErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _quantityErrorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _brokerNameCtrl,
              decoration: const InputDecoration(
                labelText: 'ပွဲစားအမည်',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brokerPhoneCtrl,
              decoration: const InputDecoration(
                labelText: 'ဖုန်းနံပါတ်',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brokerAddressCtrl,
              decoration: const InputDecoration(
                labelText: 'လိပ်စာ',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormValid() ? _saveBrokerConsignment : null,
                child: const Text('သိမ်းဆည်းရန်'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
