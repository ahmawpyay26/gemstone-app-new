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
  String password; // stored locally (plain for offline demo accounts)
  String role; // owner | admin | user
  int createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.createdAt,
  });
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
      password: fields[3] as String,
      role: fields[4] as String,
      createdAt: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AppUser obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.createdAt);
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
  double sellPrice; // ရောင်းဈေး
  int quantity; // အရေအတွက်
  String color;
  String origin; // မူရင်းနေရာ
  String status; // in_stock | sold | reserved
  String note;
  int createdAt;

  Gemstone({
    required this.id,
    required this.name,
    required this.type,
    required this.weightCarat,
    this.weightUnit = 'carat',
    required this.costPrice,
    this.commissionFee = 0,
    this.sellPrice = 0,
    required this.quantity,
    required this.color,
    required this.origin,
    required this.status,
    required this.note,
    required this.createdAt,
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
    );
  }

  @override
  void write(BinaryWriter writer, Gemstone obj) {
    writer
      ..writeByte(14)
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
      ..write(obj.commissionFee);
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
    );
  }

  @override
  void write(BinaryWriter writer, Sale obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.commissionFee);
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
