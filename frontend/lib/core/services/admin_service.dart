import 'package:uuid/uuid.dart';
import '../../data/datasources/local/app_database.dart';
import '../../data/models/ecommerce_models.dart';

class AdminService {
  final AppDatabase database;

  AdminService(this.database);

  // ============ STAFF MANAGEMENT ============

  Future<void> createStaff({
    required String name,
    required String email,
    required String phone,
    required String role,
    required String password,
  }) async {
    final id = const Uuid().v4();
    final passwordHash = _hashPassword(password);

    final staff = LocalStaff(
      id: id,
      name: name,
      email: email,
      phone: phone,
      role: role,
      passwordHash: passwordHash,
      isActive: true,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      isSynced: false,
    );

    await database.insertOrUpdateStaff(staff);
  }

  Future<void> updateStaff({
    required String staffId,
    String? name,
    String? phone,
    String? role,
    bool? isActive,
  }) async {
    final staff = await database.getStaffById(staffId);
    if (staff == null) throw Exception('Staff not found');

    final updated = staff.copyWith(
      name: name,
      phone: phone,
      role: role,
      isActive: isActive,
      lastUpdated: DateTime.now(),
    );

    await database.insertOrUpdateStaff(updated);
  }

  Future<void> deleteStaff(String staffId) async {
    await database.deleteStaff(staffId);
  }

  Future<List<StaffModel>> getAllStaff() async {
    final staffList = await database.getAllStaff();
    return staffList
        .map((s) => StaffModel(
              id: s.id,
              name: s.name,
              email: s.email,
              phone: s.phone,
              role: s.role,
              passwordHash: s.passwordHash,
              isActive: s.isActive,
              createdAt: s.createdAt,
              lastUpdated: s.lastUpdated,
            ))
        .toList();
  }

  Future<bool> validateStaffPassword(String email, String password) async {
    final staff = await database.getStaffByEmail(email);
    if (staff == null) return false;
    return _verifyPassword(password, staff.passwordHash);
  }

  // ============ PRODUCT MANAGEMENT ============

  Future<void> createProduct({
    required String name,
    required String category,
    required double price,
    required String sku,
    String? description,
    String? qrCode,
    String? imageUrl,
  }) async {
    final id = const Uuid().v4();

    final product = LocalProduct(
      id: id,
      name: name,
      description: description,
      category: category,
      price: price,
      quantity: 0,
      sku: sku,
      qrCode: qrCode,
      imageUrl: imageUrl,
      isActive: true,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      isSynced: false,
    );

    await database.insertOrUpdateProduct(product);
  }

  Future<void> updateProduct({
    required String productId,
    String? name,
    String? description,
    String? category,
    double? price,
    int? quantity,
    String? qrCode,
    String? imageUrl,
    bool? isActive,
  }) async {
    final product = await database.getProductById(productId);
    if (product == null) throw Exception('Product not found');

    final updated = product.copyWith(
      name: name,
      description: description,
      category: category,
      price: price,
      quantity: quantity,
      qrCode: qrCode,
      imageUrl: imageUrl,
      isActive: isActive,
      lastUpdated: DateTime.now(),
    );

    await database.insertOrUpdateProduct(updated);
  }

  Future<void> deleteProduct(String productId) async {
    await database.deleteProduct(productId);
  }

  Future<List<ProductModel>> getAllProducts() async {
    final products = await database.getAllProducts();
    return products
        .map((p) => ProductModel(
              id: p.id,
              name: p.name,
              description: p.description,
              category: p.category,
              price: p.price,
              quantity: p.quantity,
              sku: p.sku,
              qrCode: p.qrCode,
              imageUrl: p.imageUrl,
              isActive: p.isActive,
              createdAt: p.createdAt,
              lastUpdated: p.lastUpdated,
            ))
        .toList();
  }

  Future<void> updateProductPrice(String productId, double newPrice) async {
    final product = await database.getProductById(productId);
    if (product == null) throw Exception('Product not found');

    final updated = product.copyWith(
      price: newPrice,
      lastUpdated: DateTime.now(),
    );

    await database.insertOrUpdateProduct(updated);
  }

  // ============ ORDER MANAGEMENT ============

  Future<void> deleteOrder(String orderId) async {
    // Delete order items first
    await database.deleteOrderItemsByOrderId(orderId);
    // Then delete order
    await database.deleteOrder(orderId);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await database.updateOrderStatus(orderId, status);
  }

  Future<List<OrderModel>> getAllOrders() async {
    final orders = await database.getAllOrders();
    return orders
        .map((o) => OrderModel(
              id: o.id,
              customerId: o.customerId,
              staffId: o.staffId,
              totalAmount: o.totalAmount,
              discountAmount: o.discountAmount,
              finalAmount: o.finalAmount,
              status: o.status,
              paymentStatus: o.paymentStatus,
              notes: o.notes,
              orderDate: o.orderDate,
              deliveryDate: o.deliveryDate,
              createdAt: o.createdAt,
              lastUpdated: o.lastUpdated,
            ))
        .toList();
  }

  // ============ ANALYTICS ============

  Future<double> getTotalSales() async {
    return await database.getTotalSalesAmount();
  }

  Future<double> getTotalExpenses() async {
    return await database.getTotalExpensesAmount();
  }

  Future<double> getProfit() async {
    final sales = await getTotalSales();
    final expenses = await getTotalExpenses();
    return sales - expenses;
  }

  Future<int> getTotalOrders() async {
    return await database.getTotalOrdersCount();
  }

  Future<int> getTotalCustomers() async {
    return await database.getTotalCustomersCount();
  }

  // ============ HELPER METHODS ============

  String _hashPassword(String password) {
    // Simple hash for demo (use bcrypt in production)
    return password.hashCode.toString();
  }

  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }
}
