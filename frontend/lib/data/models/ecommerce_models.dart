import 'package:json_annotation/json_annotation.dart';

part 'ecommerce_models.g.dart';

// ============ STAFF MODEL ============
@JsonSerializable()
class StaffModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'admin', 'staff', 'user'
  final String passwordHash;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastUpdated;

  StaffModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.passwordHash,
    required this.isActive,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) =>
      _$StaffModelFromJson(json);
  Map<String, dynamic> toJson() => _$StaffModelToJson(this);

  StaffModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? passwordHash,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return StaffModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      passwordHash: passwordHash ?? this.passwordHash,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// ============ PRODUCT MODEL ============
@JsonSerializable()
class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String category;
  final double price;
  final int quantity;
  final String sku;
  final String? qrCode;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastUpdated;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    required this.quantity,
    required this.sku,
    this.qrCode,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    int? quantity,
    String? sku,
    String? qrCode,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      sku: sku ?? this.sku,
      qrCode: qrCode ?? this.qrCode,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// ============ CUSTOMER MODEL ============
@JsonSerializable()
class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String address;
  final String? city;
  final String? state;
  final String? zipCode;
  final DateTime createdAt;
  final DateTime lastUpdated;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.address,
    this.city,
    this.state,
    this.zipCode,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerModelFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerModelToJson(this);

  bool isComplete() {
    return name.isNotEmpty && phone.isNotEmpty && address.isNotEmpty;
  }

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// ============ ORDER ITEM MODEL ============
@JsonSerializable()
class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime createdAt;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);

  OrderItemModel copyWith({
    String? id,
    String? orderId,
    String? productId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    DateTime? createdAt,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ============ ORDER MODEL ============
@JsonSerializable()
class OrderModel {
  final String id;
  final String customerId;
  final String staffId;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String status; // pending, completed, cancelled
  final String paymentStatus; // unpaid, paid, partial
  final String? notes;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final List<OrderItemModel>? items; // Optional for nested data

  OrderModel({
    required this.id,
    required this.customerId,
    required this.staffId,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.status,
    required this.paymentStatus,
    this.notes,
    required this.orderDate,
    this.deliveryDate,
    required this.createdAt,
    required this.lastUpdated,
    this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? staffId,
    double? totalAmount,
    double? discountAmount,
    double? finalAmount,
    String? status,
    String? paymentStatus,
    String? notes,
    DateTime? orderDate,
    DateTime? deliveryDate,
    DateTime? createdAt,
    DateTime? lastUpdated,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      staffId: staffId ?? this.staffId,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      items: items ?? this.items,
    );
  }
}

// ============ EXPENSE MODEL ============
@JsonSerializable()
class ExpenseModel {
  final String id;
  final String description;
  final String category;
  final double amount;
  final String? staffId;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime lastUpdated;

  ExpenseModel({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    this.staffId,
    required this.expenseDate,
    required this.createdAt,
    required this.lastUpdated,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseModelToJson(this);

  ExpenseModel copyWith({
    String? id,
    String? description,
    String? category,
    double? amount,
    String? staffId,
    DateTime? expenseDate,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      description: description ?? this.description,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      staffId: staffId ?? this.staffId,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
