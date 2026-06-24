import 'dart:math';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/password_service.dart';
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
  static const String auditLogsBox = 'auditLogs';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters once.
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AppUserAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GemstoneAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SaleAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(WorkerAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(AuditLogAdapter());

    await Hive.openBox<AppUser>(usersBox);
    await Hive.openBox<Gemstone>(gemstonesBox);
    await Hive.openBox<Sale>(salesBox);
    await Hive.openBox<Expense>(expensesBox);
    await Hive.openBox<Worker>(workersBox);
    await Hive.openBox(sessionBox);
    await Hive.openBox<AuditLog>(auditLogsBox);

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
      final now = DateTime.now().millisecondsSinceEpoch;
      await users.add(AppUser(
        id: genId(),
        name: 'Admin',
        email: 'admin@gemstone.com',
        username: 'admin',
        passwordHash: PasswordService.hashPassword('admin123'),
        password: '', // empty for new users
        role: 'owner',
        createdAt: now,
        updatedAt: now,
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
          laborFee: 100000,
          miscFee: 90000,
          // totalCost = costPrice + laborFee + miscFee = 3,000,000 + 100,000 + 90,000 = 3,190,000
          totalCost: 3190000,
          remainingCost: 3190000,
          remainingQuantity: 3,
          soldQuantity: 0,
        ),
      ]);
    }
  }

  // -------------------------------------------------------------------------
  // Auth
  // -------------------------------------------------------------------------
  /// Login with username and password (NEW METHOD)
  /// Returns the user if credentials are valid, null otherwise
  static AppUser? loginWithUsername(String username, String password) {
    final users = Hive.box<AppUser>(usersBox);
    for (final u in users.values) {
      if (u.username.toLowerCase() == username.toLowerCase() &&
          PasswordService.verifyPassword(password, u.passwordHash)) {
        return u;
      }
    }
    return null;
  }

  /// Legacy login method (for backward compatibility)
  /// Tries to login with email and password
  static AppUser? login(String email, String password) {
    final users = Hive.box<AppUser>(usersBox);
    for (final u in users.values) {
      // Try new hash-based verification first
      if (u.email.toLowerCase() == email.toLowerCase() &&
          u.passwordHash.isNotEmpty &&
          PasswordService.verifyPassword(password, u.passwordHash)) {
        return u;
      }
      // Fall back to plaintext for old data
      if (u.email.toLowerCase() == email.toLowerCase() &&
          u.password == password) {
        return u;
      }
    }
    return null;
  }

  /// Get user by username
  static AppUser? getUserByUsername(String username) {
    final users = Hive.box<AppUser>(usersBox);
    for (final u in users.values) {
      if (u.username.toLowerCase() == username.toLowerCase()) {
        return u;
      }
    }
    return null;
  }

  /// Get user by ID
  static AppUser? getUserById(String id) {
    final users = Hive.box<AppUser>(usersBox);
    for (final u in users.values) {
      if (u.id == id) {
        return u;
      }
    }
    return null;
  }

  /// Update user (for username/password changes)
  static Future<bool> updateUser(AppUser user) async {
    try {
      final users = Hive.box<AppUser>(usersBox);
      for (final key in users.keys) {
        final u = users.get(key);
        if (u != null && u.id == user.id) {
          user.updatedAt = DateTime.now().millisecondsSinceEpoch;
          await users.put(key, user);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static void saveSession(AppUser user) {
    final s = Hive.box(sessionBox);
    s.put('userId', user.id);
    s.put('userName', user.name);
    s.put('userEmail', user.email);
    s.put('userUsername', user.username);
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
      'username': s.get('userUsername', defaultValue: ''),
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
  static Box<AuditLog> auditLogs() => Hive.box<AuditLog>(auditLogsBox);

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

  /// Main Dashboard Total Capital
  /// Formula: Sum(All Products Total Cost) + Total Expenses
  static double mainDashboardTotalCapital() {
    return totalCapitalInvested() + totalExpenses();
  }

  /// စုစုပေါင်း မူလအရင်း (fixed pool):
  /// ကျန်ရှိနေသေးသော ပစ္စည်းအရင်း + ရောင်းပြီးသား ပစ္စည်းအရင်း
  /// ဤပမာဏသည် ရောင်းရောင်း/မရောင်းရောင်း မပြောင်းလဲသော စုစုပေါင်းအရင်းပမာဏ ဖြစ်သည်။
  static double totalOriginalCapital() {
    return totalCapitalInvested() + totalCostOfGoodsSold();
  }

  /// အသားတင် အရောင်းရငွေ (ပွဲခ နှုတ်ပြီး)
  static double netRevenue() => totalSales() - totalSalesCommission();

  /// Main Dashboard Remaining Capital
  /// Formula: Sum(All Products Remaining Cost)
  static double mainDashboardRemainingCapital() {
    double t = 0;
    for (final g in gemstones().values) {
      final result = calculateRemainingCostAndProfit(g.id);
      final remainingCost = result['remainingCost'] as double? ?? 0;
      t += remainingCost;
    }
    return t;
  }

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
    
    // Calculate remaining cost and profit from sales records
    final profitData = calculateRemainingCostAndProfit(gemstoneId);
    g.remainingCost = profitData['remainingCost'] ?? 0;
    // totalProfit is NOT stored - it's calculated on-the-fly
    
    g.remainingQuantity = gemstoneRemainingQuantity(g);
    g.soldQuantity = gemstoneSoldQuantity(g.id);

    // NOTE: g.quantity (purchase quantity) is NEVER modified
    // It remains the source of truth for purchased quantities
    // Only remainingQuantity and soldQuantity are derived from sales

    await box.put(key, g);
    
    // --- Update transaction history fields for each sale ---
    final salesBox = sales();
    final initialCost = gemstoneTotalCost(g);
    double remainingCost = initialCost;
    double accumulatedProfit = 0;
    
    // Get all sales for this gemstone, sorted by date (oldest first)
    final salesForGem = salesBox.values
        .where((s) => s.gemstoneId == gemstoneId)
        .toList()
      ..sort((a, b) => a.saleDate.compareTo(b.saleDate));
    
    // Process each sale in chronological order
    for (final sale in salesForGem) {
      final netSale = sale.amount - sale.commissionFee;
      double costUsed = 0;
      double profitGenerated = 0;
      
      if (netSale < remainingCost) {
        // Cost not fully recouped
        costUsed = netSale;
        profitGenerated = 0;
        remainingCost -= netSale;
      } else {
        // Cost fully recouped, excess is profit
        costUsed = remainingCost;
        profitGenerated = netSale - remainingCost;
        accumulatedProfit += profitGenerated;
        remainingCost = 0;
      }
      
      // Update sale record with transaction history
      sale.costUsed = costUsed;
      sale.profitGenerated = profitGenerated;
      sale.remainingCostAfterSale = remainingCost;
      sale.accumulatedProfit = accumulatedProfit;
      
      // Find the Hive key for this sale and update it
      for (final k in salesBox.keys) {
        if (salesBox.get(k)?.id == sale.id) {
          await salesBox.put(k, sale);
          break;
        }
      }
    }
  }

  /// All gemstones' product-wise ledger ကို update လုပ်ပြီး save
  static Future<void> updateAllGemstoneProductLedgers() async {
    for (final g in gemstones().values) {
      await updateGemstoneProductLedger(g.id);
    }
  }

  /// Calculate remaining cost and total profit from sales records
  /// Returns {remainingCost, totalProfit}
  static Map<String, double> calculateRemainingCostAndProfit(String gemstoneId) {
    final g = gemstoneById(gemstoneId);
    if (g == null) return {'remainingCost': 0, 'totalProfit': 0};

    final initialCost = gemstoneTotalCost(g);
    double remainingCost = initialCost;
    double totalProfit = 0;

    // Get all sales for this gemstone, sorted by date (oldest first)
    final salesForGem = sales()
        .values
        .where((s) => s.gemstoneId == gemstoneId)
        .toList()
      ..sort((a, b) => a.saleDate.compareTo(b.saleDate));

    // Process each sale in chronological order
    for (final sale in salesForGem) {
      final netSale = sale.amount - sale.commissionFee;

      if (netSale < remainingCost) {
        // Cost not fully recouped
        remainingCost -= netSale;
        // profitGenerated = 0
      } else {
        // Cost fully recouped, excess is profit
        totalProfit += netSale - remainingCost;
        remainingCost = 0;
      }
    }

    return {
      'remainingCost': remainingCost.clamp(0, double.infinity),
      'totalProfit': totalProfit.clamp(0, double.infinity),
    };
  }

  /// ပစ္စည်းစာရင်းအတွင်း ကျောက်အလုံးရေ စုစုပေါင်း
  static int totalStoneCount() {
    int total = 0;
    for (final g in gemstones().values) {
      total += g.quantity;
    }
    return total;
  }

  /// ပစ္စည်းစာရင်းအတွင်း လက်ကျန်စုစုပေါင်း အလုံး
  static int remainingStoneCount() {
    int total = 0;
    for (final g in gemstones().values) {
      total += gemstoneRemainingQuantity(g);
    }
    return total;
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

  // -------------------------------------------------------------------------
  // Admin & Permission Helpers
  // -------------------------------------------------------------------------

  /// လက်ရှိ User သည် Admin ဖြစ်သည်ကို စစ်ဆေးခြင်း
  static bool isCurrentUserAdmin() {
    try {
      final user = currentUser();
      return user['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Audit Log Methods
  // -------------------------------------------------------------------------

  /// အကျင့်စာရင်းတစ်ခု သိမ်းဆည်းခြင်း
  static Future<void> createAuditLog(AuditLog log) async {
    try {
      await auditLogs().add(log);
    } catch (e) {
      print('Error creating audit log: $e');
    }
  }

  /// အကျင့်စာရင်းအားလုံး ရယူခြင်း (အနောက်ဆုံးအရင်း)
  static List<AuditLog> getAllAuditLogs() {
    final logs = auditLogs().values.toList();
    // Sort by timestamp descending (newest first)
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  /// Action အလိုက် အကျင့်စာရင်းများ ရယူခြင်း
  static List<AuditLog> getAuditLogsByAction(String action) {
    final logs = auditLogs().values
        .where((log) => log.action == action)
        .toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  /// User အလိုက် အကျင့်စာရင်းများ ရယူခြင်း
  static List<AuditLog> getAuditLogsByUser(String userId) {
    final logs = auditLogs().values
        .where((log) => log.userId == userId)
        .toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  /// အကျင့်စာရင်းအားလုံး ဖျက်ခြင်း (Admin အတွက်)
  static Future<void> clearAllAuditLogs() async {
    try {
      await auditLogs().clear();
    } catch (e) {
      print('Error clearing audit logs: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Purchase Delete Methods
  // -------------------------------------------------------------------------

  /// ဝယ်ယူမှတ်တမ်း ဖျက်ခြင်း (Admin-only)
  /// Total Stone Count ကျဆင်းခြင်း (Sale Delete နှင့် ကွဲပြားသည်)
  static Future<void> deletePurchaseRecord(
    String gemstoneId,
    dynamic hiveKey,
    String gemstoneName,
    int quantity,
  ) async {
    try {
      // Check admin permission
      if (!isCurrentUserAdmin()) {
        throw Exception('Admin permission required');
      }

      // Delete the gemstone record
      await gemstones().delete(hiveKey);

      // Recalculate ledger (though gemstone is deleted, this is for consistency)
      // Note: totalStoneCount() and remainingStoneCount() will automatically
      // reflect the deletion since they iterate over current gemstones

      // Create Audit Log
      final currentUser = LocalDb.currentUser();
      final auditLog = AuditLog(
        id: genId(),
        action: 'DELETE_PURCHASE',
        gemstoneId: gemstoneId,
        gemstoneName: gemstoneName,
        quantity: quantity,
        userId: currentUser['id'] as String,
        userName: currentUser['name'] as String,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: 'ဝယ်ယူမှတ်တမ်း ဖျက်ခြင်း - ကျောက်: $gemstoneName, အလုံးရေ: $quantity',
      );
      await createAuditLog(auditLog);
    } catch (e) {
      print('Error deleting purchase record: $e');
      rethrow;
    }
  }
}

  // ---------------------------------------------------------------------------
  // Soft Delete & Restore Sale
  // ---------------------------------------------------------------------------

  /// Soft delete a sale record (mark as deleted instead of hard delete)
  static Future<void> softDeleteSale(dynamic saleKey, String deleteReason) async {
    try {
      final sale = sales().get(saleKey) as Sale?;
      if (sale == null) return;

      final currentUser = session().get('currentUser') as Map?;
      if (currentUser == null) return;

      // Mark as soft deleted
      sale.isDeleted = true;
      sale.deletedAt = DateTime.now().millisecondsSinceEpoch;
      sale.deletedBy = currentUser['id'] as String;
      sale.deleteReason = deleteReason;

      await sales().put(saleKey, sale);

      // Recalculate gemstone ledger (removes sale from calculations)
      if (sale.gemstoneId.isNotEmpty) {
        updateGemstoneProductLedger(sale.gemstoneId);
      }

      // Create audit log
      final auditLog = AuditLog(
        id: genId(),
        action: 'DELETE_SALE',
        saleId: sale.id,
        gemstoneId: sale.gemstoneId,
        gemstoneName: sale.gemstoneName,
        quantity: sale.quantity,
        amount: sale.amount,
        userId: currentUser['id'] as String,
        userName: currentUser['name'] as String,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: 'အရောင်းမှတ်တမ်း soft delete - ကျောက်: ${sale.gemstoneName}, အလုံးရေ: ${sale.quantity}',
      );
      await createAuditLog(auditLog);
    } catch (e) {
      print('Error soft deleting sale: $e');
      rethrow;
    }
  }

  /// Restore a soft-deleted sale record
  static Future<void> restoreSale(dynamic saleKey) async {
    try {
      if (!isCurrentUserAdmin()) {
        throw Exception('Admin အခွင့်အရည်အချက် လိုအပ်ပါသည်။');
      }

      final sale = sales().get(saleKey) as Sale?;
      if (sale == null) return;

      final currentUser = session().get('currentUser') as Map?;
      if (currentUser == null) return;

      // Restore the sale
      sale.isDeleted = false;
      sale.deletedAt = null;
      sale.deletedBy = null;
      sale.deleteReason = null;

      await sales().put(saleKey, sale);

      // Recalculate gemstone ledger (adds sale back to calculations)
      if (sale.gemstoneId.isNotEmpty) {
        updateGemstoneProductLedger(sale.gemstoneId);
      }

      // Create audit log
      final auditLog = AuditLog(
        id: genId(),
        action: 'RESTORE_SALE',
        saleId: sale.id,
        gemstoneId: sale.gemstoneId,
        gemstoneName: sale.gemstoneName,
        quantity: sale.quantity,
        amount: sale.amount,
        userId: currentUser['id'] as String,
        userName: currentUser['name'] as String,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: 'Deleted sale restored successfully - ကျောက်: ${sale.gemstoneName}, အလုံးရေ: ${sale.quantity}',
      );
      await createAuditLog(auditLog);
    } catch (e) {
      print('Error restoring sale: $e');
      rethrow;
    }
  }

  /// Get all deleted sales
  static List<Sale> getDeletedSales() {
    final allSales = sales().values.toList();
    return allSales.where((s) => s.isDeleted == true).toList();
  }

  /// Get all active (non-deleted) sales
  static List<Sale> getActiveSales() {
    final allSales = sales().values.toList();
    return allSales.where((s) => s.isDeleted != true).toList();
  }

  /// Sale ကို ဖျက်နိုင်သည်ကို စစ်ဆေးခြင်း (Admin-only)
  static bool canDeleteSale() {
    return isCurrentUserAdmin();
  }

  /// Sale ကို Restore နိုင်သည်ကို စစ်ဆေးခြင်း (Admin-only)
  static bool canRestoreSale() {
    return isCurrentUserAdmin();
  }

  /// Sale ကို Edit နိုင်သည်ကို စစ်ဆေးခြင်း (Admin-only)
  static bool canEditSale() {
    return isCurrentUserAdmin();
  }

  /// Purchase ကို ဖျက်နိုင်သည်ကို စစ်ဆေးခြင်း (Admin-only)
  static bool canDeletePurchase() {
    return isCurrentUserAdmin();
  }

  /// Purchase ကို Edit နိုင်သည်ကို စစ်ဆေးခြင်း (Admin-only)
  static bool canEditPurchase() {
    return isCurrentUserAdmin();
  }

  /// လုပ်ဆောင်ချက်ကို Admin သာ ပြုလုပ်နိုင်သည်ဆိုသည့် Error message
  static String adminOnlyErrorMessage() {
    return 'ဤလုပ်ဆောင်ချက်ကို Admin သာ ပြုလုပ်နိုင်ပါသည်။';
  }

}
