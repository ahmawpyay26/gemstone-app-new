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

  // ----- Remember me (saved login credentials) -----
  static void saveRememberedCredentials(String email, String password) {
    final s = Hive.box(sessionBox);
    s.put('rememberMe', true);
    s.put('savedEmail', email);
    s.put('savedPassword', password);
  }

  static void clearRememberedCredentials() {
    final s = Hive.box(sessionBox);
    s.put('rememberMe', false);
    s.delete('savedEmail');
    s.delete('savedPassword');
  }

  static bool rememberMe() {
    final s = Hive.box(sessionBox);
    return s.get('rememberMe', defaultValue: false) as bool;
  }

  static String savedEmail() {
    final s = Hive.box(sessionBox);
    return s.get('savedEmail', defaultValue: '') as String;
  }

  static String savedPassword() {
    final s = Hive.box(sessionBox);
    return s.get('savedPassword', defaultValue: '') as String;
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

  /// ရောင်းချမှု အားလုံး၏ စုစုပေါင်း အရင်းတန်ဖိုး (COGS).
  static double totalCostOfGoodsSold() {
    double t = 0;
    for (final s in sales().values) {
      t += s.costPrice;
    }
    return t;
  }

  /// ရောင်းချမှုအားလုံး၏ ရောင်းပွဲခ စုစုပေါင်း။
  static double totalSalesCommission() {
    double t = 0;
    for (final s in sales().values) {
      t += s.commissionFee;
    }
    return t;
  }

  /// ကုန်သည်အမြတ် (ရောင်းရငွေ - အရင်း) — အသုံးစရိတ် မပါဝင်သေး၏ အမြတ်
  static double grossProfit() =>
      totalSales() - totalSalesCommission() - totalCostOfGoodsSold();

  /// အဆုံးသတ် အမြတ်စစ် (ရောင်းရငွေ - အရင်း - အသုံးစရိတ်)
  static double netProfit() => grossProfit() - totalExpenses();

  static double profit() =>
      totalSales() - totalSalesCommission() - totalExpenses();

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

  /// ပစ္စည်းစာရင်းအတွင်း ဝယ်ဈေး စုစုပေါင်း (cost basis).
  static double inventoryCostTotal() {
    double t = 0;
    for (final g in gemstones().values) {
      t += g.costPrice;
    }
    return t;
  }

  /// ပစ္စည်းစာရင်းအတွင်း ထည့်သွင်းထားသော ကုန်ကျစရိတ် အမျိုးအစားအလိုက် စုစုပေါင်း။
  static double inventoryCommissionTotal() {
    double t = 0;
    for (final g in gemstones().values) {
      t += g.commissionFee;
    }
    return t;
  }

  static double inventoryProcessingTotal() {
    double t = 0;
    for (final g in gemstones().values) {
      t += g.processingFee;
    }
    return t;
  }

  static double inventoryRepairTotal() {
    double t = 0;
    for (final g in gemstones().values) {
      t += g.repairFee;
    }
    return t;
  }

  static double inventoryBreakageTotal() {
    double t = 0;
    for (final g in gemstones().values) {
      t += g.breakageFee;
    }
    return t;
  }

  static double inventoryBloodTotal() {
    double t = 0;
    for (final g in gemstones().values) {
      t += g.bloodFee;
    }
    return t;
  }

  static double inventoryLaborTotal() {
    double t = 0;
    for (final g in gemstones().values) {
      t += g.laborFee;
    }
    return t;
  }

  static double inventoryMiscTotal() {
    double t = 0;
    for (final g in gemstones().values) {
      t += g.miscFee;
    }
    return t;
  }

  /// ပစ္စည်းစာရင်းအတွင်းရှိ ကုန်ကျစရိတ် (ဝယ်ဈေး မပါ) အားလုံး စုစုပေါင်း။
  static double inventoryExtraCostTotal() {
    double t = 0;
    for (final g in gemstones().values) {
      t += g.commissionFee +
          g.processingFee +
          g.repairFee +
          g.breakageFee +
          g.bloodFee +
          g.laborFee +
          g.miscFee;
    }
    return t;
  }

  /// ပစ္စည်းတစ်ခုချင်းစီ၏ စုစုပေါင်း အရင်းအနှီး (ဝယ်ဈေး + ကုန်ကျစရိတ်များ).
  static double gemstoneTotalCost(Gemstone g) =>
      g.costPrice +
      g.commissionFee +
      g.processingFee +
      g.repairFee +
      g.breakageFee +
      g.bloodFee +
      g.laborFee +
      g.miscFee;

  static int activeWorkers() {
    return workers().values.where((w) => w.status == 'active').length;
  }

  /// Placeholder for cost adjustment - NOT USED
  /// The inventory cost should NOT be modified when a sale is recorded.
  /// The remaining quantity keeps its original unit cost.
  /// Cost tracking is done through the Sale record, not by modifying inventory.
  static Future<void> adjustCost(
      String gemstoneId, double costDelta) async {
    // Do nothing - inventory costs should remain unchanged
    // This prevents the bug where all costs become 0 after a partial sale
  }

  // recordProfitLoss removed - profit/loss is now calculated directly from sales records
  // without creating separate expense entries to avoid double-counting
}
