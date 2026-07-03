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
