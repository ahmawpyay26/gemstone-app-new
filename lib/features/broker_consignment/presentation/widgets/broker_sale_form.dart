import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

typedef OnSaleSubmit = Future<void> Function(
  DateTime saleDate,
  String? buyerName,
  double quantity,
  double unitPrice,
  double brokerCommission,
  String remark,
  String? breakdownItemName,
);

class BrokerSaleForm extends StatefulWidget {
  final double brokerRemainingQuantity;
  final String sourceType; // whole_stone | breakdown_item
  final String? breakdownItemName;
  final List<String>? breakdownItems; // Available breakdown items
  final OnSaleSubmit onSubmit;
  final VoidCallback? onCancel;

  const BrokerSaleForm({
    Key? key,
    required this.brokerRemainingQuantity,
    required this.sourceType,
    this.breakdownItemName,
    this.breakdownItems,
    required this.onSubmit,
    this.onCancel,
  }) : super(key: key);

  @override
  State<BrokerSaleForm> createState() => _BrokerSaleFormState();
}

class _BrokerSaleFormState extends State<BrokerSaleForm> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat('#,##0.00', 'en_US');

  late DateTime _selectedSaleDate;
  late TextEditingController _buyerNameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _commissionController;
  late TextEditingController _remarkController;
  String? _selectedBreakdownItem;

  String? _quantityError;
  String? _unitPriceError;
  String? _commissionError;

  double _totalAmount = 0;
  double _netAmount = 0;

  @override
  void initState() {
    super.initState();
    _selectedSaleDate = DateTime.now();
    _buyerNameController = TextEditingController();
    _quantityController = TextEditingController();
    _unitPriceController = TextEditingController();
    _commissionController = TextEditingController();
    _remarkController = TextEditingController();

    if (widget.sourceType == 'breakdown_item' && widget.breakdownItemName != null) {
      _selectedBreakdownItem = widget.breakdownItemName;
    }
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _commissionController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _validateQuantity(String value) {
    if (value.isEmpty) {
      setState(() => _quantityError = null);
      _recalculateTotals();
      return;
    }

    final qty = double.tryParse(value);
    if (qty == null || qty <= 0) {
      setState(() => _quantityError = 'အရေအတွက်သည် ၀ထက်ကြီးရမည်ဖြစ်ပါသည်။');
      return;
    }

    if (qty > widget.brokerRemainingQuantity) {
      setState(() => _quantityError = 'ပွဲစားထံမှ ကျန်ရှိသော အရေအတွက်ထက် မများရပါ။');
      return;
    }

    setState(() => _quantityError = null);
    _recalculateTotals();
  }

  void _validateUnitPrice(String value) {
    if (value.isEmpty) {
      setState(() => _unitPriceError = null);
      _recalculateTotals();
      return;
    }

    final price = double.tryParse(value);
    if (price == null || price < 0) {
      setState(() => _unitPriceError = 'ယူနစ်ဈေးသည် အနုတ်မဖြစ်ရပါ။');
      return;
    }

    setState(() => _unitPriceError = null);
    _recalculateTotals();
  }

  void _validateCommission(String value) {
    if (value.isEmpty) {
      setState(() => _commissionError = null);
      _recalculateTotals();
      return;
    }

    final commission = double.tryParse(value);
    if (commission == null || commission < 0) {
      setState(() => _commissionError = 'ပွဲခသည် အနုတ်မဖြစ်ရပါ။');
      return;
    }

    setState(() => _commissionError = null);
    _recalculateTotals();
  }

  void _recalculateTotals() {
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0;
    final commission = double.tryParse(_commissionController.text) ?? 0;

    final total = qty * unitPrice;
    final net = total - commission;

    setState(() {
      _totalAmount = total;
      _netAmount = net;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedSaleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedSaleDate = picked);
    }
  }

  bool _isFormValid() {
    return _quantityError == null &&
        _unitPriceError == null &&
        _commissionError == null &&
        _quantityController.text.isNotEmpty &&
        _unitPriceController.text.isNotEmpty &&
        _commissionController.text.isNotEmpty &&
        double.tryParse(_quantityController.text)! > 0 &&
        double.tryParse(_unitPriceController.text)! >= 0;
  }

  Future<void> _submitForm() async {
    if (!_isFormValid()) return;

    try {
      await widget.onSubmit(
        _selectedSaleDate,
        _buyerNameController.text.isEmpty ? null : _buyerNameController.text,
        double.parse(_quantityController.text),
        double.parse(_unitPriceController.text),
        double.parse(_commissionController.text),
        _remarkController.text,
        _selectedBreakdownItem,
      );

      // Clear form after successful submission
      _quantityController.clear();
      _unitPriceController.clear();
      _commissionController.clear();
      _buyerNameController.clear();
      _remarkController.clear();
      setState(() {
        _totalAmount = 0;
        _netAmount = 0;
      });
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryAccent, width: 1),
        borderRadius: BorderRadius.circular(8),
        color: Colors.black.withOpacity(0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sale Date
          Text(
            'ရောင်းချရက်စွဲ',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dateFormat.format(_selectedSaleDate),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  Icon(Icons.calendar_today, color: Colors.grey[400], size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Buyer Name (Optional)
          Text(
            'ဝယ်ယူသူအမည် (ရွေးချယ်ခွင့်)',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _buyerNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ဝယ်ယူသူအမည်ထည့်သွင်းပါ',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 12),

          // Breakdown Item Selection (if applicable)
          if (widget.sourceType == 'breakdown_item' && widget.breakdownItems != null && widget.breakdownItems!.isNotEmpty) ...[
            Text(
              'အခွဲအမည်',
              style: TextStyle(color: Colors.grey[300], fontSize: 12),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedBreakdownItem,
              items: widget.breakdownItems!.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedBreakdownItem = value);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
          ],

          // Quantity
          Text(
            'ရောင်းချအရေအတွက်',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              errorText: _quantityError,
              helperText: 'အများဆုံး: ${widget.brokerRemainingQuantity.toStringAsFixed(0)}',
            ),
            onChanged: _validateQuantity,
          ),
          const SizedBox(height: 12),

          // Unit Price
          Text(
            'ယူနစ်ဈေး',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _unitPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              errorText: _unitPriceError,
            ),
            onChanged: _validateUnitPrice,
          ),
          const SizedBox(height: 12),

          // Total Amount (Auto-calculated)
          Text(
            'စုစုပေါင်းရောင်းချငွေ',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[700]!),
              borderRadius: BorderRadius.circular(4),
              color: Colors.black.withOpacity(0.3),
            ),
            child: Text(
              _currencyFormat.format(_totalAmount),
              style: const TextStyle(color: AppTheme.primaryAccent, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          // Broker Commission
          Text(
            'ပွဲခ',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commissionController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              errorText: _commissionError,
            ),
            onChanged: _validateCommission,
          ),
          const SizedBox(height: 12),

          // Net Amount (Auto-calculated)
          Text(
            'သန့်သန့်ငွေ (စုစုပေါင်း - ပွဲခ)',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[700]!),
              borderRadius: BorderRadius.circular(4),
              color: Colors.black.withOpacity(0.3),
            ),
            child: Text(
              _currencyFormat.format(_netAmount),
              style: const TextStyle(color: AppTheme.primaryAccent, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          // Remark
          Text(
            'မှတ်ချက်',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _remarkController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'မှတ်ချက်ထည့်သွင်းပါ',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.onCancel != null)
                ElevatedButton(
                  onPressed: widget.onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                  ),
                  child: const Text('ပယ်ဖျက်ရန်'),
                ),
              ElevatedButton(
                onPressed: _isFormValid() ? _submitForm : null,
                child: const Text('မှတ်တမ်းတင်'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
