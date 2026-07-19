import 'dart:math';
import 'dart:developer' as developer;
import 'package:collection/collection.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../services/password_service.dart';
import 'models.dart';
import '../rca/rca_log_collector.dart';

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
  static const String staffUsersBox = 'staffUsers';
  static const String permissionsBox = 'permissions';
  static const String rolesBox = 'roles';
  static const String brokerConsignmentsBox = 'brokerConsignments';
  static const String brokerSaleRecordsBox = 'brokerSaleRecords';
  static const String customersBox = 'customers';
  static const String customerLedgerBox = 'customerLedger';
  static const String paymentsBox = 'payments';
  static const String businessProfileBox = 'businessProfile';
  static const String brokerProfilesBox = 'brokerProfiles';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters once.
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AppUserAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(GemstoneAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SaleAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(WorkerAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(AuditLogAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(PermissionAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(RoleAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(StaffUserAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(BrokerHistoricalDataAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(BrokerConsignmentAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(BrokerSaleRecordAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(CustomerAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(CustomerLedgerAdapter());
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(PaymentAdapter());
    if (!Hive.isAdapterRegistered(16)) Hive.registerAdapter(BusinessProfileAdapter());
    if (!Hive.isAdapterRegistered(17)) Hive.registerAdapter(BrokerProfileAdapter());

    await Hive.openBox<AppUser>(usersBox);
    await Hive.openBox<Gemstone>(gemstonesBox);
    await Hive.openBox<Sale>(salesBox);
    await Hive.openBox<Expense>(expensesBox);
    await Hive.openBox<Worker>(workersBox);
    await Hive.openBox(sessionBox);
    await Hive.openBox<AuditLog>(auditLogsBox);
    await Hive.openBox<StaffUser>(staffUsersBox);
    await Hive.openBox<Permission>(permissionsBox);
    await Hive.openBox<Role>(rolesBox);
    await Hive.openBox<BrokerConsignment>(brokerConsignmentsBox);
    await Hive.openBox<BrokerSaleRecord>(brokerSaleRecordsBox);
    await Hive.openBox<Customer>(customersBox);
    await Hive.openBox<CustomerLedger>(customerLedgerBox);
    await Hive.openBox<Payment>(paymentsBox);
    await Hive.openBox<BusinessProfile>(businessProfileBox);
    await Hive.openBox<BrokerProfile>(brokerProfilesBox);

    await _seedDefaults();
    await _migrateGemstonesCostTracking();
    await _migrateFixRemainingCostBalance();
  }

  /// Supported weight units. value => Burmese display label.
  static const Map<String, String> weightUnits = {
    'viss': 'ပိသာ',
    'kyat': 'ကျပ်သား',
    'carat': 'ကာရက်',
    'kg': 'ကီလို (kg)',
    'g': 'ဂရမ် (g)',
    'lb': 'ပေါင် (lb)',
    'oz': 'အောင်စ (oz)',
  };

  /// Short label used inline next to numbers.
  static String unitLabel(String unit) {
    switch (unit) {
      case 'viss':
        return 'ပိသာ';
      case 'kyat':
        return 'ကျပ်သား';
      case 'carat':
        return 'ကာရက်';
      case 'kg':
        return 'kg';
      case 'g':
        return 'g';
      case 'lb':
        return 'lb';
      case 'oz':
        return 'oz';
      default:
        return 'kg';
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
        role: 'super_admin',
        createdAt: now,
        updatedAt: now,
      ));
    }

    // Initialize default permissions if not exists
    final permissions = Hive.box<Permission>(permissionsBox);
    if (permissions.isEmpty) {
      final defaultPermissions = [
        'Dashboard',
        'Inventory',
        'Purchase Records',
        'Sales',
        'Expenses',
        'Workers',
        'Customers',
        'Reports',
        'Audit Log',
        'Settings',
        'Export',
        'Delete',
        'Restore',
        'Edit Purchase',
        'Edit Sale',
        'Delete Purchase',
        'Delete Sale',
      ];
      for (final perm in defaultPermissions) {
        await permissions.add(Permission(
          id: genId(),
          name: perm,
          description: perm,
        ));
      }
    }

    // Initialize Super Admin role with all permissions if not exists
    final roles = Hive.box<Role>(rolesBox);
    if (roles.isEmpty) {
      final perms = Hive.box<Permission>(permissionsBox);
      final allPermissionIds = perms.values.map((p) => p.id).toList();
      await roles.add(Role(
        id: genId(),
        name: 'Super Admin',
        permissionIds: allPermissionIds,
        description: 'Full access to all features',
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
  // Migration: Initialize cost tracking fields for existing Gemstones
  // -------------------------------------------------------------------------
  static Future<void> _migrateGemstonesCostTracking() async {
    final gems = Hive.box<Gemstone>(gemstonesBox);
    bool hasChanges = false;
    
    for (int i = 0; i < gems.length; i++) {
      final g = gems.getAt(i);
      if (g != null && g.originalPurchaseCost == 0) {
        g.originalPurchaseCost = g.costPrice;
        // FIX: Use TOTAL PURCHASE COST (costPrice + all fees) as the starting balance
        // This is the value displayed as "စုစုပေါင်းအရင်း"
        g.remainingCostBalance = gemstoneTotalCost(g);
        g.recoveredCost = 0;
        await gems.putAt(i, g);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      print('[Migration] Gemstone cost tracking fields initialized for existing records');
    }
  }

  // -------------------------------------------------------------------------
  // Migration: Fix remainingCostBalance to use totalPurchaseCost
  // -------------------------------------------------------------------------
  /// Recalculates remainingCostBalance for ALL gemstones using the correct
  /// totalPurchaseCost (costPrice + all fees) instead of just costPrice.
  /// This fixes the bug where cost recovery used only the base cost.
  static Future<void> _migrateFixRemainingCostBalance() async {
    final gems = Hive.box<Gemstone>(gemstonesBox);
    bool hasChanges = false;
    
    for (int i = 0; i < gems.length; i++) {
      final g = gems.getAt(i);
      if (g == null) continue;
      
      final totalCost = gemstoneTotalCost(g);
      
      // Recalculate from scratch: totalCost minus all net sales = remaining balance
      final salesForGem = sales()
          .values
          .where((s) => !s.isDeleted && s.gemstoneId == g.id)
          .toList();
      
      double totalNetSales = 0;
      for (final sale in salesForGem) {
        totalNetSales += (sale.amount - sale.commissionFee);
      }
      
      final double correctRemainingBalance = (totalCost - totalNetSales) < 0 ? 0.0 : (totalCost - totalNetSales);
      final double correctRecoveredCost = totalNetSales > totalCost ? totalCost : totalNetSales;
      final double correctProfit = totalNetSales > totalCost ? totalNetSales - totalCost : 0.0;
      
      // Only update if values are different
      if ((g.remainingCostBalance - correctRemainingBalance).abs() > 0.01 ||
          (g.recoveredCost - correctRecoveredCost).abs() > 0.01) {
        g.remainingCostBalance = correctRemainingBalance;
        g.recoveredCost = correctRecoveredCost;
        g.totalProfit = correctProfit;
        g.remainingCost = correctRemainingBalance;
        g.totalCost = totalCost;
        await gems.putAt(i, g);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      print('[Migration] Fixed remainingCostBalance to use totalPurchaseCost for all gemstones');
    }
  }

  // -------------------------------------------------------------------------
  // Cost Recovery & Profit Calculation Engine
  // -------------------------------------------------------------------------
  /// Apply cost recovery logic to a purchase record based on sale amount.
  /// 
  /// Business Rules:
  /// Case 1: If saleAmount <= remainingCostBalance
  ///   - Recovered Cost += saleAmount
  ///   - Remaining Cost Balance -= saleAmount
  ///   - Profit = 0
  /// 
  /// Case 2: If saleAmount > remainingCostBalance
  ///   - Recovered Cost += remainingCostBalance
  ///   - Remaining Cost Balance = 0
  ///   - Profit += (saleAmount - remainingCostBalance)
  /// 
  /// Case 3: If remainingCostBalance == 0
  ///   - All future sales become profit immediately
  static void applyCostRecovery(Gemstone gemstone, double saleAmount) {
    if (saleAmount <= 0) return;
    
    // Ensure remaining cost balance never goes below zero
    double remainingBalance = gemstone.remainingCostBalance;
    
    if (saleAmount <= remainingBalance) {
      // Case 1: Partial recovery - sale amount is less than remaining cost
      gemstone.recoveredCost += saleAmount;
      gemstone.remainingCostBalance -= saleAmount;
      // Profit remains unchanged
    } else {
      // Case 2 & 3: Full recovery or already recovered
      double profitIncrease = saleAmount - remainingBalance;
      gemstone.recoveredCost += remainingBalance;
      gemstone.remainingCostBalance = 0;
      // Add profit only after cost is fully recovered
      if (gemstone.totalProfit == null) {
        gemstone.totalProfit = profitIncrease;
      } else {
        gemstone.totalProfit = (gemstone.totalProfit ?? 0) + profitIncrease;
      }
    }
    
    // Update total sales revenue
    if (gemstone.totalSalesRevenue == null) {
      gemstone.totalSalesRevenue = saleAmount;
    } else {
      gemstone.totalSalesRevenue = (gemstone.totalSalesRevenue ?? 0) + saleAmount;
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
    // AppUser မှန်သမျှ Super Admin ဖြစ်သည်။ role string မည်သည့်ပုံစံ
    // ဖြစ်စေကာမူ (super_admin/owner/empty) ၏ဟုတ် 'admin' အဖြစ် normalize လုပ်
    // ခြင်းဖြင့် downstream permission စစ်ဆေးမှုများ တည်မှန်စေသည်။
    s.put('userRole', 'admin');
    s.put('userType', 'AppUser');
    s.put('loggedIn', true);
  }

  /// Save session for a StaffUser (RBAC staff accounts).
  /// StaffUser has a different shape than AppUser, so map fields explicitly.
  static void saveStaffSession(StaffUser staff) {
    final s = Hive.box(sessionBox);
    s.put('userId', staff.id);
    s.put('userName', staff.fullName);
    s.put('userEmail', '');
    s.put('userUsername', staff.username);
    s.put('userRole', 'staff');
    s.put('userType', 'StaffUser');
    s.put('staffRoleId', staff.roleId);
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
  static Box<Customer> customers() => Hive.box<Customer>(customersBox);
  static Box<CustomerLedger> customerLedger() => Hive.box<CustomerLedger>(customerLedgerBox);
  static Box<Payment> payments() => Hive.box<Payment>(paymentsBox);
  static Box<BrokerSaleRecord> brokerSaleRecords() => Hive.box<BrokerSaleRecord>(brokerSaleRecordsBox);
  static Box<BusinessProfile> businessProfiles() => Hive.box<BusinessProfile>(businessProfileBox);

  // ---------------------------------------------------------------------------
  // BusinessProfile helpers
  // ---------------------------------------------------------------------------

  /// Returns the single BusinessProfile, creating a default one if none exists.
  static BusinessProfile getBusinessProfile() {
    final box = businessProfiles();
    if (box.isEmpty) {
      final profile = BusinessProfile.empty();
      box.put('profile', profile);
      return profile;
    }
    return box.getAt(0) ?? BusinessProfile.empty();
  }

  /// Saves (overwrites) the single BusinessProfile.
  static Future<void> saveBusinessProfile(BusinessProfile profile) async {
    final box = businessProfiles();
    await box.put('profile', profile);
  }

  // -------------------------------------------------------------------------
  // Customer CRUD operations
  // -------------------------------------------------------------------------

  /// Create a new customer
  static Future<void> createCustomer(Customer customer) async {
    final box = customers();
    await box.put(customer.id, customer);
  }

  /// Update an existing customer
  static Future<void> updateCustomer(Customer customer) async {
    final box = customers();
    customer.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await box.put(customer.id, customer);
  }

  /// Soft delete a customer
  static Future<void> deleteCustomer(String customerId) async {
    final box = customers();
    final customer = box.get(customerId);
    if (customer != null) {
      customer.isDeleted = true;
      customer.deletedAt = DateTime.now().millisecondsSinceEpoch;
      await box.put(customerId, customer);
    }
  }

  /// Restore a deleted customer
  static Future<void> restoreCustomer(String customerId) async {
    final box = customers();
    final customer = box.get(customerId);
    if (customer != null) {
      customer.isDeleted = false;
      customer.deletedAt = null;
      await box.put(customerId, customer);
    }
  }

  /// Get all active customers (not deleted)
  static List<Customer> getActiveCustomers() {
    final box = customers();
    return box.values
        .where((c) => !c.isDeleted && c.status == 'active')
        .toList();
  }

  /// Get all customers including inactive (but not deleted)
  static List<Customer> getAllCustomers() {
    final box = customers();
    return box.values.where((c) => !c.isDeleted).toList();
  }

  /// Search customers by name or phone
  static List<Customer> searchCustomers(String query) {
    final box = customers();
    final lowerQuery = query.toLowerCase();
    return box.values
        .where((c) =>
            !c.isDeleted &&
            (c.name.toLowerCase().contains(lowerQuery) ||
                (c.phone?.toLowerCase().contains(lowerQuery) ?? false)))
        .toList();
  }

  /// Get a customer by ID
  static Customer? getCustomer(String customerId) {
    final box = customers();
    return box.get(customerId);
  }

  /// Check if customer phone already exists (for duplicate warning)
  static bool phoneExists(String phone, {String? excludeCustomerId}) {
    final box = customers();
    return box.values.any((c) =>
        !c.isDeleted &&
        c.phone == phone &&
        (excludeCustomerId == null || c.id != excludeCustomerId));
  }

  // -------------------------------------------------------------------------
  // Customer Ledger operations
  // -------------------------------------------------------------------------

  /// Add a ledger entry for a customer transaction
  static Future<void> addLedgerEntry(CustomerLedger entry) async {
    final box = customerLedger();
    await box.put(entry.id, entry);
  }

  /// Get all ledger entries for a customer
  static List<CustomerLedger> getCustomerLedger(String customerId) {
    final box = customerLedger();
    return box.values
        .where((e) => e.customerId == customerId)
        .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
  }

  /// Get customer current balance from ledger
  static double getCustomerBalance(String customerId) {
    final customer = getCustomer(customerId);
    if (customer == null) return 0;
    return customer.currentBalance;
  }

  // -------------------------------------------------------------------------
  // Payment operations
  // -------------------------------------------------------------------------

  /// Record a payment
  static Future<void> recordPayment(Payment payment) async {
    final box = payments();
    await box.put(payment.id, payment);
    
    // Update customer balance
    final customer = getCustomer(payment.customerId);
    if (customer != null) {
      customer.currentBalance -= payment.amount;
      await updateCustomer(customer);
      
      // Add ledger entry
      final ledgerEntry = CustomerLedger(
        id: const Uuid().v4(),
        customerId: payment.customerId,
        type: 'payment',
        referenceId: payment.id,
        date: payment.paymentDate,
        debitAmount: 0,
        creditAmount: payment.amount,
        balanceAfter: customer.currentBalance,
        note: payment.note,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await addLedgerEntry(ledgerEntry);
    }
  }

  /// Get all payments for a customer
  static List<Payment> getCustomerPayments(String customerId) {
    final box = payments();
    return box.values
        .where((p) => p.customerId == customerId && !p.isDeleted)
        .toList()
        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
  }

  /// Soft delete a payment
  static Future<void> deletePayment(String paymentId) async {
    final box = payments();
    final payment = box.get(paymentId);
    if (payment != null) {
      payment.isDeleted = true;
      await box.put(paymentId, payment);
      
      // Reverse the customer balance
      final customer = getCustomer(payment.customerId);
      if (customer != null) {
        customer.currentBalance += payment.amount;
        await updateCustomer(customer);
        
        // Create reversing ledger entry for audit trail
        final ledgerEntry = CustomerLedger(
          id: const Uuid().v4(),
          customerId: payment.customerId,
          type: 'refund',
          referenceId: payment.id,
          date: DateTime.now().millisecondsSinceEpoch,
          debitAmount: payment.amount,
          creditAmount: 0,
          balanceAfter: customer.currentBalance,
          note: 'Payment deletion reversal',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        await addLedgerEntry(ledgerEntry);
      }
    }
  }

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
    // Normal sales
    for (final s in sales().values) {
      if (!s.isDeleted) t += s.amount;
    }
    // Broker sales (total sale amount)
    for (final bs in brokerSaleRecords().values) {
      t += bs.totalSaleAmount;
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
      if (!s.isDeleted) t += s.costPrice;
    }
    return t;
  }

  /// ရောင်းချမှုအားလုံး၏ ရောင်းပွဲခ စုစုပေါင်း။
  static double totalSalesCommission() {
    double t = 0;
    // Normal sales commission
    for (final s in sales().values) {
      if (!s.isDeleted) t += s.commissionFee;
    }
    // Broker commission
    for (final bs in brokerSaleRecords().values) {
      t += bs.brokerCommission;
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
      if (!s.isDeleted && s.gemstoneId == gemstoneId) {
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
      if (!s.isDeleted && s.gemstoneId == gemstoneId && !s.isFragmentSource) {
        total += s.quantity;
      }
    }
    return total;
  }

  /// ပစ္စည်းတစ်ခုချင်းစီ၏ ကျန်ရှိအရေအတွက်
  /// Accounts for sales deductions AND broker consignment deductions
  static int gemstoneRemainingQuantity(Gemstone g) {
    // Calculate actual remaining: original quantity - sold - active broker consigned (WHOLE STONE ONLY)
    final sold = gemstoneSoldQuantity(g.id);
    int brokerHeld = 0;
    final activeBrokers = getActiveBrokerConsignmentsForPurchase(g.id);
    for (final bc in activeBrokers) {
      // CRITICAL: Only count WHOLE STONE consignments, NEVER count FRAGMENT consignments
      // Fragment consignments are independent and should not affect Whole Stone remaining quantity
      if (bc.historicalData.sourceType == 'breakdown_item') {
        continue; // Skip fragment consignments - they have their own inventory tracking
      }
      // Net held by broker = consigned - returned - sold by broker
      final held = (bc.consignedQuantity - bc.returnedQuantity - bc.soldQuantity).toInt();
      if (held > 0) brokerHeld += held;
    }
    final remaining = g.quantity - sold - brokerHeld;
    return remaining < 0 ? 0 : remaining;
  }

    /// Get remaining quantity for a specific fragment
  /// breakdownItems['quantity'] is the current remaining quantity
  /// (decremented on sale save, incremented on sale delete/restore)
  static int getFragmentRemainingQuantity(String gemstoneId, String fragmentName) {
    final gemstone = gemstones().get(gemstoneId);
    if (gemstone == null || gemstone.breakdownItems == null) return 0;
    final itemData = gemstone.breakdownItems![fragmentName];
    if (itemData == null) return 0;
    // breakdownItems['quantity'] is the current remaining quantity
    final int remainingQty = (itemData['quantity'] as num?)?.toInt() ?? 0;
    return remainingQty < 0 ? 0 : remainingQty;
  }

  /// Check if gemstone is fully sold out (both whole stones AND all fragments)
  static bool isGemstoneFullySoldOut(Gemstone g) {
    // Condition A: No whole stones left
    if (g.quantity > 0) return false;
    
    // Condition B: Check if all fragments are sold out
    if (g.breakdownItems != null && g.breakdownItems!.isNotEmpty) {
      for (final fragmentData in g.breakdownItems!.values) {
        if (fragmentData is Map<String, dynamic>) {
          final qtyObj = fragmentData['quantity'];
          final qty = (qtyObj is num) ? (qtyObj as num).toInt() : 0;
          if (qty > 0) return false; // At least one fragment still has stock
        }
      }
    }
    
    // Both conditions met: fully sold out
    return true;
  }

  /// ပစ္စည်းတစ်ခုချင်းစီ၏ အရောင်းအကြိမ်အရေအတွက် (ဘယ်နှစ်ကြိမ် ရောင်းခဲ့သည်)
  static int gemstoneSaleCount(String gemstoneId) {
    int count = 0;
    for (final s in sales().values) {
      if (!s.isDeleted && s.gemstoneId == gemstoneId) {
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
    
    // Calculate all cost-tracking values from ACTIVE sales only
    final profitData = calculateRemainingCostAndProfit(gemstoneId);
    g.recoveredCost = profitData['recoveredCost'] ?? 0;
    g.remainingCost = profitData['remainingCost'] ?? 0;
    g.remainingCostBalance = g.remainingCost;  // Keep in sync with remainingCost
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
        .where((s) => !s.isDeleted && s.gemstoneId == gemstoneId)
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

  /// Calculate remaining cost, recovered cost, and total profit from sales records
  /// Returns {recoveredCost, remainingCost, totalProfit}
  /// 
  /// Uses TOTAL PURCHASE COST (costPrice + all fees) as the single source of truth.
  /// This is the value displayed as "စုစုပေါင်းအရင်း".
  /// Correctly calculates:
  /// - Recovered Principal = min(totalPurchaseCost, totalNetSales)
  /// - Remaining Principal = max(totalPurchaseCost - totalNetSales, 0)
  /// - Profit = max(totalNetSales - totalPurchaseCost, 0)
  static Map<String, double> calculateRemainingCostAndProfit(String gemstoneId) {
    final g = gemstoneById(gemstoneId);
    if (g == null) return {'recoveredCost': 0, 'remainingCost': 0, 'totalProfit': 0};

    // Use TOTAL PURCHASE COST (purchase price + all purchase expenses)
    // This is gemstoneTotalCost = costPrice + commissionFee + processingFee + repairFee + breakageFee + bloodFee + laborFee + miscFee
    final totalPurchaseCost = gemstoneTotalCost(g);
    double remainingCost = totalPurchaseCost;
    double totalProfit = 0;

    // Get all sales for this gemstone, sorted by date (oldest first)
    final salesForGem = sales()
        .values
        .where((s) => !s.isDeleted && s.gemstoneId == gemstoneId)
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

    // Calculate recovered cost = min(totalPurchaseCost, totalNetSales)
    double totalNetSales = totalPurchaseCost - remainingCost;
    double recoveredCost = totalNetSales > totalPurchaseCost ? totalPurchaseCost : totalNetSales;

    return {
      'recoveredCost': recoveredCost < 0 ? 0.0 : recoveredCost,
      'remainingCost': remainingCost < 0 ? 0.0 : remainingCost,
      'totalProfit': totalProfit < 0 ? 0.0 : totalProfit,
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

  /// လက်ရှိ User သည် Admin (Super Admin) ဖြစ်သည်ကို စစ်ဆေးခြင်း
  ///
  /// Super Admin သည် AppUser ဖြစ်ပြီး အမြဲတမ်း ကန့်သတ်မှုမရှိ ဝင်ရောက်ခွင့်ရှိရမည်။
  /// Session ၏ `userType` သည် 'AppUser' ဖြစ်ပါက (သို့မဟုတ် role သည်
  /// admin/super_admin/owner တစ်ခုခုဖြစ်ပါက) admin အဖြစ် သတ်မှတ်သည်။
  /// ဤနည်းဖြင့် role string မကိုက်ညီမှု (admin vs super_admin vs owner)
  /// ကြောင့် Super Admin ကန့်သတ်ခံရခြင်းကို လုံးဝ ကာကွယ်သည်။
  static bool isCurrentUserAdmin() {
    try {
      final s = Hive.box(sessionBox);
      // Primary check: any logged-in AppUser is a Super Admin.
      final userType = s.get('userType', defaultValue: '') as String;
      if (userType == 'AppUser') return true;

      // Fallback check: role string indicates an administrator/owner.
      final role = (s.get('userRole', defaultValue: '') as String).toLowerCase();
      if (role == 'admin' || role == 'super_admin' || role == 'owner') {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// လက်ရှိ login ဝင်သူသည် default Super Admin ဖြစ်မှ မဖြစ် စစ်ဆေးခြင်း။
  ///
  /// Rule: `username == "admin"` သို့မဟုတ် `role == "super_admin"` ဖြစ်ပါက
  /// Super Admin အဖြစ် သတ်မှတ်ပြီး permission စစ်ဆေးမှုအားလုံး ချက်ခြင်း TRUE ဖြစ်သည်။
  static bool isCurrentUserSuperAdmin() {
    try {
      final s = Hive.box(sessionBox);
      final username =
          (s.get('userUsername', defaultValue: '') as String).toLowerCase();
      final role =
          (s.get('userRole', defaultValue: '') as String).toLowerCase();
      final userType = s.get('userType', defaultValue: '') as String;

      if (username == 'admin') return true;
      if (role == 'super_admin' || role == 'admin' || role == 'owner') {
        return true;
      }
      if (userType == 'AppUser') return true;
      return false;
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

  // ---------------------------------------------------------------------------
  // Sale-Customer Ledger Integration
  // ---------------------------------------------------------------------------

  /// Apply customer ledger impact when a sale is created or edited
  static Future<void> applySaleCustomerLedger(Sale sale, {Sale? oldSale}) async {
    if ((sale.customerId?.isEmpty ?? true)) return;
    final customer = getCustomer(sale.customerId!);
    if (customer == null || customer.isDeleted) return;
    if (sale.isDeleted) return;

    // If editing, reverse the old sale impact first
    if (oldSale != null && oldSale.customerId == sale.customerId) {
      if (oldSale.paymentMethod == 'credit') {
        customer.currentBalance -= oldSale.amount;
      }
    }

    // Apply new sale impact
    if (sale.paymentMethod == 'credit') {
      customer.currentBalance += sale.amount;
      final ledgerEntry = CustomerLedger(
        id: const Uuid().v4(),
        customerId: sale.customerId!,
        type: 'sale',
        referenceId: sale.id,
        date: sale.saleDate,
        debitAmount: sale.amount,
        creditAmount: 0,
        balanceAfter: customer.currentBalance,
        note: 'အရောင်း: ${sale.gemstoneName}',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await addLedgerEntry(ledgerEntry);
    } else {
      final ledgerEntry = CustomerLedger(
        id: const Uuid().v4(),
        customerId: sale.customerId!,
        type: 'sale',
        referenceId: sale.id,
        date: sale.saleDate,
        debitAmount: 0,
        creditAmount: sale.amount,
        balanceAfter: customer.currentBalance,
        note: 'အရောင်း (${sale.paymentMethod}): ${sale.gemstoneName}',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await addLedgerEntry(ledgerEntry);
    }
    await updateCustomer(customer);
  }

  /// Reverse customer ledger impact when a sale is deleted
  static Future<void> reverseSaleCustomerLedger(Sale sale) async {
    if ((sale.customerId?.isEmpty ?? true)) return;
    final customer = getCustomer(sale.customerId!);
    if (customer == null) return;
    if (sale.paymentMethod == 'credit') {
      customer.currentBalance -= sale.amount;
    }
    final reversalEntry = CustomerLedger(
      id: const Uuid().v4(),
      customerId: sale.customerId!,
      type: 'adjustment',
      referenceId: sale.id,
      date: DateTime.now().millisecondsSinceEpoch,
      debitAmount: 0,
      creditAmount: sale.amount,
      balanceAfter: customer.currentBalance,
      note: 'အရောင်းမှတ်တမ်း ပယ်ဖျက်ခြင်း: ${sale.gemstoneName}',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await addLedgerEntry(reversalEntry);
    await updateCustomer(customer);
  }

  // ---------------------------------------------------------------------------
  // Soft Delete & Restore Sale
  // ---------------------------------------------------------------------------

  /// Soft delete a sale record (mark as deleted instead of hard delete)
  static Future<void> softDeleteSale(dynamic saleKey, String deleteReason) async {
    try {
      final sale = sales().get(saleKey) as Sale?;
      if (sale == null) return;

      final currentUser = LocalDb.currentUser();
      if (currentUser.isEmpty) return;

      // Mark as soft deleted
      sale.isDeleted = true;
      sale.deletedAt = DateTime.now().millisecondsSinceEpoch;
      sale.deletedBy = currentUser['id'] as String;
      sale.deleteReason = deleteReason;

      await sales().put(saleKey, sale);

      // Reverse customer ledger impact
      await reverseSaleCustomerLedger(sale);

      // Restore fragment quantity and weight if this is a fragment sale
      if (sale.gemstoneId.isNotEmpty && sale.isFragmentSource && sale.fragmentName != null && sale.fragmentName!.isNotEmpty) {
        final gemstone = gemstones().get(sale.gemstoneId);
        if (gemstone != null && gemstone.breakdownItems != null) {
          // Only restore the specific fragment that was sold
          final itemData = gemstone.breakdownItems![sale.fragmentName!];
          if (itemData is Map<String, dynamic>) {
            // Restore quantity
            final currentQty = (itemData['quantity'] as num?)?.toInt() ?? 0;
            itemData['quantity'] = currentQty + sale.quantity;
            // Restore weight if it was deducted
            if (sale.fragmentWeight != null && sale.fragmentWeight! > 0) {
              final currentWeight = (itemData['weight'] as num?)?.toDouble() ?? 0;
              itemData['weight'] = currentWeight + sale.fragmentWeight!;
            }
          }
          final hiveKey = gemstoneKeyById(sale.gemstoneId);
          if (hiveKey != null) {
            await gemstones().put(hiveKey, gemstone);
          }
        }
      }

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

      final currentUser = LocalDb.currentUser();
      if (currentUser.isEmpty) return;

      // Restore the sale
      sale.isDeleted = false;
      sale.deletedAt = null;
      sale.deletedBy = null;
      sale.deleteReason = null;

      await sales().put(saleKey, sale);

      // Reapply customer ledger impact
      await applySaleCustomerLedger(sale);

      // Re-deduct fragment quantity and weight if this is a fragment sale
      if (sale.gemstoneId.isNotEmpty && sale.isFragmentSource && sale.fragmentName != null && sale.fragmentName!.isNotEmpty) {
        final gemstone = gemstones().get(sale.gemstoneId);
        if (gemstone != null && gemstone.breakdownItems != null) {
          // Only re-deduct the specific fragment that was sold
          final itemData = gemstone.breakdownItems![sale.fragmentName!];
          if (itemData is Map<String, dynamic>) {
            // Deduct quantity
            final currentQty = (itemData['quantity'] as num?)?.toInt() ?? 0;
            if (currentQty >= sale.quantity) {
              itemData['quantity'] = currentQty - sale.quantity;
            }
            // Deduct weight if it was originally deducted
            if (sale.fragmentWeight != null && sale.fragmentWeight! > 0) {
              final currentWeight = (itemData['weight'] as num?)?.toDouble() ?? 0;
              if (currentWeight >= sale.fragmentWeight!) {
                itemData['weight'] = currentWeight - sale.fragmentWeight!;
              }
            }
          }
          final hiveKey2 = gemstoneKeyById(sale.gemstoneId);
          if (hiveKey2 != null) {
            await gemstones().put(hiveKey2, gemstone);
          }
        }
      }

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
    if (isCurrentUserSuperAdmin()) return true;
    return isCurrentUserAdmin();
  }

  /// Sale ကို Restore နိုင်သည်ကို စစ်ဆေးခြင်း (Admin-only)
  static bool canRestoreSale() {
    if (isCurrentUserSuperAdmin()) return true;
    return isCurrentUserAdmin();
  }

  /// Sale ကို Edit နိုင်သည်ကို စစ်ဆေးခြင်း (Admin-only)
  static bool canEditSale() {
    if (isCurrentUserSuperAdmin()) return true;
    return isCurrentUserAdmin();
  }

  /// Purchase ကို ဖျက်နိုင်သည်ကို စစ်ဆေးခြင်း (Admin-only)
  static bool canDeletePurchase() {
    if (isCurrentUserSuperAdmin()) return true;
    return isCurrentUserAdmin();
  }

  /// Purchase ကို Edit နိုင်သည်ကို စစ်ဆေးခြင်း (Admin-only)
  static bool canEditPurchase() {
    if (isCurrentUserSuperAdmin()) return true;
    return isCurrentUserAdmin();
  }

  /// လုပ်ဆောင်ချက်ကို Admin သာ ပြုလုပ်နိုင်သည်ဆိုသည့် Error message
  static String adminOnlyErrorMessage() {
    return 'ဤလုပ်ဆောင်ချက်ကို Admin သာ ပြုလုပ်နိုင်ပါသည်။';
  }

  // -------------------------------------------------------------------------
  // Broker Consignment CRUD Operations
  // -------------------------------------------------------------------------

  /// Helper: Update a Gemstone by its purchaseId (UUID string).
  /// Finds the original Hive key (numeric) and updates that record only.
  /// This prevents duplicate Gemstone records from being created.
  static Future<void> _updateGemstoneByPurchaseId(
    String purchaseId,
    Gemstone updated,
  ) async {
    final gemstones = Hive.box<Gemstone>(gemstonesBox);
    
    // LOG: Entry with purchaseId
    developer.log(
      '[HIVE-LOOKUP-START] Searching for purchaseId=$purchaseId in Hive box',
      level: 1000,
      name: 'HIVE_LOOKUP_DEBUG',
    );
    RCALogCollector().addLog('HIVE_LOOKUP_DEBUG', '[HIVE-LOOKUP-START] Searching for purchaseId=$purchaseId in Hive box', 1000);
    
    // LOG: All Hive keys and gemstone IDs
    final allKeys = gemstones.keys.toList();
    developer.log(
      '[HIVE-LOOKUP-KEYS] Total Hive keys: ${allKeys.length}',
      level: 1000,
      name: 'HIVE_LOOKUP_DEBUG',
    );
    RCALogCollector().addLog('HIVE_LOOKUP_DEBUG', '[HIVE-LOOKUP-KEYS] Total Hive keys: ${allKeys.length}', 1000);
    
    for (final k in allKeys) {
      final g = gemstones.get(k);
      final message = '[HIVE-LOOKUP-ENTRY] hiveKey=$k | gemstoneId=${g?.id} | gemstoneName=${g?.name} | matches=${g?.id == purchaseId}';
      developer.log(
        message,
        level: 1000,
        name: 'HIVE_LOOKUP_DEBUG',
      );
      RCALogCollector().addLog('HIVE_LOOKUP_DEBUG', message, 1000);
    }
    
    final key = gemstones.keys.firstWhere(
      (k) => gemstones.get(k)?.id == purchaseId,
      orElse: () => null,
    );
    
    // LOG: Result of lookup
    if (key != null) {
      final foundMsg = '[HIVE-LOOKUP-FOUND] purchaseId=$purchaseId | foundHiveKey=$key | WILL EXECUTE gemstones.put()';
      developer.log(foundMsg, level: 1000, name: 'HIVE_LOOKUP_DEBUG');
      RCALogCollector().addLog('HIVE_LOOKUP_DEBUG', foundMsg, 1000);
      await gemstones.put(key, updated);
      final savedMsg = '[HIVE-LOOKUP-SAVED] purchaseId=$purchaseId | hiveKey=$key | SAVE COMPLETED';
      developer.log(savedMsg, level: 1000, name: 'HIVE_LOOKUP_DEBUG');
      RCALogCollector().addLog('HIVE_LOOKUP_DEBUG', savedMsg, 1000);
    } else {
      final notFoundMsg = '[HIVE-LOOKUP-NOT-FOUND] purchaseId=$purchaseId | NO MATCHING HIVE KEY FOUND | gemstones.put() SKIPPED';
      developer.log(notFoundMsg, level: 1000, name: 'HIVE_LOOKUP_DEBUG');
      RCALogCollector().addLog('HIVE_LOOKUP_DEBUG', notFoundMsg, 1000);
    }
  }

  /// Create new Broker Consignment with automatic quantity deduction
  static Future<BrokerConsignment> createBrokerConsignment({
    required String purchaseId,
    required double consignedQuantity,
    required String sourceType, // "whole_stone" or "breakdown_item"
    String? breakdownItemName,
    required String brokerName,
    required String brokerPhone,
    required String brokerAddress,
    String? brokerSocialAccount,
    String notes = '',
    List<String> photoPaths = const [],
    String? voucherId, // Shared UUID for grouped submission
    String? voucherNumber, // Shared human-readable number (BC-YYYYMMDD-NNNN)
    double? weight, // Optional weight value
    String? weightUnit, // Unit of weight
  }) async {
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    final gemstones = Hive.box<Gemstone>(gemstonesBox);
    
    // Get the purchase record
    final purchase = gemstones.values.firstWhere(
      (g) => g.id == purchaseId,
      orElse: () => throw Exception('Purchase Record not found'),
    );
    
    // LOG: Entry point with full state
    RCALogCollector().addLog(
      'RCA_BROKER_CONSIGNMENT',
      '[RCA-ENTRY] purchaseId=$purchaseId | gemstoneName=${purchase.name} | sourceType=$sourceType | breakdownItemName=$breakdownItemName | requestedQty=$consignedQuantity | purchase.quantity=${purchase.quantity} | purchase.remainingQuantity=${purchase.remainingQuantity} | breakdownItems=${purchase.breakdownItems}',
      1000,
    );
    developer.log(
      '[RCA-ENTRY] purchaseId=$purchaseId | gemstoneName=${purchase.name} | sourceType=$sourceType | breakdownItemName=$breakdownItemName | requestedQty=$consignedQuantity | purchase.quantity=${purchase.quantity} | purchase.remainingQuantity=${purchase.remainingQuantity} | breakdownItems=${purchase.breakdownItems}',
      level: 1000,
      name: 'RCA_BROKER_CONSIGNMENT',
    );

    // Validate quantity based on source type
    if (sourceType == 'breakdown_item') {
      // For breakdown items, validate against breakdown item quantity
      if (breakdownItemName == null || breakdownItemName.isEmpty) {
        throw Exception('Breakdown item name is required');
      }
      if (!purchase.breakdownItems.containsKey(breakdownItemName)) {
        throw Exception('Breakdown item not found');
      }
      final availableQty = (purchase.breakdownItems[breakdownItemName]?['quantity'] as int?) ?? 0;
      final dynamicRemainingWhole = gemstoneRemainingQuantity(purchase);
      
      // LOG: Fragment validation with full context
      RCALogCollector().addLog(
        'RCA_BROKER_CONSIGNMENT',
        '[RCA-FRAG-VALIDATE] breakdownItemName=$breakdownItemName | requestedQty=$consignedQuantity | availableQty=$availableQty | dynamicRemainingWhole=$dynamicRemainingWhole | comparison: $consignedQuantity > $availableQty = ${consignedQuantity > availableQty} | purchase.remainingQuantity=${purchase.remainingQuantity}',
        1000,
      );
      developer.log(
        '[RCA-FRAG-VALIDATE] breakdownItemName=$breakdownItemName | requestedQty=$consignedQuantity | availableQty=$availableQty | dynamicRemainingWhole=$dynamicRemainingWhole | comparison: $consignedQuantity > $availableQty = ${consignedQuantity > availableQty} | purchase.remainingQuantity=${purchase.remainingQuantity}',
        level: 1000,
        name: 'RCA_BROKER_CONSIGNMENT',
      );
      
      if (consignedQuantity > availableQty) {
        RCALogCollector().addLog(
          'RCA_BROKER_CONSIGNMENT',
          '[RCA-FRAG-THROW] LINE 1770 | gemstone=${purchase.name} | breakdownItemName=$breakdownItemName | consignedQuantity=$consignedQuantity | availableQty=$availableQty',
          2,
        );
        developer.log(
          '[RCA-FRAG-THROW] LINE 1770 | gemstone=${purchase.name} | breakdownItemName=$breakdownItemName | consignedQuantity=$consignedQuantity | availableQty=$availableQty',
          level: 1000,
          name: 'RCA_BROKER_CONSIGNMENT',
        );
        throw Exception('လက်ကျန်အရေအတွက် မလုံလောက်ပါ။');
      }
    } else {
      // For whole stone, validate against remaining quantity
      final dynamicRemaining = gemstoneRemainingQuantity(purchase);
      
      // LOG: Whole stone validation - FIX: Use dynamicRemaining instead of stale purchase.remainingQuantity
      RCALogCollector().addLog(
        'RCA_BROKER_CONSIGNMENT',
        '[RCA-WHOLE-VALIDATION-FIX] gemstone=${purchase.name} | consignedQuantity=$consignedQuantity | purchase.remainingQuantity=${purchase.remainingQuantity} | dynamicRemaining=$dynamicRemaining | condition: $consignedQuantity > $dynamicRemaining = ${consignedQuantity > dynamicRemaining}',
        1000,
      );
      developer.log(
        '[RCA-WHOLE-VALIDATION-FIX] gemstone=${purchase.name} | consignedQuantity=$consignedQuantity | purchase.remainingQuantity=${purchase.remainingQuantity} | dynamicRemaining=$dynamicRemaining | condition: $consignedQuantity > $dynamicRemaining = ${consignedQuantity > dynamicRemaining}',
        level: 1000,
        name: 'RCA_BROKER_CONSIGNMENT',
      );
      
      if (consignedQuantity > dynamicRemaining) {
        RCALogCollector().addLog(
          'RCA_BROKER_CONSIGNMENT',
          '[RCA-WHOLE-THROW-FIX] LINE 1851 | gemstone=${purchase.name} | consignedQuantity=$consignedQuantity | dynamicRemaining=$dynamicRemaining',
          2,
        );
        developer.log(
          '[RCA-WHOLE-THROW-FIX] LINE 1851 | gemstone=${purchase.name} | consignedQuantity=$consignedQuantity | dynamicRemaining=$dynamicRemaining',
          level: 1000,
          name: 'RCA_BROKER_CONSIGNMENT',
        );
        throw Exception('ထည့်သွင်းသောအရေအတွက်သည် ကျန်ရှိအရေအတွက်ထက် မကျော်လွန်ရပါ။');
      }
    }

    // Capture historical data
    final now = DateTime.now().millisecondsSinceEpoch;
    final historicalData = BrokerHistoricalData(
      purchaseName: purchase.name,
      purchaseDate: purchase.createdAt,
      originalSeller: '', // No seller field in Gemstone
      gemstoneType: purchase.type,
      sourceType: sourceType,
      breakdownItemName: breakdownItemName,
      originalQuantity: purchase.quantity.toDouble(),
      originalWeight: purchase.weightCarat,
      capturedAt: now,
    );

    // Create broker consignment
    final brokerConsignment = BrokerConsignment(
      id: genId(),
      purchaseId: purchaseId,
      sourceType: sourceType,
      breakdownItemName: breakdownItemName,
      consignedQuantity: consignedQuantity,
      historicalData: historicalData,
      brokerName: brokerName,
      brokerPhone: brokerPhone,
      brokerAddress: brokerAddress,
      brokerSocialAccount: brokerSocialAccount,
      notes: notes,
      photoPaths: photoPaths,
      createdAt: now,
      voucherId: voucherId, // Assign shared voucher ID
      voucherNumber: voucherNumber, // Assign shared voucher number
      weight: weight, // Optional weight value
      weightUnit: weightUnit, // Unit of weight
    );

    // PHASE 1: Deduct quantity based on source type
    // CRITICAL: Only modify the selected source record, never cross-reference
    if (sourceType == 'breakdown_item' && breakdownItemName != null) {
      // FRAGMENT PATH: Only touch breakdown item, never touch whole stone
      final currentQty = (purchase.breakdownItems[breakdownItemName]?['quantity'] as int?) ?? 0;
      final newQty = currentQty - consignedQuantity.toInt();
      if (newQty < 0) {
        throw Exception('Breakdown item quantity cannot go below zero');
      }
      RCALogCollector().addLog(
        'RCA_BROKER_CONSIGNMENT',
        '[RCA-FRAG-DEDUCT] breakdownItemName=$breakdownItemName | before=$currentQty | deduct=${consignedQuantity.toInt()} | after=$newQty',
        1000,
      );
      developer.log(
        '[RCA-FRAG-DEDUCT] breakdownItemName=$breakdownItemName | before=$currentQty | deduct=${consignedQuantity.toInt()} | after=$newQty',
        level: 1000,
        name: 'RCA_BROKER_CONSIGNMENT',
      );
      purchase.breakdownItems[breakdownItemName] = {'quantity': newQty, 'weight': null, 'weightUnit': null};
      // IMPORTANT: Do NOT modify purchase.remainingQuantity for fragments
      // Fragment deduction is INDEPENDENT of whole stone
    } else {
      // WHOLE STONE PATH: Only touch whole stone remaining quantity
      final beforeRemaining = purchase.remainingQuantity;
      purchase.remainingQuantity -= consignedQuantity.toInt();
      RCALogCollector().addLog(
        'RCA_BROKER_CONSIGNMENT',
        '[RCA-WHOLE-DEDUCT] before=$beforeRemaining | deduct=${consignedQuantity.toInt()} | after=${purchase.remainingQuantity}',
        1000,
      );
      developer.log(
        '[RCA-WHOLE-DEDUCT] before=$beforeRemaining | deduct=${consignedQuantity.toInt()} | after=${purchase.remainingQuantity}',
        level: 1000,
        name: 'RCA_BROKER_CONSIGNMENT',
      );
      // IMPORTANT: Do NOT modify breakdown items for whole stone
    }
    
    // PHASE 2: Save only the modified source record
    // This ensures no cross-contamination between whole stone and fragments
    await _updateGemstoneByPurchaseId(purchaseId, purchase);
    
    // PHASE 3: Recalculate ledger ONLY for the selected source
    await updateGemstoneProductLedger(purchaseId);

    // Save broker consignment
    await brokers.put(brokerConsignment.id, brokerConsignment);

    // Create audit log
    final currentUser = LocalDb.currentUser();
    final auditLogDetails = sourceType == 'breakdown_item'
        ? 'Consigned ${consignedQuantity} of $breakdownItemName from ${purchase.name} to ${brokerName}'
        : 'Consigned ${consignedQuantity} from ${purchase.name} to ${brokerName}';
    final auditLog = AuditLog(
      id: genId(),
      action: 'BROKER_CONSIGNMENT_CREATED',
      userId: currentUser['id'] as String,
      userName: currentUser['name'] as String,
      timestamp: now,
      details: auditLogDetails,
    );
    await createAuditLog(auditLog);

    return brokerConsignment;
  }

  /// Generate next voucher number for today (BC-YYYYMMDD-NNNN)
  /// Counts DISTINCT vouchers, not item records (one voucher can contain multiple items)
  static String generateNextVoucherNumber() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    
    // Collect all distinct voucher numbers for today
    final distinctVouchers = brokers.values
        .where((b) => b.voucherNumber != null && b.voucherNumber!.startsWith('BC-$dateStr-'))
        .map((b) => b.voucherNumber!)
        .toSet(); // Remove duplicates
    
    // Find the highest sequence number
    int maxSequence = 0;
    for (final voucherNum in distinctVouchers) {
      try {
        // Extract the last 4 digits (suffix after the last dash)
        final parts = voucherNum.split('-');
        if (parts.length == 3) {
          final suffix = parts[2];
          final sequenceNum = int.tryParse(suffix) ?? 0;
          if (sequenceNum > maxSequence) {
            maxSequence = sequenceNum;
          }
        }
      } catch (e) {
        // Safely ignore malformed voucher numbers
        continue;
      }
    }
    
    // Generate next sequence number (4 digits, zero-padded)
    final nextSequence = (maxSequence + 1).toString().padLeft(4, '0');
    return 'BC-$dateStr-$nextSequence';
  }

  /// Get all active broker consignments for a purchase
  static List<BrokerConsignment> getActiveBrokerConsignmentsForPurchase(String purchaseId) {
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    return brokers.values
        .where((b) => b.purchaseId == purchaseId && b.isActive)
        .toList();
  }

  /// Get broker consignment by ID
  static BrokerConsignment? getBrokerConsignment(String id) {
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    return brokers.get(id);
  }

  /// Get all active broker consignments
  static List<BrokerConsignment> getAllActiveBrokerConsignments() {
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    return brokers.values.where((b) => b.isActive).toList();
  }

  /// Phase C.1: Group active broker consignments by voucherId
  /// Returns Map<String, List<BrokerConsignment>>
  /// - Key: voucherId (or unique record ID for legacy records with null voucherId)
  /// - Value: List of BrokerConsignment records in that group
  /// - Sorted by newest first (latest createdAt in each group)
  static Map<String, List<BrokerConsignment>> getGroupedBrokerConsignments() {
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    final active = brokers.values.where((b) => b.isActive).toList();
    
    final grouped = <String, List<BrokerConsignment>>{};
    
    for (final bc in active) {
      // Use voucherId as grouping key if present, otherwise use record's own ID (legacy)
      final groupKey = bc.voucherId ?? bc.id;
      grouped.putIfAbsent(groupKey, () => []).add(bc);
    }
    
    // Sort groups by newest first (use latest createdAt in each group)
    final sorted = grouped.entries.toList()
      ..sort((a, b) {
        final latestA = a.value.fold<int>(0, (max, bc) => bc.createdAt > max ? bc.createdAt : max);
        final latestB = b.value.fold<int>(0, (max, bc) => bc.createdAt > max ? bc.createdAt : max);
        return latestB.compareTo(latestA);
      });
    
    return Map.fromEntries(sorted);
  }

  /// Phase C.1: Get all records in a specific voucher group
  /// groupKey: voucherId or record ID (for legacy records)
  static List<BrokerConsignment> getBrokerConsignmentsByGroup(String groupKey) {
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    final active = brokers.values.where((b) => b.isActive).toList();
    
    return active.where((bc) {
      final key = bc.voucherId ?? bc.id;
      return key == groupKey;
    }).toList();
  }

  /// Phase C.1: Calculate aggregate voucher summary
  /// Returns: (totalConsigned, totalSold, totalReturned, totalRemaining, itemCount, status)
  static Map<String, dynamic> getVoucherSummary(String groupKey) {
    final items = getBrokerConsignmentsByGroup(groupKey);
    if (items.isEmpty) return {};
    
    final totalConsigned = items.fold<double>(0, (sum, bc) => sum + bc.consignedQuantity);
    final totalSold = items.fold<double>(0, (sum, bc) => sum + bc.soldQuantity);
    final totalReturned = items.fold<double>(0, (sum, bc) => sum + bc.returnedQuantity);
    final totalRemaining = items.fold<double>(0, (sum, bc) => sum + bc.remainingQuantity);
    final itemCount = items.length;
    
    // Derive status from items
    final allCompleted = items.every((bc) => bc.remainingQuantity == 0);
    final somePartial = items.any((bc) => bc.soldQuantity > 0 || bc.returnedQuantity > 0);
    final someRemaining = items.any((bc) => bc.remainingQuantity > 0);
    
    String status;
    if (allCompleted) {
      status = 'ပြီးစီး';
    } else if (somePartial && someRemaining) {
      status = 'တစ်စိတ်တစ်ပိုင်း ပြန်လည်အပ်';
    } else {
      status = 'လုပ်ဆောင်ဆဲ';
    }
    
    return {
      'totalConsigned': totalConsigned,
      'totalSold': totalSold,
      'totalReturned': totalReturned,
      'totalRemaining': totalRemaining,
      'itemCount': itemCount,
      'status': status,
      'brokerName': items.first.brokerName,
      'createdAt': items.first.createdAt,
      'voucherId': items.first.voucherId,
      'voucherNumber': items.first.voucherNumber,
      'isLegacy': items.first.voucherId == null,
    };
  }

  /// Phase C.1: Check if a group is a legacy record (null voucherId)
  static bool isLegacyGroup(String groupKey) {
    final items = getBrokerConsignmentsByGroup(groupKey);
    return items.isNotEmpty && items.first.voucherId == null;
  }

  /// Update broker sold quantity
  static Future<void> updateBrokerSoldQuantity(String brokerId, double soldQuantity) async {
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    final broker = brokers.get(brokerId);
    
    if (broker == null) throw Exception('Broker Consignment not found');
    if (soldQuantity > broker.remainingQuantity) {
      throw Exception('ရောင်းလိုသောအရေအတွက်သည် ပွဲစားထံရှိ လက်ကျန်ထက် များနေပါသည်။');
    }

    broker.soldQuantity = soldQuantity;
    broker.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await brokers.put(brokerId, broker);

    final currentUser = LocalDb.currentUser();
    final auditLog = AuditLog(
      id: genId(),
      action: 'BROKER_SOLD',
      userId: currentUser['id'] as String,
      userName: currentUser['name'] as String,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      details: 'Sold \${soldQuantity} units',
    );
    await createAuditLog(auditLog);
  }

  /// Update broker returned quantity
  static Future<void> updateBrokerReturnedQuantity(String brokerId, double returnedQuantity) async {
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    final gemstones = Hive.box<Gemstone>(gemstonesBox);
    final broker = brokers.get(brokerId);
    
    if (broker == null) throw Exception('Broker Consignment not found');
    if (returnedQuantity > broker.remainingQuantity) {
      throw Exception('ပြန်လည်လက်ခံသော အရေအတွက်သည် ပွဲစားထံရှိ လက်ကျန်ထက် များနေပါသည်။');
    }

    // Restore quantity to purchase based on original source type
    final purchase = gemstones.values.firstWhereOrNull(
      (g) => g.id == broker.purchaseId,
    );
    if (purchase != null) {
      // Check if this was a breakdown item consignment
      if (broker.historicalData.sourceType == 'breakdown_item') {
        final itemName = broker.historicalData.breakdownItemName ?? '';
        if (itemName.isNotEmpty && purchase.breakdownItems.containsKey(itemName)) {
          final oldQty = (purchase.breakdownItems[itemName]?['quantity'] as int?) ?? 0;
          purchase.breakdownItems[itemName] = {
            'quantity': oldQty + returnedQuantity.toInt(),
            'weight': purchase.breakdownItems[itemName]?['weight'],
            'weightUnit': purchase.breakdownItems[itemName]?['weightUnit']
          };
        }
      } else {
        // Restore to whole stone remaining quantity
        purchase.remainingQuantity += returnedQuantity.toInt();
      }
      await _updateGemstoneByPurchaseId(broker.purchaseId, purchase);
      // Recalculate ledger after inventory change
      await updateGemstoneProductLedger(broker.purchaseId);
    }

    broker.returnedQuantity = returnedQuantity;
    broker.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await brokers.put(brokerId, broker);

    final currentUser = LocalDb.currentUser();
    final auditLog = AuditLog(
      id: genId(),
      action: 'BROKER_RETURNED',
      userId: currentUser['id'] as String,
      userName: currentUser['name'] as String,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      details: 'Returned \${returnedQuantity} units',
    );
    await createAuditLog(auditLog);
  }

  /// Delete broker consignment and restore all quantities
  static Future<void> deleteBrokerConsignment(String brokerId) async {
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    final gemstones = Hive.box<Gemstone>(gemstonesBox);
    final broker = brokers.get(brokerId);
    
    if (broker == null) throw Exception('Broker Consignment not found');
    
    // Check if broker has sales
    if (broker.soldQuantity > 0) {
      throw Exception('ရောင်းထားသည့် အရေအတွက်ကြောင့် ဖျက်၍မရပါ။');
    }

    // PHASE 1: Restore quantities based on source type
    // CRITICAL: Only restore to the selected source record, never cross-reference
    final remainingToRestore = broker.consignedQuantity - broker.returnedQuantity;
    final purchase = gemstones.values.firstWhereOrNull(
      (g) => g.id == broker.purchaseId,
    );
    if (purchase != null) {
      // Check if this is a breakdown item consignment
      if (broker.historicalData.sourceType == 'breakdown_item') {
        // FRAGMENT PATH: Only restore to breakdown item, never touch whole stone
        final itemName = broker.historicalData.breakdownItemName ?? '';
        if (itemName.isNotEmpty && purchase.breakdownItems.containsKey(itemName)) {
          final oldQty = (purchase.breakdownItems[itemName]?['quantity'] as int?) ?? 0;
          purchase.breakdownItems[itemName] = {
            'quantity': oldQty + remainingToRestore.toInt(),
            'weight': purchase.breakdownItems[itemName]?['weight'],
            'weightUnit': purchase.breakdownItems[itemName]?['weightUnit']
          };
          // IMPORTANT: Do NOT modify purchase.remainingQuantity for fragments
        }
      } else {
        // WHOLE STONE PATH: Only restore to whole stone remaining quantity
        purchase.remainingQuantity += remainingToRestore.toInt();
        // IMPORTANT: Do NOT modify breakdown items for whole stone
      }
      
      // PHASE 2: Save only the modified source record
      await _updateGemstoneByPurchaseId(broker.purchaseId, purchase);
      
      // PHASE 3: Recalculate ledger ONLY for the selected source
      await updateGemstoneProductLedger(broker.purchaseId);
    }

    // Soft delete
    broker.deletedAt = DateTime.now().millisecondsSinceEpoch;
    await brokers.put(brokerId, broker);

    final currentUser = LocalDb.currentUser();
    final auditLog = AuditLog(
      id: genId(),
      action: 'DELETE_BROKER_CONSIGNMENT',
      userId: currentUser['id'] as String,
      userName: currentUser['name'] as String,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      details: 'Deleted and restored \${remainingToRestore} units',
    );
    await createAuditLog(auditLog);
  }

  /// Check if purchase can be edited (not linked to active broker consignments)
  static bool canEditPurchaseFields(String purchaseId) {
    final activeBrokers = getActiveBrokerConsignmentsForPurchase(purchaseId);
    return activeBrokers.isEmpty;
  }

  /// Check if breakdown item can be deleted (not linked to active broker consignments)
  static bool canDeleteBreakdownItem(String purchaseId, String breakdownItemName) {
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    final linkedBrokers = brokers.values.where((b) =>
      b.purchaseId == purchaseId &&
      b.historicalData.sourceType == 'breakdown_item' &&
      b.historicalData.breakdownItemName == breakdownItemName &&
      b.isActive
    ).toList();
    return linkedBrokers.isEmpty;
  }

  // -------------------------------------------------------------------------
  // Broker Consignment RBAC Permissions
  // -------------------------------------------------------------------------

  /// Broker Consignment ကို ဖန်တီးနိုင်သည်ကို စစ်ဆေးခြင်း (Admin-only)
  static bool canCreateBrokerConsignment() {
    if (isCurrentUserSuperAdmin()) return true;
    return isCurrentUserAdmin();
  }

  /// Broker Consignment ကို Edit နိုင်သည်ကို စစ်ဆေးခြင်း (Admin-only)
  static bool canEditBrokerConsignment() {
    if (isCurrentUserSuperAdmin()) return true;
    return isCurrentUserAdmin();
  }

  /// Broker Consignment ကို ဖျက်နိုင်သည်ကို စစ်ဆေးခြင်း (Admin-only)
  static bool canDeleteBrokerConsignment() {
    if (isCurrentUserSuperAdmin()) return true;
    return isCurrentUserAdmin();
  }

  /// Step 9: Process broker return - restore inventory
  static Future<void> recordBrokerSale({
    required String brokerConsignmentId,
    required double soldQuantity,
    double? saleAmount,
  }) async {
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    final gemstones = Hive.box<Gemstone>(gemstonesBox);

    // Get broker consignment
    final bc = brokers.values.firstWhere(
      (b) => b.id == brokerConsignmentId,
      orElse: () => throw Exception('Broker Consignment not found'),
    );

    // Validation: Sold + Returned must not exceed Consigned
    final totalUsed = soldQuantity + bc.returnedQuantity;
    if (totalUsed > bc.consignedQuantity) {
      throw Exception('ရောင်းချ + ပြန်လည်လက်ခံ သည် အပ်ထားအရေအတွက်ထက် မများရပါ။');
    }

    // Update broker consignment - increase soldQuantity
    bc.soldQuantity += soldQuantity;
    await brokers.put(brokerConsignmentId, bc);

    // Apply cost recovery if sale amount is provided
    String costRecoveryDetails = '';
    if (saleAmount != null && saleAmount > 0) {
      final purchase = gemstones.get(bc.purchaseId);
      if (purchase != null) {
        final previousRecoveredCost = purchase.recoveredCost;
        final previousProfit = purchase.totalProfit ?? 0;
        
        // Apply cost recovery engine
        applyCostRecovery(purchase, saleAmount);
        
        // Save updated purchase record
        await _updateGemstoneByPurchaseId(bc.purchaseId, purchase);
        // Recalculate ledger after cost recovery
        await updateGemstoneProductLedger(bc.purchaseId);
        
        // Calculate cost recovery details for audit log
        final costRecovered = purchase.recoveredCost - previousRecoveredCost;
        final profitGenerated = (purchase.totalProfit ?? 0) - previousProfit;
        costRecoveryDetails = ', Cost Recovered: ${costRecovered.toStringAsFixed(0)}, Profit: ${profitGenerated.toStringAsFixed(0)}';
      }
    }

    // Create audit log
    final currentUser = LocalDb.currentUser();
    final now = DateTime.now().millisecondsSinceEpoch;
    final auditLog = AuditLog(
      id: genId(),
      action: 'BROKER_CONSIGNMENT_SOLD',
      userId: currentUser['id'] as String,
      userName: currentUser['name'] as String,
      timestamp: now,
      details: 'Sold ${soldQuantity} from broker ${bc.brokerName}, Sale Amount: ${saleAmount?.toStringAsFixed(0) ?? "N/A"}$costRecoveryDetails',
    );
    await createAuditLog(auditLog);
  }

  static Future<void> processBrokerReturn({
    required String brokerConsignmentId,
    required double returnedQuantity,
  }) async {
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    final gemstones = Hive.box<Gemstone>(gemstonesBox);

    // Get broker consignment
    final bc = brokers.values.firstWhere(
      (b) => b.id == brokerConsignmentId,
      orElse: () => throw Exception('Broker Consignment not found'),
    );

    // Validate returned quantity
    if (returnedQuantity > bc.remainingQuantity) {
      throw Exception('ပြန်လည်လက်ခံသော အရေအတွက်သည် ပွဲစားထံရှိ လက်ကျန်ထက် မများရပါ။');
    }

    // Get purchase record
    final purchase = gemstones.values.firstWhere(
      (g) => g.id == bc.purchaseId,
      orElse: () => throw Exception('Purchase Record not found'),
    );

    // Step 9: Update broker consignment - increase returnedQuantity
    bc.returnedQuantity += returnedQuantity;
    // Use brokerConsignmentId directly as the Hive key
    await brokers.put(brokerConsignmentId, bc);

    // Step 9: Restore to purchase record based on original source type
    // Check if this was a breakdown item consignment
    if (bc.historicalData.sourceType == 'breakdown_item') {
      final itemName = bc.historicalData.breakdownItemName ?? '';
      if (itemName.isNotEmpty && purchase.breakdownItems.containsKey(itemName)) {
        final oldQty = (purchase.breakdownItems[itemName]?['quantity'] as int?) ?? 0;
        purchase.breakdownItems[itemName] = {
          'quantity': oldQty + returnedQuantity.toInt(),
          'weight': purchase.breakdownItems[itemName]?['weight'],
          'weightUnit': purchase.breakdownItems[itemName]?['weightUnit']
        };
      }
    } else {
      // Restore to whole stone remaining quantity
      purchase.remainingQuantity += returnedQuantity.toInt();
    }
    // Update the original Gemstone record using the helper method
    await _updateGemstoneByPurchaseId(bc.purchaseId, purchase);
    // Recalculate ledger after inventory change
    await updateGemstoneProductLedger(bc.purchaseId);

    // Create audit log
    final currentUser = LocalDb.currentUser();
    final now = DateTime.now().millisecondsSinceEpoch;
    final auditLog = AuditLog(
      id: genId(),
      action: 'BROKER_CONSIGNMENT_RETURNED',
      userId: currentUser['id'] as String,
      userName: currentUser['name'] as String,
      timestamp: now,
      details: 'Returned ${returnedQuantity} from broker ${bc.brokerName} to ${purchase.name}',
    );
    await createAuditLog(auditLog);
  }

  // ============================================================================
  // BROKER GROUPING HELPERS (Phase 1 - Presentation Layer)
  // ============================================================================

  /// Normalize broker name for comparison (trim, collapse spaces, lowercase)
  static String _normalizeBrokerName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  /// Normalize phone number for comparison (remove spaces, hyphens, parentheses)
  static String _normalizePhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]+'), '');
  }

  /// Create unique broker key from name and phone
  static String _createBrokerKey(String name, String phone) {
    final normalizedName = _normalizeBrokerName(name);
    final normalizedPhone = _normalizePhoneNumber(phone);
    return '$normalizedName|$normalizedPhone';
  }

  /// Group broker consignments by broker identity (name + phone)
  static Map<String, List<BrokerConsignment>> getGroupedBrokersByIdentity() {
    final brokers = Hive.box<BrokerConsignment>(brokerConsignmentsBox);
    final grouped = <String, List<BrokerConsignment>>{};

    for (final bc in brokers.values) {
      if (bc.deletedAt != null) continue; // Skip soft-deleted records

      final key = _createBrokerKey(bc.brokerName, bc.brokerPhone);
      grouped.putIfAbsent(key, () => []).add(bc);
    }

    return grouped;
  }

  /// Get broker summary stats for a broker group
  static Map<String, dynamic> getBrokerSummary(List<BrokerConsignment> brokerVouchers) {
    if (brokerVouchers.isEmpty) {
      return {
        'brokerName': '',
        'brokerPhone': '',
        'brokerAddress': '',
        'totalRemaining': 0.0,
        'activeCount': 0,
        'completedCount': 0,
        'latestDate': 0,
      };
    }

    // Use first voucher for broker details
    final first = brokerVouchers.first;

    // Calculate totals
    double totalRemaining = 0;
    int activeCount = 0;
    int completedCount = 0;
    int latestDate = 0;

    for (final bc in brokerVouchers) {
      totalRemaining += bc.remainingQuantity;
      if (bc.isCompleted) {
        completedCount++;
      } else {
        activeCount++;
      }
      if (bc.updatedAt > latestDate) {
        latestDate = bc.updatedAt;
      }
    }

    return {
      'brokerName': first.brokerName,
      'brokerPhone': first.brokerPhone,
      'brokerAddress': first.brokerAddress,
      'totalRemaining': totalRemaining,
      'activeCount': activeCount,
      'completedCount': completedCount,
      'latestDate': latestDate,
    };
  }

  /// Get active vouchers for a broker (remaining > 0)
  static List<BrokerConsignment> getActiveBrokerVouchers(
    List<BrokerConsignment> brokerVouchers,
  ) {
    final active = brokerVouchers
        .where((bc) => !bc.isCompleted && bc.deletedAt == null)
        .toList();
    // Sort by latest date descending
    active.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return active;
  }

  /// Get completed vouchers for a broker (remaining == 0)
  static List<BrokerConsignment> getCompletedBrokerVouchers(
    List<BrokerConsignment> brokerVouchers,
  ) {
    final completed = brokerVouchers
        .where((bc) => bc.isCompleted && bc.deletedAt == null)
        .toList();
    // Sort by latest date descending
    completed.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return completed;
  }

  /// Get sorted broker groups (active first, then by latest date)
  static List<MapEntry<String, List<BrokerConsignment>>> getSortedBrokerGroups() {
    final grouped = getGroupedBrokersByIdentity();
    final entries = grouped.entries.toList();

    entries.sort((a, b) {
      final summaryA = getBrokerSummary(a.value);
      final summaryB = getBrokerSummary(b.value);

      // Active brokers first
      final activeCountA = summaryA['activeCount'] as int;
      final activeCountB = summaryB['activeCount'] as int;

      if (activeCountA > 0 && activeCountB == 0) return -1;
      if (activeCountA == 0 && activeCountB > 0) return 1;

      // Then sort by latest date descending
      final latestA = summaryA['latestDate'] as int;
      final latestB = summaryB['latestDate'] as int;
      return latestB.compareTo(latestA);
    });

    return entries;
  }

  /// Group broker consignments by voucherNumber (for detail page active tab)
  static Map<String, List<BrokerConsignment>> groupBrokerConsignmentsByVoucher(
    List<BrokerConsignment> vouchers,
  ) {
    final grouped = <String, List<BrokerConsignment>>{};
    for (final bc in vouchers) {
      if (bc.isCompleted || bc.deletedAt != null) continue;
      final voucherNum = bc.voucherNumber ?? 'Unknown';
      grouped.putIfAbsent(voucherNum, () => []).add(bc);
    }
    return grouped;
  }

  /// Group broker sale records by voucherNumber (for detail page completed tab)
  static Map<String, List<BrokerSaleRecord>> groupBrokerSaleRecordsByVoucher(
    List<BrokerConsignment> completedVouchers,
  ) {
    final grouped = <String, List<BrokerSaleRecord>>{};
    final salesBox = brokerSaleRecords();

    for (final bc in completedVouchers) {
      if (!bc.isCompleted || bc.deletedAt != null) continue;
      final voucherNum = bc.voucherNumber ?? 'Unknown';

      final sales = salesBox.values
          .where((sale) => sale.brokerConsignmentId == bc.id)
          .toList();

      if (sales.isNotEmpty) {
        grouped.putIfAbsent(voucherNum, () => []).addAll(sales);
      }
    }
    return grouped;
  }

  /// Resolve gemstone name and details for a BrokerConsignment item
  /// Handles both whole_stone and breakdown_item source types
  /// Returns null if gemstone was deleted or sourceType is invalid
  static Map<String, dynamic>? resolveBrokerConsignmentGemstone(BrokerConsignment item) {
    try {
      // Get the parent gemstone
      final gemstone = gemstoneById(item.purchaseId);
      if (gemstone == null) return null;

      // Whole stone: return gemstone name directly
      if (item.sourceType == 'whole_stone') {
        return {
          'name': gemstone.name,
          'type': gemstone.type,
          'gemstone': gemstone,
          'isBreakdown': false,
        };
      }

      // Breakdown item: combine parent name + breakdown item name
      if (item.sourceType == 'breakdown_item' && item.breakdownItemName != null) {
        return {
          'name': '${gemstone.name} / ${item.breakdownItemName}',
          'type': gemstone.type,
          'gemstone': gemstone,
          'breakdownItemName': item.breakdownItemName,
          'isBreakdown': true,
        };
      }

      // Fallback: return parent gemstone if breakdown item name is missing
      return {
        'name': gemstone.name,
        'type': gemstone.type,
        'gemstone': gemstone,
        'isBreakdown': false,
      };
    } catch (e) {
      return null;
    }
  }
}

  // ---------------------------------------------------------------------------
  // Broker Profile Methods
  // ---------------------------------------------------------------------------

  /// Get all broker profiles (active and deleted)
  static List<BrokerProfile> brokerProfiles() {
    final box = Hive.box<BrokerProfile>(LocalDb.brokerProfilesBox);
    return box.values.toList();
  }

  /// Get only active (non-deleted) broker profiles
  static List<BrokerProfile> activeBrokerProfiles() {
    final box = Hive.box<BrokerProfile>(LocalDb.brokerProfilesBox);
    return box.values.where((broker) => !broker.isDeleted).toList();
  }

  /// Get broker profile by ID
  static BrokerProfile? brokerProfileById(String id) {
    final box = Hive.box<BrokerProfile>(LocalDb.brokerProfilesBox);
    return box.values.firstWhereOrNull((broker) => broker.id == id);
  }

  /// Save a new broker profile
  static Future<void> saveBrokerProfile(BrokerProfile broker) async {
    final box = Hive.box<BrokerProfile>(LocalDb.brokerProfilesBox);
    await box.put(broker.id, broker);
  }

  /// Update an existing broker profile
  static Future<void> updateBrokerProfile(BrokerProfile broker) async {
    final box = Hive.box<BrokerProfile>(LocalDb.brokerProfilesBox);
    await box.put(broker.id, broker);
  }

  /// Soft delete a broker profile (mark as deleted, don't remove)
  static Future<void> softDeleteBrokerProfile(String id) async {
    final box = Hive.box<BrokerProfile>(LocalDb.brokerProfilesBox);
    final broker = box.get(id);
    if (broker != null) {
      broker.isDeleted = true;
      broker.deletedAt = DateTime.now().millisecondsSinceEpoch;
      await box.put(id, broker);
    }
  }

  /// Search broker profiles by name or phone (case-insensitive)
  /// Empty query returns all active brokers
  static List<BrokerProfile> searchBrokerProfiles(String query) {
    final box = Hive.box<BrokerProfile>(LocalDb.brokerProfilesBox);
    final activeProfiles = box.values.where((broker) => !broker.isDeleted).toList();

    if (query.isEmpty) {
      return activeProfiles;
    }

    final lowerQuery = query.toLowerCase();
    return activeProfiles.where((broker) {
      final nameMatch = broker.name.toLowerCase().contains(lowerQuery);
      final phoneMatch = broker.phone.contains(lowerQuery);
      return nameMatch || phoneMatch;
    }).toList();
  }
