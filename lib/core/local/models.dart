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
    );
  }

  @override
  void write(BinaryWriter writer, Gemstone obj) {
    writer
      ..writeByte(24)
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
      ..write(obj.soldQuantity);
  }
}

// ---------------------------------------------------------------------------
// Sale (ရောင်းချမှု)
// ---------------------------------------------------------------------------
class Sale {
  String id;
  String gemstoneId; // ဆက်စပ်ကျောက်မျက် id (ဗလာဖြစ်နိုင်)
  String gemstoneName; // ရောင်းသည့်ကျောက်
  String customerName; // ဝယ်သူအမည်
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

  Sale({
    required this.id,
    this.gemstoneId = '',
    required this.gemstoneName,
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
    );
  }

  @override
  void write(BinaryWriter writer, Sale obj) {
    writer
      ..writeByte(21)
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
      ..write(obj.deleteReason);
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
