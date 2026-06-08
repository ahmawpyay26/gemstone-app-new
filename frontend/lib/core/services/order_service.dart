import 'package:uuid/uuid.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/models/ecommerce_models.dart';

class OrderService {
  final AppDatabase database;

  OrderService(this.database);

  // ============ ORDER VALIDATION ============

  /// Validates customer information before creating order
  /// Returns error message if validation fails, null if valid
  Future<String?> validateCustomerInfo(CustomerModel customer) async {
    if (customer.name.trim().isEmpty) {
      return 'အမည် မည်သည့်ကြေးမျ မဖြည့်သွင်းရသေးပါ';
    }
    if (customer.phone.trim().isEmpty) {
      return 'ဖုန်းနံပါတ် မည်သည့်ကြေးမျ မဖြည့်သွင်းရသေးပါ';
    }
    if (customer.address.trim().isEmpty) {
      return 'လိပ်စာ မည်သည့်ကြေးမျ မဖြည့်သွင်းရသေးပါ';
    }

    // Validate phone number format (basic)
    if (!_isValidPhoneNumber(customer.phone)) {
      return 'ဖုန်းနံပါတ် မှားမှားကျေးဇူးပြု၍ ပြန်စစ်ဆေးပါ';
    }

    return null; // Valid
  }

  /// Validates order items
  Future<String?> validateOrderItems(List<OrderItemModel> items) async {
    if (items.isEmpty) {
      return 'အနည်းဆုံး ပစ္စည်း တစ်ခု ရွေးချယ်ရန် လိုအပ်သည်';
    }

    for (var item in items) {
      if (item.quantity <= 0) {
        return 'ပစ္စည်း အရေအတွက် သုည ထက် များရန် လိုအပ်သည်';
      }

      final product = await database.getProductById(item.productId);
      if (product == null) {
        return 'ပစ္စည်း မတွေ့ရှိပါ';
      }

      if (product.quantity < item.quantity) {
        return 'ပစ္စည်း အလုံအလောက် မရှိပါ။ ရှိသည့် အရေအတွက်: ${product.quantity}';
      }
    }

    return null; // Valid
  }

  // ============ ORDER CREATION ============

  Future<OrderModel> createOrder({
    required CustomerModel customer,
    required String staffId,
    required List<OrderItemModel> items,
    double discountAmount = 0.0,
    String? notes,
  }) async {
    // Validate customer
    final customerError = await validateCustomerInfo(customer);
    if (customerError != null) throw Exception(customerError);

    // Validate items
    final itemsError = await validateOrderItems(items);
    if (itemsError != null) throw Exception(itemsError);

    // Create or update customer
    final customerId = customer.id.isEmpty ? const Uuid().v4() : customer.id;
    final customerToSave = customer.copyWith(
      id: customerId,
      lastUpdated: DateTime.now(),
    );
    await database.insertOrUpdateCustomer(
      LocalCustomer(
        id: customerToSave.id,
        name: customerToSave.name,
        phone: customerToSave.phone,
        email: customerToSave.email,
        address: customerToSave.address,
        city: customerToSave.city,
        state: customerToSave.state,
        zipCode: customerToSave.zipCode,
        createdAt: customerToSave.createdAt,
        lastUpdated: customerToSave.lastUpdated,
        isSynced: false,
      ),
    );

    // Calculate totals
    double totalAmount = 0.0;
    for (var item in items) {
      totalAmount += item.totalPrice;
    }

    final finalAmount = totalAmount - discountAmount;

    // Create order
    final orderId = const Uuid().v4();
    final now = DateTime.now();

    final order = LocalOrder(
      id: orderId,
      customerId: customerId,
      staffId: staffId,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
      status: 'pending',
      paymentStatus: 'unpaid',
      notes: notes,
      orderDate: now,
      deliveryDate: null,
      createdAt: now,
      lastUpdated: now,
      isSynced: false,
    );

    await database.insertOrUpdateOrder(order);

    // Create order items and update product quantities
    for (var item in items) {
      final orderItem = LocalOrderItem(
        id: const Uuid().v4(),
        orderId: orderId,
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        totalPrice: item.totalPrice,
        createdAt: now,
        isSynced: false,
      );

      await database.insertOrUpdateOrderItem(orderItem);

      // Update product quantity
      final product = await database.getProductById(item.productId);
      if (product != null) {
        final newQuantity = product.quantity - item.quantity;
        await database.updateProductQuantity(item.productId, newQuantity);
      }
    }

    return OrderModel(
      id: orderId,
      customerId: customerId,
      staffId: staffId,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
      status: 'pending',
      paymentStatus: 'unpaid',
      notes: notes,
      orderDate: now,
      deliveryDate: null,
      createdAt: now,
      lastUpdated: now,
      items: items,
    );
  }

  // ============ ORDER MANAGEMENT ============

  Future<OrderModel?> getOrderById(String orderId) async {
    final order = await database.getOrderById(orderId);
    if (order == null) return null;

    final items = await database.getOrderItems(orderId);

    return OrderModel(
      id: order.id,
      customerId: order.customerId,
      staffId: order.staffId,
      totalAmount: order.totalAmount,
      discountAmount: order.discountAmount,
      finalAmount: order.finalAmount,
      status: order.status,
      paymentStatus: order.paymentStatus,
      notes: order.notes,
      orderDate: order.orderDate,
      deliveryDate: order.deliveryDate,
      createdAt: order.createdAt,
      lastUpdated: order.lastUpdated,
      items: items
          .map((i) => OrderItemModel(
                id: i.id,
                orderId: i.orderId,
                productId: i.productId,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
                totalPrice: i.totalPrice,
                createdAt: i.createdAt,
              ))
          .toList(),
    );
  }

  Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    final orders = await database.getOrdersByCustomerId(customerId);
    final result = <OrderModel>[];

    for (var order in orders) {
      final items = await database.getOrderItems(order.id);
      result.add(OrderModel(
        id: order.id,
        customerId: order.customerId,
        staffId: order.staffId,
        totalAmount: order.totalAmount,
        discountAmount: order.discountAmount,
        finalAmount: order.finalAmount,
        status: order.status,
        paymentStatus: order.paymentStatus,
        notes: order.notes,
        orderDate: order.orderDate,
        deliveryDate: order.deliveryDate,
        createdAt: order.createdAt,
        lastUpdated: order.lastUpdated,
        items: items
            .map((i) => OrderItemModel(
                  id: i.id,
                  orderId: i.orderId,
                  productId: i.productId,
                  quantity: i.quantity,
                  unitPrice: i.unitPrice,
                  totalPrice: i.totalPrice,
                  createdAt: i.createdAt,
                ))
            .toList(),
      ));
    }

    return result;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await database.updateOrderStatus(orderId, status);
  }

  Future<void> deleteOrder(String orderId) async {
    // Get order items to restore product quantities
    final items = await database.getOrderItems(orderId);

    for (var item in items) {
      final product = await database.getProductById(item.productId);
      if (product != null) {
        final newQuantity = product.quantity + item.quantity;
        await database.updateProductQuantity(item.productId, newQuantity);
      }
    }

    // Delete order items
    await database.deleteOrderItemsByOrderId(orderId);

    // Delete order
    await database.deleteOrder(orderId);
  }

  // ============ HELPER METHODS ============

  bool _isValidPhoneNumber(String phone) {
    // Simple validation - at least 7 digits
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return digits.length >= 7;
  }

  Future<double> calculateOrderTotal(List<OrderItemModel> items) async {
    double total = 0.0;
    for (var item in items) {
      total += item.totalPrice;
    }
    return total;
  }
}
