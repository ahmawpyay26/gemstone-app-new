import 'dart:developer' as developer;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gemstone_management/core/local/local_db.dart';
import 'package:gemstone_management/core/local/models.dart';

/// Test script to reproduce the exact screenshot scenario and capture logs
/// 
/// Scenario:
/// - Draft Item 1: မဲစိမ်းကြား Whole = 9
/// - Draft Item 2: မဲစိမ်းကြား Fragment = 40
/// - Draft Item 3: ပတ္တမြား Whole = 2

void main() async {
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(GemstoneAdapter());
  Hive.registerAdapter(BrokerConsignmentAdapter());
  Hive.registerAdapter(BrokerHistoricalDataAdapter());
  Hive.registerAdapter(AuditLogAdapter());
  Hive.registerAdapter(SaleAdapter());
  Hive.registerAdapter(FragmentSaleAdapter());
  
  // Open boxes
  await Hive.openBox<Gemstone>('gemstones');
  await Hive.openBox<BrokerConsignment>('brokerConsignments');
  
  print('\n========== RCA TEST SCENARIO START ==========\n');
  
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
  
  final rubyGemstone = Gemstone(
    id: 'ruby_001',
    name: 'ပတ္တမြား',
    type: 'Ruby',
    weightCarat: 50,
    costPrice: 100000,
    quantity: 5,
    color: 'Red',
    origin: 'Myanmar',
    status: 'in_stock',
    note: 'Test ruby',
    createdAt: DateTime.now().millisecondsSinceEpoch,
    remainingQuantity: 5,
  );
  
  // Save gemstones to Hive
  final gemstonesBox = Hive.box<Gemstone>('gemstones');
  await gemstonesBox.put('jade_001', jadeGemstone);
  await gemstonesBox.put('ruby_001', rubyGemstone);
  
  print('[TEST] Initial state:');
  print('  Jade: quantity=${jadeGemstone.quantity}, remainingQuantity=${jadeGemstone.remainingQuantity}');
  print('  Jade breakdownItems: ${jadeGemstone.breakdownItems}');
  print('  Ruby: quantity=${rubyGemstone.quantity}, remainingQuantity=${rubyGemstone.remainingQuantity}\n');
  
  // Simulate the save loop
  print('[TEST] Starting save loop simulation...\n');
  
  try {
    // Item 1: Whole မဲစိမ်းကြား = 9
    print('[TEST] Item 1: Whole မဲစိမ်းကြား = 9');
    await LocalDb.createBrokerConsignment(
      purchaseId: 'jade_001',
      consignedQuantity: 9,
      sourceType: 'whole_stone',
      brokerName: 'Test Broker 1',
      brokerPhone: '09123456789',
      brokerAddress: 'Yangon',
    );
    print('[TEST] Item 1: SUCCESS\n');
  } catch (e) {
    print('[TEST] Item 1: EXCEPTION - $e\n');
  }
  
  try {
    // Item 2: Fragment မဲစိမ်းကြား = 40
    print('[TEST] Item 2: Fragment မဲစိမ်းကြား = 40');
    await LocalDb.createBrokerConsignment(
      purchaseId: 'jade_001',
      consignedQuantity: 40,
      sourceType: 'breakdown_item',
      breakdownItemName: 'မဲစိမ်းကြား',
      brokerName: 'Test Broker 2',
      brokerPhone: '09123456789',
      brokerAddress: 'Yangon',
    );
    print('[TEST] Item 2: SUCCESS\n');
  } catch (e) {
    print('[TEST] Item 2: EXCEPTION - $e\n');
  }
  
  try {
    // Item 3: Whole ပတ္တမြား = 2
    print('[TEST] Item 3: Whole ပတ္တမြား = 2');
    await LocalDb.createBrokerConsignment(
      purchaseId: 'ruby_001',
      consignedQuantity: 2,
      sourceType: 'whole_stone',
      brokerName: 'Test Broker 3',
      brokerPhone: '09123456789',
      brokerAddress: 'Yangon',
    );
    print('[TEST] Item 3: SUCCESS\n');
  } catch (e) {
    print('[TEST] Item 3: EXCEPTION - $e\n');
  }
  
  print('[TEST] Final state:');
  final updatedJade = gemstonesBox.get('jade_001');
  final updatedRuby = gemstonesBox.get('ruby_001');
  print('  Jade: remainingQuantity=${updatedJade?.remainingQuantity}');
  print('  Jade breakdownItems: ${updatedJade?.breakdownItems}');
  print('  Ruby: remainingQuantity=${updatedRuby?.remainingQuantity}\n');
  
  print('========== RCA TEST SCENARIO END ==========\n');
  
  await Hive.close();
}
