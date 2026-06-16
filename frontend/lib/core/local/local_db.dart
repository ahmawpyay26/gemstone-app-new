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
          totalCost: 1500000,
          remainingCost: 1500000,
          totalProfit: 0,
          remainingQuantity: 2,
          soldQuantity: 0,
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
          totalCost: 1200000,
          remainingCost: 1200000,
          totalProfit: 0,
          remainingQuantity: 1,
          soldQuantity: 0,
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
          totalCost: 3000000,
          remainingCost: 3000000,
          totalProfit: 0,
          remainingQuantity: 3,
          soldQuantity: 0,
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

  /// ပစ္စည်းစာရင်းအတွင်း ကျန်ရှိသည့် စုစုပေါင်းအရင်း
  static double totalCapitalInvested() {
    double t = 0;
    for (final g in gemstones().values) {
      t += gemstoneTotalCost(g);
    }
    return t;
  }

  /// စုစုပေါင်း မူလအရင်း (fixed pool):
  /// ကျန်ရှိနေသေးသော ပစ္စည်းအရင်း + ရောင်းပြီးသား ပစ္စည်းအရင်း
  /// ဤပမာဏသည် ရောင်းရောင်း/မရောင်းရောင်း မပြောင်းလဲသော စုစုပေါင်းအရင်းပမာဏ ဖြစ်သည်။
  static double totalOriginalCapital() {
    return totalCapitalInvested() + totalCostOfGoodsSold();
  }

  /// အသားတင် အရောင်းရငွေ (ပွဲခ နှုတ်ပြီး)
  static double netRevenue() => totalSales() - totalSalesCommission();

  /// ကျန်ရှိသော လက်ကျန်အရင်း:
  /// မူလစုစုပေါင်းအရင်း ထဲမှ အသားတင် အရောင်းရငွေကို နှုတ်ပြီး ကျန်အရင်းပမာဏ
  /// အရင်းကျေသွားပါက 0 (သုည) ဖြစ်သည်။ ဘယ်တော့မှ အနှုတ် မဖြစ်ပါ။
  static double remainingCapital() {
    final r = totalOriginalCapital() - netRevenue();
    return r > 0 ? r : 0;
  }

  /// ကုန်သည်အမြတ် (capital recoupment logic):
  /// အသားတင် အရောင်းရငွေသည် မူလစုစုပေါင်းအရင်းထက် မကျော်မချင်း အမြတ် = 0 (သုည)။
  /// ကျော်လွန်မှသာ ကျော်လွန်သည့်ပမာဏကို အမြတ်အဖြစ် ပြသည်။ အရှုံး ဘယ်တော့မှ မပြပါ။
  static double grossProfit() {
    final p = netRevenue() - totalOriginalCapital();
    return p > 0 ? p : 0;
  }

  /// အဆုံးသတ် အမြတ်စစ် (အမြတ် - အသုံးစရိတ်)
  /// အရင်းမကျေသေးပါက (grossProfit == 0) အသားတင်အမြတ်ကို 0 အဖြစ်ထားသည်။
  static double netProfit() {
    final gp = grossProfit();
    if (gp <= 0) return 0;
    final np = gp - totalExpenses();
    return np > 0 ? np : 0;
  }

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

  /// ဤကျောက်မျက် (id) နှင့် ဆက်စပ်သော အရောင်းများ၏ အသားတင် အရောင်းရငွေ
  /// (ရောင်းရငွေ စုစုပေါင်း ထဲမှ ရောင်းပွဲခ နှုတ်ပြီး).
  static double netRevenueForGemstone(String gemstoneId) {
    if (gemstoneId.isEmpty) return 0;
    double t = 0;
    for (final s in sales().values) {
      if (s.gemstoneId == gemstoneId) {
        t += (s.amount - s.commissionFee);
      }
    }
    return t;
  }

  /// ပစ္စည်းတစ်ခုချင်းစီ၏ ကျန်ရှိအရင်း:
  /// မူလစုစုပေါင်းအရင်း ထဲမှ ဤကျောက်နှင့်ဆက်စပ်သော အသားတင် အရောင်းရငွေကို နှုတ်ပြီး
  /// ကျန်အရင်းပမာဏ။ အရင်းကျေသွားပါက 0 (သုည)။ အနှုတ် ဘယ်တော့မှ မဖြစ်ပါ။
  static double gemstoneRemainingCapital(Gemstone g) {
    final remaining = gemstoneTotalCost(g) - netRevenueForGemstone(g.id);
    return remaining > 0 ? remaining : 0;
  }

  // -------------------------------------------------------------------------
  // Product-wise Independent Ledger Logic
  // -------------------------------------------------------------------------

  /// ပစ္စည်းတစ်ခုချင်းစီ၏ စုစုပေါင်းအမြတ်:
  /// အသားတင်အရောင်းရငွေ > မူလစုစုပေါင်းအရင်း ဖြစ်သည့်အခါ၊
  /// (အသားတင်အရောင်းရငွေ - မူလစုစုပေါင်းအရင်း) = အမြတ်
  static double gemstoneTotalProfit(Gemstone g) {
    final totalCost = gemstoneTotalCost(g);
    final netRevenue = netRevenueForGemstone(g.id);
    if (netRevenue > totalCost) {
      return netRevenue - totalCost;
    }
    return 0;
  }

  /// ပစ္စည်းတစ်ခုချင်းစီ၏ ရောင်းပြီးအရေအတွက်
  static int gemstoneSoldQuantity(String gemstoneId) {
    int total = 0;
    for (final s in sales().values) {
      if (s.gemstoneId == gemstoneId) {
        total += s.quantity;
      }
    }
    return total;
  }

  /// ပစ္စည်းတစ်ခုချင်းစီ၏ ကျန်ရှိအရေအတွက်
  static int gemstoneRemainingQuantity(Gemstone g) {
    return g.quantity - gemstoneSoldQuantity(g.id);
  }

  /// ပစ္စည်းတစ်ခုချင်းစီ၏ အရောင်းအကြိမ်အရေအတွက် (ဘယ်နှစ်ကြိမ် ရောင်းခဲ့သည်)
  static int gemstoneSaleCount(String gemstoneId) {
    int count = 0;
    for (final s in sales().values) {
      if (s.gemstoneId == gemstoneId) {
        count++;
      }
    }
    return count;
  }

  /// ပစ္စည်းတစ်ခုချင်းစီ၏ ပထမအကြိမ်ရောင်းချမှုအတွက် အရင်းတန်ဖိုး (Auto-fill)
  /// ပထမအကြိမ်: totalCost
  /// နောက်အကြိမ်များ: remainingCost
  /// remainingCost = 0 ဖြစ်လျှင်: 0
  static double getSalesFormAutoCost(Gemstone g) {
    final saleCount = gemstoneSaleCount(g.id);
    if (saleCount == 0) {
      // ပထမအကြိမ်: totalCost
      return gemstoneTotalCost(g);
    } else {
      // နောက်အကြိမ်များ: remainingCost
      return gemstoneRemainingCapital(g);
    }
  }

  /// ပစ္စည်းတစ်ခုချင်းစီ၏ Ledger အချက်အလက် အားလုံး update လုပ်ပြီး save
  static Future<void> updateGemstoneProductLedger(String gemstoneId) async {
    final key = gemstoneKeyById(gemstoneId);
    if (key == null) return;
    final box = gemstones();
    final g = box.get(key);
    if (g == null) return;

    // Update ledger fields
    g.totalCost = gemstoneTotalCost(g);
    g.remainingCost = gemstoneRemainingCapital(g);
    g.totalProfit = gemstoneTotalProfit(g);
    g.remainingQuantity = gemstoneRemainingQuantity(g);
    g.soldQuantity = gemstoneSoldQuantity(g.id);

    // Auto-update quantity based on sales
    g.quantity = g.remainingQuantity + g.soldQuantity;

    await box.put(key, g);
  }

  /// All gemstones' product-wise ledger ကို update လုပ်ပြီး save
  static Future<void> updateAllGemstoneProductLedgers() async {
    for (final g in gemstones().values) {
      await updateGemstoneProductLedger(g.id);
    }
  }

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
