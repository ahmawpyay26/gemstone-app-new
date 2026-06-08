import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ecommerce_models.dart';

class OrderCreatePage extends StatefulWidget {
  const OrderCreatePage({Key? key}) : super(key: key);

  @override
  State<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends State<OrderCreatePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Customer Information
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  
  // Order Items
  List<OrderItemModel> _orderItems = [];
  
  // Discount
  double _discountAmount = 0.0;
  String? _notes;
  
  // Available Products (Mock data)
  final List<ProductModel> _availableProducts = [
    ProductModel(
      id: '1',
      name: 'Ruby - 2.5ct',
      category: 'Gemstone',
      price: 5000000,
      quantity: 10,
      sku: 'RUB-001',
      isActive: true,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    ),
    ProductModel(
      id: '2',
      name: 'Sapphire - 1.8ct',
      category: 'Gemstone',
      price: 3500000,
      quantity: 15,
      sku: 'SAP-001',
      isActive: true,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    ),
    ProductModel(
      id: '3',
      name: 'Emerald - 1.5ct',
      category: 'Gemstone',
      price: 4200000,
      quantity: 8,
      sku: 'EME-001',
      isActive: true,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('အမှာစာ ထည့်သွင်းရန်'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Information Section
              Text(
                'ဆိုင်ဖက်အချက်အလက်',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryAccent,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'အမည် *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'အမည် မည်သည့်ကြေးမျ မဖြည့်သွင်းရသေးပါ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'ဖုန်းနံပါတ် *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'ဖုန်းနံပါတ် မည်သည့်ကြေးမျ မဖြည့်သွင်းရသေးပါ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Address Field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'လိပ်စာ *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'လိပ်စာ မည်သည့်ကြေးမျ မဖြည့်သွင်းရသေးပါ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Email Field (Optional)
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'အီးမေးလ်',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              
              // Order Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'အမှာစာ ပစ္စည်းများ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryAccent,
                        ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddItemDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('ပစ္စည်း ထည့်သွင်း'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Order Items List
              if (_orderItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'ပစ္စည်း မထည့်သွင်းရသေးပါ',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _orderItems.length,
                  itemBuilder: (context, index) {
                    final item = _orderItems[index];
                    return _buildOrderItemCard(context, item, index);
                  },
                ),
              const SizedBox(height: 24),
              
              // Discount Section
              Text(
                'ကျေးဇူးခွင့်',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _discountAmount.toString(),
                decoration: InputDecoration(
                  labelText: 'ကျေးဇူးခွင့် (MMK)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.discount),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _discountAmount = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              // Notes Section
              Text(
                'မှတ်ချက်များ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'မှတ်ချက်များ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 3,
                onChanged: (value) {
                  _notes = value;
                },
              ),
              const SizedBox(height: 24),
              
              // Order Summary
              _buildOrderSummary(context),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ပယ်ဖျက်ရန်'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                      ),
                      onPressed: _submitOrder,
                      child: const Text('အမှာစာ သိမ်းဆည်းရန်'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemCard(BuildContext context, OrderItemModel item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ပစ္စည်း #${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'အရေအတွက်: ${item.quantity} | ယူနစ် စျေး: ${item.unitPrice.toStringAsFixed(0)} MMK',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'စုစုပေါင်း: ${item.totalPrice.toStringAsFixed(0)} MMK',
                  style: const TextStyle(
                    color: AppTheme.primaryAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppTheme.errorColor),
            onPressed: () {
              setState(() {
                _orderItems.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context) {
    double totalAmount = 0;
    for (var item in _orderItems) {
      totalAmount += item.totalPrice;
    }
    final finalAmount = totalAmount - _discountAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('စုစုပေါင်း:', style: Theme.of(context).textTheme.bodyMedium),
              Text('${totalAmount.toStringAsFixed(0)} MMK', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ကျေးဇူးခွင့်:', style: Theme.of(context).textTheme.bodyMedium),
              Text('- ${_discountAmount.toStringAsFixed(0)} MMK', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const Divider(color: AppTheme.primaryAccent),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'နောက်ဆုံး စျေး:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryAccent,
                    ),
              ),
              Text(
                '${finalAmount.toStringAsFixed(0)} MMK',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ပစ္စည်း ရွေးချယ်ရန်'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _availableProducts.map((product) {
              return ListTile(
                title: Text(product.name),
                subtitle: Text('${product.price.toStringAsFixed(0)} MMK'),
                onTap: () {
                  Navigator.pop(context);
                  _showQuantityDialog(product);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showQuantityDialog(ProductModel product) {
    final quantityController = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('အရေအတွက် ရွေးချယ်ရန် - ${product.name}'),
        content: TextFormField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'အရေအတွက်',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ပယ်ဖျက်ရန်'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text) ?? 1;
              if (quantity > 0 && quantity <= product.quantity) {
                setState(() {
                  _orderItems.add(OrderItemModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    orderId: '',
                    productId: product.id,
                    quantity: quantity,
                    unitPrice: product.price,
                    totalPrice: product.price * quantity,
                    createdAt: DateTime.now(),
                  ));
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('မှားမှားကျေးဇူးပြု၍ အရေအတွက် ပြန်စစ်ဆေးပါ')),
                );
              }
            },
            child: const Text('ထည့်သွင်း'),
          ),
        ],
      ),
    );
  }

  void _submitOrder() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ကျေးဇူးပြု၍ လိုအပ်သည့် အချက်အလက်များ ဖြည့်သွင်းပါ')),
      );
      return;
    }

    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('အနည်းဆုံး ပစ္စည်း တစ်ခု ရွေးချယ်ရန် လိုအပ်သည်')),
      );
      return;
    }

    // TODO: Save order to database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('အမှာစာ သိမ်းဆည်းပြီးပါပြီ')),
    );
    Navigator.pop(context);
  }
}
