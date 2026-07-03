import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:gemstone_management/core/local/local_db.dart';
import 'package:gemstone_management/core/local/models.dart';
import 'package:gemstone_management/core/theme/app_theme.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({Key? key}) : super(key: key);

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  late final NumberFormat _money;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _money = NumberFormat('#,##0', 'my_MM');
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ဖောက်သည်စာရင်း'),
        backgroundColor: AppTheme.primaryAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'အမည် သို့မဟုတ် ဖုန်းနံပါတ်ဖြင့် ရှာဖွေ',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          // Customer list
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: LocalDb.customers().listenable(),
              builder: (context, box, _) {
                final customers = _searchQuery.isEmpty
                    ? LocalDb.getActiveCustomers()
                    : LocalDb.searchCustomers(_searchQuery);

                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'ဖောက်သည်မရှိသေးပါ'
                              : 'ရှာဖွေမှုရလဒ်မရှိပါ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _buildCustomerCard(customer);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerForm(context),
        backgroundColor: AppTheme.primaryAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryAccent,
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(customer.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phone != null && customer.phone!.isNotEmpty)
              Text('ဖုန်း: ${customer.phone}'),
            Text('လက်ရှိကြွေးမြတ်: ${_money.format(customer.currentBalance)}'),
            Text('အကြွေးကန့်သတ်: ${_money.format(customer.creditLimit)}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('ပြင်ဆင်'),
              onTap: () => _showCustomerForm(context, customer),
            ),
            PopupMenuItem(
              child: const Text('ဖျက်မည်'),
              onTap: () => _deleteCustomer(customer.id),
            ),
          ],
        ),
        onTap: () => _showCustomerForm(context, customer),
      ),
    );
  }

  void _showCustomerForm(BuildContext context, [Customer? existing]) {
    showDialog(
      context: context,
      builder: (context) => _CustomerFormDialog(
        existing: existing,
        onSave: (customer) {
          if (existing == null) {
            LocalDb.createCustomer(customer);
          } else {
            LocalDb.updateCustomer(customer);
          }
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(existing == null
                  ? 'ဖောက်သည်ထည့်သွင်းပြီးပါပြီ'
                  : 'ဖောက်သည်အချက်အလက်ပြင်ဆင်းပြီးပါပြီ'),
            ),
          );
        },
      ),
    );
  }

  void _deleteCustomer(String customerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ဖောက်သည်ဖျက်မည်'),
        content: const Text('ဤဖောက်သည်ကိုဖျက်ရန်သေချာပါသလား?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ပယ်ဖျက်'),
          ),
          TextButton(
            onPressed: () {
              LocalDb.deleteCustomer(customerId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ဖောက်သည်ဖျက်ပြီးပါပြီ')),
              );
            },
            child: const Text('ဖျက်မည်'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => _PaymentFormDialog(
        customer: customer,
        onSave: (payment) {
          LocalDb.recordPayment(payment);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ငွေပေးချေမှုမှတ်တမ်းတင်ပြီးပါပြီ')),
          );
          setState(() {});
        },
      ),
    );
  }

  void _showLedgerDialog(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => _CustomerLedgerDialog(customer: customer),
    );
  }
}

class _CustomerFormDialog extends StatefulWidget {
  final Customer? existing;
  final Function(Customer) onSave;

  const _CustomerFormDialog({
    required this.existing,
    required this.onSave,
  });

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late final TextEditingController _openingBalanceController;
  late final TextEditingController _creditLimitController;
  late String _status;
  late String _customerId;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _customerId = existing?.id ?? const Uuid().v4();
    _nameController = TextEditingController(text: existing?.name ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _addressController = TextEditingController(text: existing?.address ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _openingBalanceController = TextEditingController(
      text: existing?.openingBalance.toString() ?? '0',
    );
    _creditLimitController = TextEditingController(
      text: existing?.creditLimit.toString() ?? '0',
    );
    _status = existing?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _openingBalanceController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() => _phoneError = null);

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ဖောက်သည်အမည်ထည့်သွင်းပါ')),
      );
      return false;
    }

    if (_phoneController.text.isNotEmpty) {
      if (LocalDb.phoneExists(_phoneController.text,
          excludeCustomerId: widget.existing?.id)) {
        setState(() => _phoneError = 'ဤဖုန်းနံပါတ်ကိုအခြားဖောက်သည်မှာရှိပြီးပါပြီ');
        return false;
      }
    }

    try {
      double.parse(_openingBalanceController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('မူလကြွေးမြတ်သည်ကိန်းဂဏန်းဖြစ်ရမည်')),
      );
      return false;
    }

    try {
      double.parse(_creditLimitController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('အကြွေးကန့်သတ်သည်ကိန်းဂဏန်းဖြစ်ရမည်')),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'ဖောက်သည်ထည့်သွင်း' : 'ဖောက်သည်ပြင်ဆင်'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ဖောက်သည်အမည် *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'ဖုန်းနံပါတ်',
                border: const OutlineInputBorder(),
                errorText: _phoneError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'လိပ်စာ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _openingBalanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'မူလကြွေးမြတ်',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _creditLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'အကြွေးကန့်သတ်',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'အခြေအနေ',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('왕성')),
                DropdownMenuItem(value: 'inactive', child: Text('ပိတ်ထားသည်')),
              ],
              onChanged: (value) => setState(() => _status = value ?? 'active'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'မှတ်ချက်',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ပယ်ဖျက်'),
        ),
        TextButton(
          onPressed: () {
            if (_validate()) {
              final customer = Customer(
                id: _customerId,
                name: _nameController.text.trim(),
                phone: _phoneController.text.trim().isEmpty
                    ? null
                    : _phoneController.text.trim(),
                address: _addressController.text.trim().isEmpty
                    ? null
                    : _addressController.text.trim(),
                notes: _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
                openingBalance: double.parse(_openingBalanceController.text),
                currentBalance: widget.existing?.currentBalance ??
                    double.parse(_openingBalanceController.text),
                creditLimit: double.parse(_creditLimitController.text),
                status: _status,
                createdAt: widget.existing?.createdAt ??
                    DateTime.now().millisecondsSinceEpoch,
              );
              widget.onSave(customer);
            }
          },
          child: const Text('သိမ်းဆည်း'),
        ),
      ],
    );
  }
}

// ============================================================================
// Payment Form Dialog
// ============================================================================
class _PaymentFormDialog extends StatefulWidget {
  final Customer customer;
  final Function(Payment) onSave;

  const _PaymentFormDialog({
    required this.customer,
    required this.onSave,
  });

  @override
  State<_PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<_PaymentFormDialog> {
  late final NumberFormat _money;
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _paymentDate;
  String _method = 'cash';
  late final NumberFormat _currencyFormat;

  @override
  void initState() {
    super.initState();
    _money = NumberFormat('#,##0', 'my_MM');
    _currencyFormat = NumberFormat('#,##0.00', 'my_MM');
    _paymentDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ငွေပေးချေမှု ထည့်သွင်း'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ဖောက်သည်: ${widget.customer.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'လက်ရှိကြွေးမြတ်: ${_money.format(widget.customer.currentBalance)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Payment date
            Text(
              'ငွေပေးချေမှုရက်စွဲ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _paymentDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _paymentDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(DateFormat('dd/MM/yyyy').format(_paymentDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Amount
            Text(
              'ငွေပေးချေမှုပမာဏ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'ပမာဏထည့်သွင်းပါ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            // Payment method
            Text(
              'ငွေပေးချေမှုနည်းလမ်း',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _method,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('ငွေသားငွေ')),
                DropdownMenuItem(value: 'bank', child: Text('ဘဏ်')),
              ],
              onChanged: (value) => setState(() => _method = value ?? 'cash'),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            // Reference number
            Text(
              'ကိုးကားအမှတ်',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                hintText: 'ကိုးကားအမှတ် (ရွေးချယ်)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            // Note
            Text(
              'မှတ်ချက်',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'မှတ်ချက် (ရွေးချယ်)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ပယ်ဖျက်'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text);
            if (amount == null || amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ပမာဏ ၀ より大きい ဖြစ်ရမည်')),
              );
              return;
            }
            if (amount > widget.customer.currentBalance) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ပမာဏသည် လက်ရှိကြွေးမြတ်ထက် မကြီးရမည်')),
              );
              return;
            }

            final payment = Payment(
              id: const Uuid().v4(),
              customerId: widget.customer.id,
              paymentDate: _paymentDate.millisecondsSinceEpoch,
              amount: amount,
              method: _method,
              referenceNo: _referenceController.text.isEmpty
                  ? null
                  : _referenceController.text,
              note: _noteController.text.isEmpty ? null : _noteController.text,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            );
            widget.onSave(payment);
          },
          child: const Text('သိမ်းဆည်း'),
        ),
      ],
    );
  }
}

// ============================================================================
// Customer Ledger Dialog
// ============================================================================
class _CustomerLedgerDialog extends StatefulWidget {
  final Customer customer;

  const _CustomerLedgerDialog({required this.customer});

  @override
  State<_CustomerLedgerDialog> createState() => _CustomerLedgerDialogState();
}

class _CustomerLedgerDialogState extends State<_CustomerLedgerDialog> {
  late final NumberFormat _money;

  @override
  void initState() {
    super.initState();
    _money = NumberFormat('#,##0', 'my_MM');
  }

  String _getTransactionTypeLabel(String type) {
    switch (type) {
      case 'sale':
        return 'ရောင်းချမှု';
      case 'payment':
        return 'ငွေပေးချေမှု';
      case 'adjustment':
        return 'ညှိနှိုင်းခြင်း';
      case 'refund':
        return 'ပြန်အမ်းခြင်း';
      default:
        return type;
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'ငွေသားငွေ';
      case 'bank':
        return 'ဘဏ်';
      case 'credit':
        return 'အကြွေး';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ledgerEntries = LocalDb.getCustomerLedger(widget.customer.id);
    final payments = LocalDb.getCustomerPayments(widget.customer.id);

    return AlertDialog(
      title: const Text('ဖောက်သည်စာရင်း'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer info header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ဖောက်သည်: ${widget.customer.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'လက်ရှိကြွေးမြတ်',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              _money.format(widget.customer.currentBalance),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'အကြွေးကန့်သတ်',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              _money.format(widget.customer.creditLimit),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Ledger entries
            if (ledgerEntries.isEmpty && payments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'စာရင်းမှတ်တမ်းမရှိသေးပါ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              )
            else
              Column(
                children: [
                  Text(
                    'ငွေပေးချေမှုမှတ်တမ်း',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  ...payments.map((payment) => _buildPaymentRow(payment)),
                  if (ledgerEntries.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'အခြားစာရင်းမှတ်တမ်း',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    ...ledgerEntries
                        .where((e) => e.type != 'payment')
                        .map((entry) => _buildLedgerRow(entry)),
                  ],
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ပိတ်မည်'),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(Payment payment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(Icons.payment, size: 20, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ငွေပေးချေမှု - ${_getPaymentMethodLabel(payment.method)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(
                      DateTime.fromMillisecondsSinceEpoch(payment.paymentDate),
                    ),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              _money.format(payment.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerRow(CustomerLedger entry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(
              entry.type == 'sale' ? Icons.shopping_cart : Icons.edit,
              size: 20,
              color: entry.debitAmount > 0 ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTransactionTypeLabel(entry.type),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(
                      DateTime.fromMillisecondsSinceEpoch(entry.date),
                    ),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (entry.debitAmount > 0)
                  Text(
                    _money.format(entry.debitAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                if (entry.creditAmount > 0)
                  Text(
                    _money.format(entry.creditAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
