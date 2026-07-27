import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gemstone_management/core/local/local_db.dart';
import 'package:gemstone_management/core/local/models.dart';
import 'package:gemstone_management/core/theme/app_theme.dart';

/// Reusable customer selector widget with autocomplete and creation support
/// Returns Customer object on selection
class CustomerSelector extends StatefulWidget {
  /// Callback when a customer is selected
  final Function(Customer) onCustomerSelected;

  /// Initial customer (optional)
  final Customer? initialCustomer;

  /// Label text (optional)
  final String? labelText;

  /// Hint text (optional)
  final String? hintText;

  /// Allow clearing selection (optional, default true)
  final bool allowClear;

  const CustomerSelector({
    Key? key,
    required this.onCustomerSelected,
    this.initialCustomer,
    this.labelText,
    this.hintText,
    this.allowClear = true,
  }) : super(key: key);

  @override
  State<CustomerSelector> createState() => _CustomerSelectorState();
}

class _CustomerSelectorState extends State<CustomerSelector> {
  late TextEditingController _textController;
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.initialCustomer;
    _textController = TextEditingController(
      text: widget.initialCustomer?.name ?? '',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showCreateCustomerDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('ဖောက်သည်အသစ်ထည့်ရန်'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'ဖောက်သည်အမည်',
                hintText: 'ဖောက်သည်အမည်ထည့်သွင်းပါ',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ပယ်ဖျက်မည်'),
          ),
          TextButton(
            onPressed: () async {
              final customerName = nameController.text.trim();
              if (customerName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ဖောက်သည်အမည်ထည့်သွင်းပါ')),
                );
                return;
              }

              // Check for duplicate (case-insensitive)
              final existingCustomer = LocalDb.customers()
                  .values
                  .firstWhereOrNull((c) =>
                      c.name.toLowerCase() == customerName.toLowerCase() &&
                      !c.isDeleted);

              if (existingCustomer != null) {
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _selectedCustomer = existingCustomer;
                    _textController.text = existingCustomer.name;
                  });
                  widget.onCustomerSelected(existingCustomer);
                }
                return;
              }

              // Create new customer
              final newCustomer = Customer(
                id: LocalDb.genId(),
                name: customerName,
                phone: '',
                address: '',
                notes: '',
                openingBalance: 0.0,
                currentBalance: 0.0,
                creditLimit: 0.0,
                status: 'active',
                isDeleted: false,
                deletedAt: null,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              );

              await LocalDb.customers().add(newCustomer);

              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _selectedCustomer = newCustomer;
                  _textController.text = newCustomer.name;
                });
                widget.onCustomerSelected(newCustomer);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ဖောက်သည်အသစ်ထည့်သွင်းပြီးပါပြီ')),
                );
              }
            },
            child: const Text('သိမ်းဆည်းမည်'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Customer>>(
      valueListenable: LocalDb.customers().listenable(),
      builder: (context, box, _) {
        final activeCustomers = box.values
            .where((c) => !c.isDeleted && c.status == 'active')
            .toList();

        return Autocomplete<Customer>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return activeCustomers;
            }
            final searchText = textEditingValue.text.toLowerCase();
            return activeCustomers
                .where((c) => c.name.toLowerCase().contains(searchText))
                .toList();
          },
          onSelected: (Customer customer) {
            setState(() {
              _selectedCustomer = customer;
              _textController.text = customer.name;
            });
            widget.onCustomerSelected(customer);
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted) {
            // Sync the text controller
            if (_selectedCustomer != null &&
                textEditingController.text != _selectedCustomer!.name) {
              textEditingController.text = _selectedCustomer!.name;
            }
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.labelText ?? 'ဖောက်သည်အမည်',
                hintText: widget.hintText ?? 'ဖောက်သည်အမည်ထည့်သွင်းပါ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: widget.allowClear && _selectedCustomer != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          textEditingController.clear();
                          setState(() {
                            _selectedCustomer = null;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                // Clear selection when user modifies text
                if (value.isEmpty) {
                  setState(() {
                    _selectedCustomer = null;
                  });
                }
              },
            );
          },
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<Customer> onSelected,
              Iterable<Customer> options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: Container(
                    color: AppTheme.surfaceLight,
                    child: options.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: InkWell(
                              onTap: () => _showCreateCustomerDialog(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Text('➕ '),
                                    Text('ဖောက်သည်အသစ် ထည့်မည်'),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: options.length + 1,
                            itemBuilder: (BuildContext context, int index) {
                              if (index == options.length) {
                                return InkWell(
                                  onTap: () => _showCreateCustomerDialog(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: Colors.white24),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 8.0),
                                    child: const Row(
                                      children: [
                                        Text('➕ '),
                                        Text('ဖောက်သည်အသစ် ထည့်မည်'),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              final customer = options.elementAt(index);
                              return InkWell(
                                onTap: () {
                                  onSelected(customer);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      if (customer.phone != null &&
                                          customer.phone!.isNotEmpty)
                                        Text(
                                          customer.phone!,
                                          style: const TextStyle(
                                              fontSize: 11, color: Colors.white70),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
