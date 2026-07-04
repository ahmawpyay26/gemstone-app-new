import 'package:hive/hive.dart';

/// All local data models for the offline-first Gemstone app.
/// Manual Hive TypeAdapters are used to avoid code generation during CI builds.

// ---------------------------------------------------------------------------
// User
// ---------------------------------------------------------------------------
class AppUser {
  String id;
  String name;
  String email;
  String username; // username for login (unique)
  String passwordHash; // hashed password (never plaintext)
  String password; // DEPRECATED: kept for backward compatibility only
  String role; // owner | admin | user
  int createdAt;
  int updatedAt; // timestamp of last update

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.username = '',
    this.passwordHash = '',
    this.password = '', // DEPRECATED
    required this.role,
    required this.createdAt,
    int? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;
}

class AppUserAdapter extends TypeAdapter<AppUser> {
  @override
  final int typeId = 1;

  @override
  AppUser read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return AppUser(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      password: (fields[3] as String?) ?? '',
      role: fields[4] as String,
      createdAt: fields[5] as int,
      username: (fields[6] as String?) ?? '',
      passwordHash: (fields[7] as String?) ?? '',
      updatedAt: (fields[8] as int?) ?? fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AppUser obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.username)
      ..writeByte(7)
      ..write(obj.passwordHash)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }
}

// ---------------------------------------------------------------------------
// Gemstone (Inventory)
// ---------------------------------------------------------------------------
class Gemstone {
  String id;
  String name; // ကျောက်အမည်
  String type; // အမျိုးအစား (e.g., Ruby, Sapphire, Jade)
  double weightCarat; // အလေးချိန် တန်ဖိုး (ယူနစ်ပေါ်မူတည်)
  String weightUnit; // carat | kg | viss
  double costPrice; // ဝယ်ဈေး
  double commissionFee; // ပွဲခ (ဝယ်ယူစဉ် ပေးရသည့်ပွဲခ)
  double processingFee; // ဆီဖိုး
  double repairFee; // ပြုပြင်ခ
  double breakageFee; // ဖျက်ခ
  double bloodFee; // သွေးခ
  double laborFee; // အလုပ်သမားခ
  double miscFee; // အထွေထွေ
  double sellPrice; // ရောင်းဈေး
  int quantity; // အရေအတွက်
  String color;
  String origin; // မူရင်းနေရာ
  String status; // in_stock | sold | reserved
  String note;
  int createdAt;
  
  // Product-wise Independent Ledger Fields
  double totalCost; // စုစုပေါင်းအရင်း (costPrice + fees)
  double remainingCost; // ကျန်ရှိအရင်း (ရောင်းချတိုင်း နှုတ်ပြီး)
  // totalProfit is CALCULATED from Sales records, not stored
  int remainingQuantity; // ကျန်ရှိအရေအတွက်
  int soldQuantity; // ရောင်းပြီးအရေအတွက်
  List<String> photoPaths; // ဓာတ်ပုံ file paths
  Map<String, int> breakdownItems; // breakdown item name -> quantity
  
  // Cost/Profit Tracking for Breakdown Items
  double originalPurchaseCost; // ကုန်ကျစာရင်း (Set once, never changes)
  double remainingCostBalance; // ကျန်ရှိအရင်းကျ (Reduces on sales)
  double recoveredCost; // ပြန်လည်ရရှိသောအရင်း (Increases on sales)
  double? totalProfit; // စုစုပေါင်းအမြတ် (Only after cost fully recovered)
  double? totalSalesRevenue; // စုစုပေါင်းရောင်းချငွေ (Total revenue from all sales)

  Gemstone({
    required this.id,
    required this.name,
    required this.type,
    required this.weightCarat,
    this.weightUnit = 'carat',
    required this.costPrice,
    this.commissionFee = 0,
    this.processingFee = 0,
    this.repairFee = 0,
    this.breakageFee = 0,
    this.bloodFee = 0,
    this.laborFee = 0,
    this.miscFee = 0,
    this.sellPrice = 0,
    required this.quantity,
    required this.color,
    required this.origin,
    required this.status,
    required this.note,
    required this.createdAt,
    this.totalCost = 0,
    this.remainingCost = 0,
    this.remainingQuantity = 0,
    this.soldQuantity = 0,
    this.photoPaths = const [],
    this.breakdownItems = const {},
    this.originalPurchaseCost = 0,
    this.remainingCostBalance = 0,
    this.recoveredCost = 0,
    this.totalProfit,
    this.totalSalesRevenue,
  });
}

class GemstoneAdapter extends TypeAdapter<Gemstone> {
  @override
  final int typeId = 2;

  @override
  Gemstone read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return Gemstone(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      weightCarat: (fields[3] as num).toDouble(),
      costPrice: (fields[4] as num).toDouble(),
      sellPrice: (fields[5] as num).toDouble(),
      quantity: fields[6] as int,
      color: fields[7] as String,
      origin: fields[8] as String,
      status: fields[9] as String,
      note: fields[10] as String,
      createdAt: fields[11] as int,
      weightUnit: (fields[12] as String?) ?? 'carat',
      commissionFee:
          fields[13] == null ? 0 : (fields[13] as num).toDouble(),
      processingFee:
          fields[14] == null ? 0 : (fields[14] as num).toDouble(),
      repairFee:
          fields[15] == null ? 0 : (fields[15] as num).toDouble(),
      breakageFee:
          fields[16] == null ? 0 : (fields[16] as num).toDouble(),
      bloodFee:
          fields[17] == null ? 0 : (fields[17] as num).toDouble(),
      laborFee:
          fields[18] == null ? 0 : (fields[18] as num).toDouble(),
      miscFee:
          fields[19] == null ? 0 : (fields[19] as num).toDouble(),
      totalCost: fields[20] == null ? 0 : (fields[20] as num).toDouble(),
      remainingCost: fields[21] == null ? 0 : (fields[21] as num).toDouble(),
      remainingQuantity: fields[22] == null ? 0 : (fields[22] as int),
      soldQuantity: fields[23] == null ? 0 : (fields[23] as int),
      photoPaths: (fields[24] as List<dynamic>?)?.cast<String>() ?? [],
      breakdownItems: (fields[25] as Map<dynamic, dynamic>?)?.cast<String, int>() ?? {},
      originalPurchaseCost: fields[26] == null ? 0 : (fields[26] as num).toDouble(),
      remainingCostBalance: fields[27] == null ? 0 : (fields[27] as num).toDouble(),
      recoveredCost: fields[28] == null ? 0 : (fields[28] as num).toDouble(),
      totalProfit: fields[29] == null ? null : (fields[29] as num).toDouble(),
      totalSalesRevenue: fields[30] == null ? null : (fields[30] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Gemstone obj) {
    writer
      ..writeByte(31)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.weightCarat)
      ..writeByte(4)
      ..write(obj.costPrice)
      ..writeByte(5)
      ..write(obj.sellPrice)
      ..writeByte(6)
      ..write(obj.quantity)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.origin)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.note)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.weightUnit)
      ..writeByte(13)
      ..write(obj.commissionFee)
      ..writeByte(14)
      ..write(obj.processingFee)
      ..writeByte(15)
      ..write(obj.repairFee)
      ..writeByte(16)
      ..write(obj.breakageFee)
      ..writeByte(17)
      ..write(obj.bloodFee)
      ..writeByte(18)
      ..write(obj.laborFee)
      ..writeByte(19)
      ..write(obj.miscFee)
      ..writeByte(20)
      ..write(obj.totalCost)
      ..writeByte(21)
      ..write(obj.remainingCost)
      ..writeByte(22)
      ..write(obj.remainingQuantity)
      ..writeByte(23)
      ..write(obj.soldQuantity)
      ..writeByte(24)
      ..write(obj.photoPaths)
      ..writeByte(25)
      ..write(obj.breakdownItems)
      ..writeByte(26)
      ..write(obj.originalPurchaseCost)
      ..writeByte(27)
      ..write(obj.remainingCostBalance)
      ..writeByte(28)
      ..write(obj.recoveredCost)
      ..writeByte(29)
      ..write(obj.totalProfit)
      ..writeByte(30)
      ..write(obj.totalSalesRevenue);
  }
}

// ---------------------------------------------------------------------------
// Expense (အစ်တွချပ်မရေအ)
// ---------------------------------------------------------------------------
class Sale {
  String id;
  String gemstoneId; // ဆက်စပ်ကျောက်မျက် id (ဗလာဖြစ်နိုင်)
  String gemstoneName; // ရောင်းသည့်ကျောက်
  String? customerId; // ဖောက်သည် ID (Customer Master reference)
  String customerName; // ဝယ်သူအမည် (backward compatibility)
  double amount; // ရောင်းရငွေ (gross revenue)
  double costPrice; // ရောင်းသည့်ပစ္စည်း ၏ စုစုပေါင်းအရင်း (cost of goods sold)
  double commissionFee; // ပွဲခ (ရောင်းစဉ် ပေးရသည့်ပွဲခ)
  int quantity;
  double weightCarat; // အလေးချိန် တန်ဖိုး (ယူနစ်ပေါ်မူတည်)
  String paymentMethod; // cash | bank | credit
  String note;
  int saleDate;
  
  // Detailed Transaction History Fields
  double netSale; // Selling Price - Commission
  double costUsed; // ဒီအကြိမ်ရောင်းချမှာ သုံးစွဲတဲ့ အရင်း
  double remainingCostAfterSale; // ရောင်းပြီးနောက် ကျန်ရှိအရင်း
  double profitGenerated; // ဒီအကြိမ်ရောင်းချမှ ရရှိတဲ့ အမြတ်
  double accumulatedProfit; // စုစုပေါင်းအမြတ် (ယခုအထိ)
  
  // Soft Delete Fields
  bool isDeleted; // Soft delete flag
  int? deletedAt; // Deletion timestamp
  String? deletedBy; // User who deleted
  String? deleteReason; // Reason for deletion
  
  // Photo Attachments
  List<String> photoPaths; // ဓာတ်ပုံ file paths
  
  // Multi-Item Invoice Support
  String invoiceNumber; // Invoice number for grouping multiple sales (e.g., INV-2026-07-04-0001)

  Sale({
    required this.id,
    this.gemstoneId = '',
    required this.gemstoneName,
    this.customerId,
    required this.customerName,
    required this.amount,
    this.costPrice = 0,
    this.commissionFee = 0,
    required this.quantity,
    this.weightCarat = 0,
    required this.paymentMethod,
    required this.note,
    required this.saleDate,
    this.netSale = 0,
    this.costUsed = 0,
    this.remainingCostAfterSale = 0,
    this.profitGenerated = 0,
    this.accumulatedProfit = 0,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
    this.deleteReason,
    this.photoPaths = const [],
    this.invoiceNumber = '',
  });
}

class SaleAdapter extends TypeAdapter<Sale> {
  @override
  final int typeId = 3;

  @override
  Sale read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return Sale(
      id: fields[0] as String,
      gemstoneName: fields[1] as String,
      customerId: fields[22] as String?,
      customerName: fields[2] as String,
      amount: (fields[3] as num).toDouble(),
      quantity: fields[4] as int,
      paymentMethod: fields[5] as String,
      note: fields[6] as String,
      saleDate: fields[7] as int,
      gemstoneId: (fields[8] as String?) ?? '',
      weightCarat: fields[9] == null ? 0 : (fields[9] as num).toDouble(),
      costPrice: fields[10] == null ? 0 : (fields[10] as num).toDouble(),
      commissionFee:
          fields[11] == null ? 0 : (fields[11] as num).toDouble(),
      netSale: fields[12] == null ? 0 : (fields[12] as num).toDouble(),
      costUsed: fields[13] == null ? 0 : (fields[13] as num).toDouble(),
      remainingCostAfterSale: fields[14] == null ? 0 : (fields[14] as num).toDouble(),
      profitGenerated: fields[15] == null ? 0 : (fields[15] as num).toDouble(),
      accumulatedProfit: fields[16] == null ? 0 : (fields[16] as num).toDouble(),
      isDeleted: (fields[17] as bool?) ?? false,
      deletedAt: fields[18] as int?,
      deletedBy: fields[19] as String?,
      deleteReason: fields[20] as String?,
      photoPaths: (fields[21] as List<dynamic>?)?.cast<String>() ?? [],
      invoiceNumber: (fields[23] as String?) ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Sale obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.gemstoneName)
      ..writeByte(2)
      ..write(obj.customerName)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.paymentMethod)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.saleDate)
      ..writeByte(8)
      ..write(obj.gemstoneId)
      ..writeByte(9)
      ..write(obj.weightCarat)
      ..writeByte(10)
      ..write(obj.costPrice)
      ..writeByte(11)
      ..write(obj.commissionFee)
      ..writeByte(12)
      ..write(obj.netSale)
      ..writeByte(13)
      ..write(obj.costUsed)
      ..writeByte(14)
      ..write(obj.remainingCostAfterSale)
      ..writeByte(15)
      ..write(obj.profitGenerated)
      ..writeByte(16)
      ..write(obj.accumulatedProfit)
      ..writeByte(17)
      ..write(obj.isDeleted)
      ..writeByte(18)
      ..write(obj.deletedAt)
      ..writeByte(19)
      ..write(obj.deletedBy)
      ..writeByte(20)
      ..write(obj.deleteReason)
      ..writeByte(21)
      ..write(obj.photoPaths)
      ..writeByte(22)
      ..write(obj.customerId)
      ..writeByte(23)
      ..write(obj.invoiceNumber);
  }
}

// ---------------------------------------------------------------------------
// Expense (အသုံးစရိတ်)
// ---------------------------------------------------------------------------
class Expense {
  String id;
  String title; // အသုံးစရိတ်အမည်
  String category; // အမျိုးအစား
  double amount;
  String note;
  int expenseDate;

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.note,
    required this.expenseDate,
  });
}

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 4;

  @override
  Expense read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as String,
      amount: (fields[3] as num).toDouble(),
      note: fields[4] as String,
      expenseDate: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.expenseDate);
  }
}

// ---------------------------------------------------------------------------
// Worker (အလုပ်သမား)
// ---------------------------------------------------------------------------
class Worker {
  String id;
  String name;
  String role; // ရာထူး/တာဝန်
  String phone;
  double salary; // လစာ
  String status; // active | inactive
  String note;
  int createdAt;

  Worker({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.salary,
    required this.status,
    required this.note,
    required this.createdAt,
  });
}

class WorkerAdapter extends TypeAdapter<Worker> {
  @override
  final int typeId = 5;

  @override
  Worker read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return Worker(
      id: fields[0] as String,
      name: fields[1] as String,
      role: fields[2] as String,
      phone: fields[3] as String,
      salary: (fields[4] as num).toDouble(),
      status: fields[5] as String,
      note: fields[6] as String,
      createdAt: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Worker obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.salary)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.createdAt);
  }
}

// ---------------------------------------------------------------------------
// AuditLog (အကျင့်စာရင်း)
// ---------------------------------------------------------------------------
class AuditLog {
  String id;
  String action; // DELETE_SALE, ADD_SALE, EDIT_SALE, ADD_PURCHASE, EDIT_PURCHASE, DELETE_PURCHASE
  String? saleId; // ဆက်စပ်သော Sale Record ID
  String? gemstoneId; // ဆက်စပ်သော Gemstone ID
  String? gemstoneName; // ကျောက်အမည်
  int? quantity; // အလုံးရေ
  double? amount; // အငွေ
  String userId; // User ID
  String userName; // User အမည်
  int timestamp; // ပြုလုပ်ချိန် (milliseconds since epoch)
  String details; // အသေးစိတ်အချက်အလက်

  AuditLog({
    required this.id,
    required this.action,
    this.saleId,
    this.gemstoneId,
    this.gemstoneName,
    this.quantity,
    this.amount,
    required this.userId,
    required this.userName,
    required this.timestamp,
    required this.details,
  });
}

class AuditLogAdapter extends TypeAdapter<AuditLog> {
  @override
  final int typeId = 6;

  @override
  AuditLog read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return AuditLog(
      id: fields[0] as String,
      action: fields[1] as String,
      saleId: (fields[2] as String?),
      gemstoneId: (fields[3] as String?),
      gemstoneName: (fields[4] as String?),
      quantity: (fields[5] as int?),
      amount: fields[6] == null ? null : (fields[6] as num).toDouble(),
      userId: fields[7] as String,
      userName: fields[8] as String,
      timestamp: fields[9] as int,
      details: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AuditLog obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.action)
      ..writeByte(2)
      ..write(obj.saleId)
      ..writeByte(3)
      ..write(obj.gemstoneId)
      ..writeByte(4)
      ..write(obj.gemstoneName)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.amount)
      ..writeByte(7)
      ..write(obj.userId)
      ..writeByte(8)
      ..write(obj.userName)
      ..writeByte(9)
      ..write(obj.timestamp)
      ..writeByte(10)
      ..write(obj.details);
  }
}


// ---------------------------------------------------------------------------
// RBAC: Permission
// ---------------------------------------------------------------------------
class Permission {
  String id;
  String name; // e.g., "Dashboard", "Inventory", "Sales", "Delete", "Export"
  String description;

  Permission({
    required this.id,
    required this.name,
    this.description = '',
  });
}

class PermissionAdapter extends TypeAdapter<Permission> {
  @override
  final int typeId = 7;

  @override
  Permission read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return Permission(
      id: fields[0] as String,
      name: fields[1] as String,
      description: (fields[2] as String?) ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Permission obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description);
  }
}

// ---------------------------------------------------------------------------
// RBAC: Role
// ---------------------------------------------------------------------------
class Role {
  String id;
  String name; // e.g., "Super Admin", "Staff", "Viewer"
  List<String> permissionIds; // list of permission IDs
  String description;

  Role({
    required this.id,
    required this.name,
    this.permissionIds = const [],
    this.description = '',
  });
}

class RoleAdapter extends TypeAdapter<Role> {
  @override
  final int typeId = 8;

  @override
  Role read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return Role(
      id: fields[0] as String,
      name: fields[1] as String,
      permissionIds: (fields[2] as List?)?.cast<String>() ?? [],
      description: (fields[3] as String?) ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Role obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.permissionIds)
      ..writeByte(3)
      ..write(obj.description);
  }
}

// ---------------------------------------------------------------------------
// RBAC: StaffUser
// ---------------------------------------------------------------------------
class StaffUser {
  String id;
  String fullName;
  String username; // unique
  String passwordHash; // hashed password
  String phoneNumber;
  String position; // e.g., "Sales Manager", "Inventory Staff"
  String roleId; // reference to Role
  List<String> permissionIds; // direct permission list (can override role permissions)
  bool isActive; // Active / Disabled
  int createdAt;
  int updatedAt;
  String createdBy; // user ID who created this staff
  int? lastLoginAt; // timestamp of last login

  StaffUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.passwordHash,
    required this.phoneNumber,
    required this.position,
    required this.roleId,
    this.permissionIds = const [],
    this.isActive = true,
    required this.createdAt,
    int? updatedAt,
    required this.createdBy,
    this.lastLoginAt,
  }) : updatedAt = updatedAt ?? createdAt;
}

class StaffUserAdapter extends TypeAdapter<StaffUser> {
  @override
  final int typeId = 9;

  @override
  StaffUser read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return StaffUser(
      id: fields[0] as String,
      fullName: fields[1] as String,
      username: fields[2] as String,
      passwordHash: fields[3] as String,
      phoneNumber: fields[4] as String,
      position: fields[5] as String,
      roleId: fields[6] as String,
      permissionIds: (fields[7] as List?)?.cast<String>() ?? [],
      isActive: (fields[8] as bool?) ?? true,
      createdAt: fields[9] as int,
      updatedAt: (fields[10] as int?) ?? fields[9] as int,
      createdBy: fields[11] as String,
      lastLoginAt: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, StaffUser obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fullName)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.passwordHash)
      ..writeByte(4)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.position)
      ..writeByte(6)
      ..write(obj.roleId)
      ..writeByte(7)
      ..write(obj.permissionIds)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.createdBy)
      ..writeByte(12)
      ..write(obj.lastLoginAt);
  }
}


// ---------------------------------------------------------------------------
// Broker Consignment
// ---------------------------------------------------------------------------

/// Historical data snapshot captured at broker consignment creation
class BrokerHistoricalData {
  String purchaseName; // Gemstone name at time of consignment
  int purchaseDate; // Purchase date (timestamp)
  String originalSeller; // Seller name at time of consignment
  String gemstoneType; // Gemstone type at time of consignment
  String sourceType; // "whole_stone" or "breakdown_item"
  String? breakdownItemName; // Name if sourceType is "breakdown_item"
  double originalQuantity; // Purchase quantity at time of consignment
  double originalWeight; // Purchase weight at time of consignment
  int capturedAt; // When this snapshot was taken (timestamp)

  BrokerHistoricalData({
    required this.purchaseName,
    required this.purchaseDate,
    required this.originalSeller,
    required this.gemstoneType,
    required this.sourceType,
    this.breakdownItemName,
    required this.originalQuantity,
    required this.originalWeight,
    required this.capturedAt,
  });
}

class BrokerHistoricalDataAdapter extends TypeAdapter<BrokerHistoricalData> {
  @override
  final int typeId = 10;

  @override
  BrokerHistoricalData read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return BrokerHistoricalData(
      purchaseName: fields[0] as String,
      purchaseDate: fields[1] as int,
      originalSeller: fields[2] as String,
      gemstoneType: fields[3] as String,
      sourceType: fields[4] as String,
      breakdownItemName: fields[5] as String?,
      originalQuantity: fields[6] as double,
      originalWeight: fields[7] as double,
      capturedAt: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BrokerHistoricalData obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.purchaseName)
      ..writeByte(1)
      ..write(obj.purchaseDate)
      ..writeByte(2)
      ..write(obj.originalSeller)
      ..writeByte(3)
      ..write(obj.gemstoneType)
      ..writeByte(4)
      ..write(obj.sourceType)
      ..writeByte(5)
      ..write(obj.breakdownItemName)
      ..writeByte(6)
      ..write(obj.originalQuantity)
      ..writeByte(7)
      ..write(obj.originalWeight)
      ..writeByte(8)
      ..write(obj.capturedAt);
  }
}

/// Broker Consignment Record
class BrokerConsignment {
  String id;
  String purchaseId; // Permanent reference to source Purchase Record
  
  // Current Status
  double consignedQuantity;
  double soldQuantity;
  double returnedQuantity;
  
  // Historical Data (Immutable)
  BrokerHistoricalData historicalData;
  
  // Broker Information
  String brokerName;
  String brokerPhone;
  String brokerAddress;
  String? brokerSocialAccount;
  
  // Additional Information
  String notes;
  List<String> photoPaths; // Paths to broker photos
  
  // Timestamps
  int createdAt;
  int updatedAt;
  int? deletedAt; // Soft delete support

  BrokerConsignment({
    required this.id,
    required this.purchaseId,
    required this.consignedQuantity,
    this.soldQuantity = 0,
    this.returnedQuantity = 0,
    required this.historicalData,
    required this.brokerName,
    required this.brokerPhone,
    required this.brokerAddress,
    this.brokerSocialAccount,
    this.notes = '',
    this.photoPaths = const [],
    required this.createdAt,
    int? updatedAt,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  /// Calculate remaining quantity with broker
  double get remainingQuantity => consignedQuantity - soldQuantity - returnedQuantity;

  /// Check if this broker consignment is active (not deleted)
  bool get isActive => deletedAt == null;

  /// Check if this broker consignment is completed (no remaining quantity)
  bool get isCompleted => remainingQuantity <= 0;
}

class BrokerConsignmentAdapter extends TypeAdapter<BrokerConsignment> {
  @override
  final int typeId = 11;

  @override
  BrokerConsignment read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return BrokerConsignment(
      id: fields[0] as String,
      purchaseId: fields[1] as String,
      consignedQuantity: fields[2] as double,
      soldQuantity: (fields[3] as double?) ?? 0,
      returnedQuantity: (fields[4] as double?) ?? 0,
      historicalData: fields[5] as BrokerHistoricalData,
      brokerName: fields[6] as String,
      brokerPhone: fields[7] as String,
      brokerAddress: fields[8] as String,
      brokerSocialAccount: fields[9] as String?,
      notes: (fields[10] as String?) ?? '',
      photoPaths: (fields[11] as List?)?.cast<String>() ?? [],
      createdAt: fields[12] as int,
      updatedAt: (fields[13] as int?) ?? fields[12] as int,
      deletedAt: fields[14] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, BrokerConsignment obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.purchaseId)
      ..writeByte(2)
      ..write(obj.consignedQuantity)
      ..writeByte(3)
      ..write(obj.soldQuantity)
      ..writeByte(4)
      ..write(obj.returnedQuantity)
      ..writeByte(5)
      ..write(obj.historicalData)
      ..writeByte(6)
      ..write(obj.brokerName)
      ..writeByte(7)
      ..write(obj.brokerPhone)
      ..writeByte(8)
      ..write(obj.brokerAddress)
      ..writeByte(9)
      ..write(obj.brokerSocialAccount)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.photoPaths)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.deletedAt);
  }
}

// ---------------------------------------------------------------------------
// Broker Sale Record (Individual Sale Transactions)
// ---------------------------------------------------------------------------
class BrokerSaleRecord {
  String id; // Unique sale record ID
  String brokerConsignmentId; // Reference to broker consignment
  String purchaseId; // Reference to original purchase
  
  // Source Information
  String sourceType; // whole_stone | breakdown_item
  String? breakdownItemName; // Name of breakdown item if sourceType == breakdown_item
  
  // Sale Details
  double soldQuantity;
  double unitPrice;
  double totalSaleAmount;
  double brokerCommission;
  double netAmount; // totalSaleAmount - brokerCommission
  
  // Additional Information
  String? buyerName;
  String remark;
  
  // Timestamps
  int saleDate; // Unix timestamp of sale
  int createdAt;
  int updatedAt;

  BrokerSaleRecord({
    required this.id,
    required this.brokerConsignmentId,
    required this.purchaseId,
    required this.sourceType,
    this.breakdownItemName,
    required this.soldQuantity,
    required this.unitPrice,
    required this.totalSaleAmount,
    required this.brokerCommission,
    required this.netAmount,
    this.buyerName,
    this.remark = '',
    required this.saleDate,
    required this.createdAt,
    int? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  /// Validate sale record data
  String? validate() {
    if (soldQuantity <= 0) return 'Sold quantity must be greater than 0';
    if (unitPrice < 0) return 'Unit price cannot be negative';
    if (totalSaleAmount <= 0) return 'Total sale amount must be greater than 0';
    if (brokerCommission < 0) return 'Broker commission cannot be negative';
    if (netAmount < 0) return 'Net amount cannot be negative';
    
    // Verify calculation
    final expectedNetAmount = totalSaleAmount - brokerCommission;
    if ((netAmount - expectedNetAmount).abs() > 0.01) {
      return 'Net amount calculation is incorrect';
    }
    
    return null;
  }
}

class BrokerSaleRecordAdapter extends TypeAdapter<BrokerSaleRecord> {
  @override
  final int typeId = 12;

  @override
  BrokerSaleRecord read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return BrokerSaleRecord(
      id: fields[0] as String,
      brokerConsignmentId: fields[1] as String,
      purchaseId: fields[2] as String,
      sourceType: fields[3] as String,
      breakdownItemName: fields[4] as String?,
      soldQuantity: fields[5] as double,
      unitPrice: fields[6] as double,
      totalSaleAmount: fields[7] as double,
      brokerCommission: fields[8] as double,
      netAmount: fields[9] as double,
      buyerName: fields[10] as String?,
      remark: (fields[11] as String?) ?? '',
      saleDate: fields[12] as int,
      createdAt: fields[13] as int,
      updatedAt: (fields[14] as int?) ?? fields[13] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BrokerSaleRecord obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.brokerConsignmentId)
      ..writeByte(2)
      ..write(obj.purchaseId)
      ..writeByte(3)
      ..write(obj.sourceType)
      ..writeByte(4)
      ..write(obj.breakdownItemName)
      ..writeByte(5)
      ..write(obj.soldQuantity)
      ..writeByte(6)
      ..write(obj.unitPrice)
      ..writeByte(7)
      ..write(obj.totalSaleAmount)
      ..writeByte(8)
      ..write(obj.brokerCommission)
      ..writeByte(9)
      ..write(obj.netAmount)
      ..writeByte(10)
      ..write(obj.buyerName)
      ..writeByte(11)
      ..write(obj.remark)
      ..writeByte(12)
      ..write(obj.saleDate)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt);
  }
}


// ---------------------------------------------------------------------------
// Customer (ဖောက်သည်)
// ---------------------------------------------------------------------------
class Customer {
  String id;                    // Unique customer ID (UUID)
  String name;                  // Customer name (ဖောက်သည်အမည်)
  String? phone;                // Phone number (optional)
  String? address;              // Address (optional)
  String? notes;                // Notes (optional)
  double openingBalance;        // Opening balance (မူလကြွေးမြတ်)
  double currentBalance;        // Current balance (လက်ရှိကြွေးမြတ်)
  double creditLimit;           // Credit limit (အကြွေးကန့်သတ်)
  String status;                // active | inactive
  bool isDeleted;               // Soft delete flag
  int? deletedAt;               // Deletion timestamp
  int createdAt;                // Creation timestamp
  int updatedAt;                // Last update timestamp

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.notes,
    this.openingBalance = 0,
    this.currentBalance = 0,
    this.creditLimit = 0,
    this.status = 'active',
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    int? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;
}

class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 13;

  @override
  Customer read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return Customer(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: (fields[2] as String?) ?? '',
      address: (fields[3] as String?) ?? '',
      notes: (fields[4] as String?) ?? '',
      openingBalance: (fields[5] as num?)?.toDouble() ?? 0,
      currentBalance: (fields[6] as num?)?.toDouble() ?? 0,
      creditLimit: (fields[7] as num?)?.toDouble() ?? 0,
      status: (fields[8] as String?) ?? 'active',
      isDeleted: (fields[9] as bool?) ?? false,
      deletedAt: fields[10] as int?,
      createdAt: fields[11] as int,
      updatedAt: (fields[12] as int?) ?? fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone ?? '')
      ..writeByte(3)
      ..write(obj.address ?? '')
      ..writeByte(4)
      ..write(obj.notes ?? '')
      ..writeByte(5)
      ..write(obj.openingBalance)
      ..writeByte(6)
      ..write(obj.currentBalance)
      ..writeByte(7)
      ..write(obj.creditLimit)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.isDeleted)
      ..writeByte(10)
      ..write(obj.deletedAt)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }
}


// ---------------------------------------------------------------------------
// CustomerLedger (ဖောက်သည်အကောင့်)
// ---------------------------------------------------------------------------
class CustomerLedger {
  String id;                    // Unique ledger entry ID (UUID)
  String customerId;            // Reference to Customer
  String type;                  // sale | payment | adjustment | refund
  String? referenceId;          // Reference to sale or payment ID
  int date;                     // Transaction date (timestamp)
  double debitAmount;           // Amount owed (ကြွေးမြတ်)
  double creditAmount;          // Amount paid (ငွေပေးချေ)
  double balanceAfter;          // Running balance after transaction
  String? note;                 // Transaction note
  int createdAt;                // Creation timestamp

  CustomerLedger({
    required this.id,
    required this.customerId,
    required this.type,
    this.referenceId,
    required this.date,
    this.debitAmount = 0,
    this.creditAmount = 0,
    required this.balanceAfter,
    this.note,
    required this.createdAt,
  });
}

class CustomerLedgerAdapter extends TypeAdapter<CustomerLedger> {
  @override
  final int typeId = 14;

  @override
  CustomerLedger read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return CustomerLedger(
      id: fields[0] as String,
      customerId: fields[1] as String,
      type: fields[2] as String,
      referenceId: fields[3] as String?,
      date: fields[4] as int,
      debitAmount: (fields[5] as num?)?.toDouble() ?? 0,
      creditAmount: (fields[6] as num?)?.toDouble() ?? 0,
      balanceAfter: (fields[7] as num?)?.toDouble() ?? 0,
      note: fields[8] as String?,
      createdAt: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerLedger obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.referenceId)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.debitAmount)
      ..writeByte(6)
      ..write(obj.creditAmount)
      ..writeByte(7)
      ..write(obj.balanceAfter)
      ..writeByte(8)
      ..write(obj.note)
      ..writeByte(9)
      ..write(obj.createdAt);
  }
}

// ---------------------------------------------------------------------------
// Payment (ငွေပေးချေမှု)
// ---------------------------------------------------------------------------
class Payment {
  String id;                    // Unique payment ID (UUID)
  String customerId;            // Reference to Customer
  String? saleId;               // Optional reference to Sale
  int paymentDate;              // Payment date (timestamp)
  double amount;                // Payment amount (ငွေပေးချေမှုပမာဏ)
  String method;                // cash | bank | credit
  String? referenceNo;          // Reference number (optional)
  String? note;                 // Payment note
  bool isDeleted;               // Soft delete flag
  int createdAt;                // Creation timestamp

  Payment({
    required this.id,
    required this.customerId,
    this.saleId,
    required this.paymentDate,
    required this.amount,
    required this.method,
    this.referenceNo,
    this.note,
    this.isDeleted = false,
    required this.createdAt,
  });
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 15;

  @override
  Payment read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      id: fields[0] as String,
      customerId: fields[1] as String,
      saleId: fields[2] as String?,
      paymentDate: fields[3] as int,
      amount: (fields[4] as num?)?.toDouble() ?? 0,
      method: fields[5] as String,
      referenceNo: fields[6] as String?,
      note: fields[7] as String?,
      isDeleted: (fields[8] as bool?) ?? false,
      createdAt: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.saleId)
      ..writeByte(3)
      ..write(obj.paymentDate)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.method)
      ..writeByte(6)
      ..write(obj.referenceNo)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.isDeleted)
      ..writeByte(9)
      ..write(obj.createdAt);
  }
}
