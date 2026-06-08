import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/ecommerce_models.dart';

class OrdersListPage extends StatefulWidget {
  const OrdersListPage({Key? key}) : super(key: key);

  @override
  State<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends State<OrdersListPage> {
  // Mock orders data
  final List<OrderModel> _orders = [
    OrderModel(
      id: '001',
      customerId: 'cust001',
      staffId: 'staff001',
      totalAmount: 12500000,
      discountAmount: 500000,
      finalAmount: 12000000,
      status: 'completed',
      paymentStatus: 'paid',
      notes: 'ပြီးဆုံးပြီး',
      orderDate: DateTime.now().subtract(const Duration(days: 2)),
      deliveryDate: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
    ),
    OrderModel(
      id: '002',
      customerId: 'cust002',
      staffId: 'staff001',
      totalAmount: 45000000,
      discountAmount: 2000000,
      finalAmount: 43000000,
      status: 'pending',
      paymentStatus: 'unpaid',
      notes: 'စောင့်ဆိုင်းနေ',
      orderDate: DateTime.now(),
      deliveryDate: null,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    ),
    OrderModel(
      id: '003',
      customerId: 'cust003',
      staffId: 'staff002',
      totalAmount: 5000000,
      discountAmount: 0,
      finalAmount: 5000000,
      status: 'completed',
      paymentStatus: 'paid',
      notes: 'ပြီးဆုံးပြီး',
      orderDate: DateTime.now().subtract(const Duration(days: 5)),
      deliveryDate: DateTime.now().subtract(const Duration(days: 4)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      lastUpdated: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  String _filterStatus = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _orders.where((order) {
      final statusMatch = _filterStatus == 'all' || order.status == _filterStatus;
      final searchMatch = _searchQuery.isEmpty || 
          order.id.contains(_searchQuery) || 
          order.customerId.contains(_searchQuery);
      return statusMatch && searchMatch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('အမှာစာများ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/order-create');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'အမှာစာ ID သို့မဟုတ် ဆိုင်ဖက် ID ရှာပါ',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Filter Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton('အားလုံး', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterButton('စောင့်ဆိုင်း', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterButton('ပြီးဆုံး', 'completed'),
                  const SizedBox(width: 8),
                  _buildFilterButton('ပယ်ဖျက်ထား', 'cancelled'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Orders List
            if (filteredOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 48,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'အမှာစာ မရှိသေးပါ',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                  return _buildOrderCard(context, order);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String status) {
    final isSelected = _filterStatus == status;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryAccent : AppTheme.surfaceDark,
        foregroundColor: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
      ),
      onPressed: () {
        setState(() {
          _filterStatus = status;
        });
      },
      child: Text(label),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final statusColor = _getStatusColor(order.status);
    final paymentStatusColor = _getPaymentStatusColor(order.paymentStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'အမှာစာ #${order.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryAccent,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ဆိုင်ဖက် ID: ${order.customerId}',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(order.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Order Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'စုစုပေါင်း:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.finalAmount.toStringAsFixed(0)} MMK',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryAccent,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ငွေချေးမှု:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: paymentStatusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getPaymentStatusLabel(order.paymentStatus),
                      style: TextStyle(
                        color: paymentStatusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'မှာယူ သည့် နေ့:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(order.orderDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showOrderDetails(context, order);
                  },
                  child: const Text('အသေးစိတ်'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _showEditOrderDialog(context, order);
                  },
                  child: const Text('ပြင်ဆင်ရန်'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppTheme.successColor;
      case 'unpaid':
        return AppTheme.errorColor;
      case 'partial':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'ပြီးဆုံး';
      case 'pending':
        return 'စောင့်ဆိုင်း';
      case 'cancelled':
        return 'ပယ်ဖျက်ထား';
      default:
        return status;
    }
  }

  String _getPaymentStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'ငွေချေးပြီး';
      case 'unpaid':
        return 'ငွေမချေး';
      case 'partial':
        return 'တစ်ခြင်းခြင်း';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('အမှာစာ #${order.id} အသေးစိတ်'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('အမှာစာ ID:', order.id),
              _buildDetailRow('ဆိုင်ဖက် ID:', order.customerId),
              _buildDetailRow('အဆင်သည့်သူ ID:', order.staffId),
              _buildDetailRow('စုစုပေါင်း:', '${order.totalAmount.toStringAsFixed(0)} MMK'),
              _buildDetailRow('ကျေးဇူးခွင့်:', '${order.discountAmount.toStringAsFixed(0)} MMK'),
              _buildDetailRow('နောက်ဆုံး စျေး:', '${order.finalAmount.toStringAsFixed(0)} MMK'),
              _buildDetailRow('အမှာစာ အခြေအနေ:', _getStatusLabel(order.status)),
              _buildDetailRow('ငွေချေးမှု အခြေအနေ:', _getPaymentStatusLabel(order.paymentStatus)),
              if (order.notes != null) _buildDetailRow('မှတ်ချက်:', order.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ပိတ်ရန်'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showEditOrderDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('အမှာစာ #${order.id} ပြင်ဆင်ရန်'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: order.status,
                decoration: const InputDecoration(
                  labelText: 'အမှာစာ အခြေအနေ',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('စောင့်ဆိုင်း')),
                  DropdownMenuItem(value: 'completed', child: Text('ပြီးဆုံး')),
                  DropdownMenuItem(value: 'cancelled', child: Text('ပယ်ဖျက်ထား')),
                ],
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: order.paymentStatus,
                decoration: const InputDecoration(
                  labelText: 'ငွေချေးမှု အခြေအနေ',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'unpaid', child: Text('ငွေမချေး')),
                  DropdownMenuItem(value: 'paid', child: Text('ငွေချေးပြီး')),
                  DropdownMenuItem(value: 'partial', child: Text('တစ်ခြင်းခြင်း')),
                ],
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ပယ်ဖျက်ရန်'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('အမှာစာ အဆင့်မြှင့်တင်ပြီးပါပြီ')),
              );
            },
            child: const Text('သိမ်းဆည်း'),
          ),
        ],
      ),
    );
  }
}
