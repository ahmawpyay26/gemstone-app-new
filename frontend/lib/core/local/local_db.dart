import 'dart:math';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';

/// Central offline-first data store backed by Hive.
/// No network is required for any operation.
class LocalDb {
  static const String usersBox = 'users';
  static const String gemstonesBox = 'gemstones';
  static const String salesBox = 'sales';
  static const String expensesBox = 'expenses';
  static const String workersBox = 'workers';
  static const String sessionBox = 'session';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters once.
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AppUserAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GemstoneAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SaleAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(WorkerAdapter());

    await Hive.openBox<AppUser>(usersBox);
    await Hive.openBox<Gemstone>(gemstonesBox);
    await Hive.openBox<Sale>(salesBox);
    await Hive.openBox<Expense>(expensesBox);
    await Hive.openBox<Worker>(workersBox);
    await Hive.openBox(sessionBox);

    await _seedDefaults();
  }

  /// Supported weight units. value => Burmese display label.
  static const Map<String, String> weightUnits = {
    'carat': 'ကာရက်',
    'kg': 'ကီလို (kg)',
    'viss': 'ပိဿာ',
  };

  /// Short label used inline next to numbers.
  static String unitLabel(String unit) {
    switch (unit) {
      case 'kg':
        return 'kg';
      case 'viss':
        return 'ပိဿာ';
      case 'carat':
      default:
        return 'ကာရက်';
    }
  }

  static String genId() {
    final r = Random();
    return '${DateTime.now().millisecondsSinceEpoch}-${r.nextInt(99999)}';
  }

  // -------------------------------------------------------------------------
  // Seed default admin + sample data on first run
  // -------------------------------------------------------------------------
  static Future<void> _seedDefaults() async {
    final users = Hive.box<AppUser>(usersBox);
    if (users.isEmpty) {
      await users.add(AppUser(
        id: genId(),
        name: 'Admin',
        email: 'admin@gemstone.com',
        password: 'admin123',
        role: 'owner',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    final gems = Hive.box<Gemstone>(gemstonesBox);
    if (gems.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await gems.addAll([
        Gemstone(
          id: genId(),
          name: 'ပတ္တမြား နီ',
          type: 'ပတ္တမြား (Ruby)',
          weightCarat: 3.5,
          weightUnit: 'kg',
          costPrice: 1500000,
          sellPrice: 2200000,
          quantity: 2,
          color: 'အနီ',
          origin: 'မိုးကုတ်',
          status: 'in_stock',
          note: 'အရည်အသွေးမြင့်',
          createdAt: now,
        ),
        Gemstone(
          id: genId(),
          name: 'နီလာ ပြာ',
          type: 'နီလာ (Sapphire)',
          weightCarat: 5.2,
          weightUnit: 'viss',
          costPrice: 1200000,
          sellPrice: 1800000,
          quantity: 1,
          color: 'အပြာ',
          origin: 'မိုးကုတ်',
          status: 'in_stock',
          note: '',
          createdAt: now,
        ),
        Gemstone(
          id: genId(),
          name: 'ကျောက်စိမ်း',
          type: 'ကျောက်စိမ်း (Jade)',
          weightCarat: 50,
          weightUnit: 'kg',
          costPrice: 3000000,
          sellPrice: 4500000,
          quantity: 3,
          color: 'အစိမ်း',
          origin: 'ဖားကန့်',
          status: 'in_stock',
          note: 'Imperial Jade',
          createdAt: now,
        ),
      ]);
    }
  }

  // -------------------------------------------------------------------------
  // Auth
  // -------------------------------------------------------------------------
  static AppUser? login(String email, String password) {
    final users = Hive.box<AppUser>(usersBox);
    for (final u in users.values) {
      if (u.email.toLowerCase() == email.toLowerCase() &&
          u.password == password) {
        return u;
      }
    }
    return null;
  }

  static void saveSession(AppUser user) {
    final s = Hive.box(sessionBox);
    s.put('userId', user.id);
    s.put('userName', user.name);
    s.put('userEmail', user.email);
    s.put('userRole', user.role);
    s.put('loggedIn', true);
  }

  static bool isLoggedIn() {
    final s = Hive.box(sessionBox);
    return s.get('loggedIn', defaultValue: false) as bool;
  }

  static Map<String, dynamic> currentUser() {
    final s = Hive.box(sessionBox);
    return {
      'id': s.get('userId', defaultValue: ''),
      'name': s.get('userName', defaultValue: 'Admin'),
      'email': s.get('userEmail', defaultValue: ''),
      'role': s.get('userRole', defaultValue: 'owner'),
    };
  }

  static void logout() {
    final s = Hive.box(sessionBox);
    s.put('loggedIn', false);
  }

  // -------------------------------------------------------------------------
  // Box accessors
  // -------------------------------------------------------------------------
  static Box<Gemstone> gemstones() => Hive.box<Gemstone>(gemstonesBox);
  static Box<Sale> sales() => Hive.box<Sale>(salesBox);
  static Box<Expense> expenses() => Hive.box<Expense>(expensesBox);
  static Box<Worker> workers() => Hive.box<Worker>(workersBox);
  static Box<AppUser> users() => Hive.box<AppUser>(usersBox);

  // -------------------------------------------------------------------------
  // Inventory stock helpers (auto deduction on sale)
  // -------------------------------------------------------------------------

  /// Find a gemstone by its business id. Returns null if not found.
  static Gemstone? gemstoneById(String id) {
    if (id.isEmpty) return null;
    for (final g in gemstones().values) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// Find the Hive key of a gemstone by its business id.
  static dynamic gemstoneKeyById(String id) {
    final box = gemstones();
    for (final k in box.keys) {
      if (box.get(k)?.id == id) return k;
    }
    return null;
  }

  /// Deduct quantity and weight from a gemstone's stock.
  /// Pass negative values to restore (e.g., when a sale is deleted/edited).
  static Future<void> adjustStock(
      String gemstoneId, int qtyDelta, double weightDelta) async {
    final key = gemstoneKeyById(gemstoneId);
    if (key == null) return;
    final box = gemstones();
    final g = box.get(key);
    if (g == null) return;
    g.quantity = (g.quantity - qtyDelta).clamp(0, 1 << 31);
    g.weightCarat = (g.weightCarat - weightDelta);
    if (g.weightCarat < 0) g.weightCarat = 0;
    // Auto-mark as sold-out when nothing remains.
    if (g.quantity <= 0) {
      g.status = 'sold';
    } else if (g.status == 'sold') {
      g.status = 'in_stock';
    }
    await box.put(key, g);
  }

  // -------------------------------------------------------------------------
  // Statistics for dashboard / reports
  // -------------------------------------------------------------------------
  static double totalSales() {
    double t = 0;
    for (final s in sales().values) {
      t += s.amount;
    }
    return t;
  }

  static double totalExpenses() {
    double t = 0;
    for (final e in expenses().values) {
      t += e.amount;
    }
    return t;
  }

  static double totalSalary() {
    double t = 0;
    for (final w in workers().values) {
      if (w.status == 'active') t += w.salary;
    }
    return t;
  }

  static double profit() => totalSales() - totalExpenses();

  static int inventoryCount() {
    int t = 0;
    for (final g in gemstones().values) {
      t += g.quantity;
    }
    return t;
  }

  static double inventoryValue() {
    double t = 0;
    for (final g in gemstones().values) {
      t += g.sellPrice * g.quantity;
    }
    return t;
  }

  static int activeWorkers() {
    return workers().values.where((w) => w.status == 'active').length;
  }
}
