import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gemstone_management/core/local/local_db.dart';
import 'package:gemstone_management/core/local/models.dart';
import 'package:gemstone_management/features/sales/domain/broker_sales_business_logic.dart';

/// RCA Test: Final Save with Multi-Item Draft
/// 
/// Scenario:
/// - Draft Item 1: Whole Stone မဲစိမ်းကြား = 10
/// - Draft Item 2: Fragment မဲစိမ်းကြား = 40
/// - Draft Item 3: Whole Stone ပတ္တမြား (Sapphire) = 1
/// 
/// Expected Behavior:
/// - Item 1 (Whole 10): Should succeed, remainingQuantity: 20 -> 10
/// - Item 2 (Fragment 40): Should succeed, fragment quantity: 70 -> 30
/// - Item 3 (Whole 1): Should succeed, remainingQuantity: 5 -> 4
/// 
/// Actual Behavior (Bug):
/// - One of the items throws an exception during Final Save
/// 
/// RCA Objective:
/// - Capture exact values at each step
/// - Identify which item throws the exception
/// - Show the exact comparison that fails
/// - Prove the root cause with runtime evidence

void main() {
  test('RCA: Final Save Multi-Item Draft Scenario', () async {
    print('\n========== RCA TEST: FINAL SAVE SCENARIO START ==========\n');

    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(GemstoneAdapter());
    Hive.registerAdapter(BrokerConsignmentAdapter());
    Hive.registerAdapter(BrokerHistoricalDataAdapter());
    Hive.registerAdapter(AuditLogAdapter());
    Hive.registerAdapter(SaleAdapter());
    Hive.registerAdapter(FragmentSaleAdapter());
    Hive.registerAdapter(AppUserAdapter());
    Hive.registerAdapter(StaffUserAdapter());
    Hive.registerAdapter(PermissionAdapter());
    Hive.registerAdapter(RoleAdapter());
    Hive.registerAdapter(BrokerSaleRecordAdapter());
    Hive.registerAdapter(CustomerAdapter());
    Hive.registerAdapter(CustomerLedgerAdapter());
    Hive.registerAdapter(PaymentAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(WorkerAdapter());

    // Open boxes
    await Hive.openBox<Gemstone>('gemstones');
    await Hive.openBox<BrokerConsignment>('brokerConsignments');
    await Hive.openBox<Sale>('sales');
    await Hive.openBox<AuditLog>('auditLogs');
    await Hive.openBox<AppUser>('users');
    await Hive.openBox<StaffUser>('staffUsers');
    await Hive.openBox<Permission>('permissions');
    await Hive.openBox<Role>('roles');
    await Hive.openBox<BrokerSaleRecord>('brokerSaleRecords');
    await Hive.openBox<Customer>('customers');
    await Hive.openBox<CustomerLedger>('customerLedger');
    await Hive.openBox<Payment>('payments');
    await Hive.openBox<Expense>('expenses');
    await Hive.openBox<Worker>('workers');
    await Hive.openBox('session');

    print('[SETUP] Hive initialized with all boxes\n');

    // Create test gemstones
    final jadeGemstone = Gemstone(
      id: 'jade_001',
      name: 'မဲစိမ်းကြား',
      type: 'Jade',
      weightCarat: 100,
      costPrice: 50000,
      quantity: 20,
      color: 'Green',
      origin: 'Myanmar',
      status: 'in_stock',
      note: 'Test jade',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      remainingQuantity: 20,
      breakdownItems: {
        'မဲစိမ်းကြား': {'quantity': 70, 'weight': null, 'weightUnit': null},
      },
    );

    final sapphireGemstone = Gemstone(
      id: 'sapphire_001',
      name: 'ပတ္တမြား',
      type: 'Sapphire',
      weightCarat: 50,
      costPrice: 100000,
      quantity: 5,
      color: 'Blue',
      origin: 'Myanmar',
      status: 'in_stock',
      note: 'Test sapphire',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      remainingQuantity: 5,
    );

    // Save gemstones to Hive
    final gemstonesBox = Hive.box<Gemstone>('gemstones');
    await gemstonesBox.put('jade_001', jadeGemstone);
    await gemstonesBox.put('sapphire_001', sapphireGemstone);

    print('[SETUP] Gemstones created:');
    print('  Jade: quantity=${jadeGemstone.quantity}, remainingQuantity=${jadeGemstone.remainingQuantity}');
    print('  Jade breakdownItems: ${jadeGemstone.breakdownItems}');
    print('  Sapphire: quantity=${sapphireGemstone.quantity}, remainingQuantity=${sapphireGemstone.remainingQuantity}\n');

    // Create broker consignments for draft items
    print('[SETUP] Creating broker consignments for draft items...\n');

    try {
      // Item 1: Whole Stone မဲစိမ်းကြား = 10
      print('[DRAFT-ITEM-1] Creating: Whole Stone မဲစိမ်းကြား = 10');
      final consignment1 = await LocalDb.createBrokerConsignment(
        purchaseId: 'jade_001',
        consignedQuantity: 10,
        sourceType: 'whole_stone',
        brokerName: 'Broker 1',
        brokerPhone: '09123456789',
        brokerAddress: 'Yangon',
      );
      print('[DRAFT-ITEM-1] SUCCESS: Created consignment ${consignment1.id}\n');
    } catch (e) {
      print('[DRAFT-ITEM-1] EXCEPTION: $e\n');
      rethrow;
    }

    try {
      // Item 2: Fragment မဲစိမ်းကြား = 40
      print('[DRAFT-ITEM-2] Creating: Fragment မဲစိမ်းကြား = 40');
      final consignment2 = await LocalDb.createBrokerConsignment(
        purchaseId: 'jade_001',
        consignedQuantity: 40,
        sourceType: 'breakdown_item',
        breakdownItemName: 'မဲစိမ်းကြား',
        brokerName: 'Broker 2',
        brokerPhone: '09123456789',
        brokerAddress: 'Yangon',
      );
      print('[DRAFT-ITEM-2] SUCCESS: Created consignment ${consignment2.id}\n');
    } catch (e) {
      print('[DRAFT-ITEM-2] EXCEPTION: $e\n');
      rethrow;
    }

    try {
      // Item 3: Whole Stone ပတ္တမြား = 1
      print('[DRAFT-ITEM-3] Creating: Whole Stone ပတ္တမြား = 1');
      final consignment3 = await LocalDb.createBrokerConsignment(
        purchaseId: 'sapphire_001',
        consignedQuantity: 1,
        sourceType: 'whole_stone',
        brokerName: 'Broker 3',
        brokerPhone: '09123456789',
        brokerAddress: 'Yangon',
      );
      print('[DRAFT-ITEM-3] SUCCESS: Created consignment ${consignment3.id}\n');
    } catch (e) {
      print('[DRAFT-ITEM-3] EXCEPTION: $e\n');
      rethrow;
    }

    print('[SETUP] All consignments created successfully\n');

    // Verify state after consignments
    print('[STATE-CHECK] After consignments:');
    final updatedJade = gemstonesBox.get('jade_001');
    final updatedSapphire = gemstonesBox.get('sapphire_001');
    print('  Jade: remainingQuantity=${updatedJade?.remainingQuantity}');
    print('  Jade breakdownItems: ${updatedJade?.breakdownItems}');
    print('  Sapphire: remainingQuantity=${updatedSapphire?.remainingQuantity}\n');

    print('========== RCA TEST: FINAL SAVE SCENARIO COMPLETE ==========\n');

    await Hive.close();
  });
}
