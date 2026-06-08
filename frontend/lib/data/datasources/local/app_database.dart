import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ============ ECOMMERCE TABLES ============

// 1. Staff/Users Table
class LocalStaff extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  TextColumn get phone => text()();
  TextColumn get role => text()(); // 'admin', 'staff', 'user'
  TextColumn get passwordHash => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. Products/Gemstones Table
class LocalProducts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text()(); // 'gemstone', 'jewelry', etc.
  RealColumn get price => real()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  TextColumn get sku => text().unique()();
  TextColumn get qrCode => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 3. Customers Table
class LocalCustomers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text()();
  TextColumn get city => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get zipCode => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 4. Orders Table
class LocalOrders extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get staffId => text()();
  RealColumn get totalAmount => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get finalAmount => real()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, completed, cancelled
  TextColumn get paymentStatus => text().withDefault(const Constant('unpaid'))(); // unpaid, paid, partial
  TextColumn get notes => text().nullable()();
  DateTimeColumn get orderDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deliveryDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 5. Order Items Table
class LocalOrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text()();
  TextColumn get productId => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get totalPrice => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 6. Expenses Table
class LocalExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get description => text()();
  TextColumn get category => text()(); // 'salary', 'rent', 'utilities', etc.
  RealColumn get amount => real()();
  TextColumn get staffId => text().nullable()();
  DateTimeColumn get expenseDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 7. Legacy Gemstones Table (kept for backward compatibility)
class LocalGemstones extends Table {
  TextColumn get id => text()();
  TextColumn get qrCode => text()();
  TextColumn get type => text()();
  RealColumn get caratWeight => real()();
  TextColumn get status => text()();
  RealColumn get totalCost => real()();
  TextColumn get lotId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============ DATABASE CONFIGURATION ============

@DriftDatabase(tables: [
  LocalStaff,
  LocalProducts,
  LocalCustomers,
  LocalOrders,
  LocalOrderItems,
  LocalExpenses,
  LocalGemstones,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  // ============ STAFF METHODS ============
  Future<List<LocalStaff>> getAllStaff() => select(localStaff).get();

  Future<LocalStaff?> getStaffById(String id) =>
      (select(localStaff)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<LocalStaff?> getStaffByEmail(String email) =>
      (select(localStaff)..where((t) => t.email.equals(email))).getSingleOrNull();

  Future<void> insertOrUpdateStaff(LocalStaff staff) =>
      into(localStaff).insertOnConflictUpdate(staff);

  Future<void> deleteStaff(String id) =>
      (delete(localStaff)..where((t) => t.id.equals(id))).go();

  Future<List<LocalStaff>> getActiveStaff() =>
      (select(localStaff)..where((t) => t.isActive.equals(true))).get();

  // ============ PRODUCTS METHODS ============
  Future<List<LocalProduct>> getAllProducts() => select(localProducts).get();

  Future<LocalProduct?> getProductById(String id) =>
      (select(localProducts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<LocalProduct?> getProductBySku(String sku) =>
      (select(localProducts)..where((t) => t.sku.equals(sku))).getSingleOrNull();

  Future<void> insertOrUpdateProduct(LocalProduct product) =>
      into(localProducts).insertOnConflictUpdate(product);

  Future<void> deleteProduct(String id) =>
      (delete(localProducts)..where((t) => t.id.equals(id))).go();

  Future<List<LocalProduct>> getActiveProducts() =>
      (select(localProducts)..where((t) => t.isActive.equals(true))).get();

  Future<void> updateProductQuantity(String productId, int newQuantity) =>
      (update(localProducts)..where((t) => t.id.equals(productId)))
          .write(LocalProductsCompanion(quantity: Value(newQuantity)));

  // ============ CUSTOMERS METHODS ============
  Future<List<LocalCustomer>> getAllCustomers() => select(localCustomers).get();

  Future<LocalCustomer?> getCustomerById(String id) =>
      (select(localCustomers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertOrUpdateCustomer(LocalCustomer customer) =>
      into(localCustomers).insertOnConflictUpdate(customer);

  Future<void> deleteCustomer(String id) =>
      (delete(localCustomers)..where((t) => t.id.equals(id))).go();

  // ============ ORDERS METHODS ============
  Future<List<LocalOrder>> getAllOrders() => select(localOrders).get();

  Future<LocalOrder?> getOrderById(String id) =>
      (select(localOrders)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<LocalOrder>> getOrdersByCustomerId(String customerId) =>
      (select(localOrders)..where((t) => t.customerId.equals(customerId))).get();

  Future<List<LocalOrder>> getOrdersByStatus(String status) =>
      (select(localOrders)..where((t) => t.status.equals(status))).get();

  Future<void> insertOrUpdateOrder(LocalOrder order) =>
      into(localOrders).insertOnConflictUpdate(order);

  Future<void> deleteOrder(String id) =>
      (delete(localOrders)..where((t) => t.id.equals(id))).go();

  Future<void> updateOrderStatus(String orderId, String status) =>
      (update(localOrders)..where((t) => t.id.equals(orderId)))
          .write(LocalOrdersCompanion(status: Value(status)));

  // ============ ORDER ITEMS METHODS ============
  Future<List<LocalOrderItem>> getOrderItems(String orderId) =>
      (select(localOrderItems)..where((t) => t.orderId.equals(orderId))).get();

  Future<void> insertOrUpdateOrderItem(LocalOrderItem item) =>
      into(localOrderItems).insertOnConflictUpdate(item);

  Future<void> deleteOrderItem(String id) =>
      (delete(localOrderItems)..where((t) => t.id.equals(id))).go();

  Future<void> deleteOrderItemsByOrderId(String orderId) =>
      (delete(localOrderItems)..where((t) => t.orderId.equals(orderId))).go();

  // ============ EXPENSES METHODS ============
  Future<List<LocalExpense>> getAllExpenses() => select(localExpenses).get();

  Future<List<LocalExpense>> getExpensesByDateRange(DateTime start, DateTime end) =>
      (select(localExpenses)
            ..where((t) => t.expenseDate.isBetweenValues(start, end)))
          .get();

  Future<void> insertOrUpdateExpense(LocalExpense expense) =>
      into(localExpenses).insertOnConflictUpdate(expense);

  Future<void> deleteExpense(String id) =>
      (delete(localExpenses)..where((t) => t.id.equals(id))).go();

  // ============ LEGACY GEMSTONE METHODS ============
  Future<List<LocalGemstone>> getUnsyncedGemstones() =>
      (select(localGemstones)..where((t) => t.isSynced.equals(false))).get();

  Future<void> markGemstoneAsSynced(String id) =>
      (update(localGemstones)..where((t) => t.id.equals(id)))
          .write(const LocalGemstonesCompanion(isSynced: Value(true)));

  Future<void> insertOrUpdateGemstone(LocalGemstone stone) =>
      into(localGemstones).insertOnConflictUpdate(stone);

  Future<LocalGemstone?> getGemstoneById(String id) =>
      (select(localGemstones)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> deleteGemstone(String id) =>
      (delete(localGemstones)..where((t) => t.id.equals(id))).go();

  // ============ ANALYTICS METHODS ============
  Future<double> getTotalSalesAmount() async {
    final result = await customSelect(
      'SELECT SUM(final_amount) as total FROM local_orders WHERE status = ?',
      variables: [const Variable<String>('completed')],
      readsFrom: {localOrders},
    ).map((row) => row.read<double>('total') ?? 0.0).getSingle();
    return result;
  }

  Future<double> getTotalExpensesAmount() async {
    final result = await customSelect(
      'SELECT SUM(amount) as total FROM local_expenses',
      readsFrom: {localExpenses},
    ).map((row) => row.read<double>('total') ?? 0.0).getSingle();
    return result;
  }

  Future<int> getTotalOrdersCount() =>
      (select(localOrders)).get().then((list) => list.length);

  Future<int> getTotalCustomersCount() =>
      (select(localCustomers)).get().then((list) => list.length);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gemstone_ecommerce.db'));
    return NativeDatabase(file);
  });
}
