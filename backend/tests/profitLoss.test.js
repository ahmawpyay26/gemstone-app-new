const LotPurchaseService = require('../services/lotPurchase.service');
const LotSplittingService = require('../services/lotSplitting.service');
const WasteStoneService = require('../services/wasteStone.service');
const ExpenseAllocationService = require('../services/expenseAllocation.service');
const ProfitLossService = require('../services/profitLoss.service');
const FinancialValidationService = require('../services/financialValidation.service');

/**
 * Test Scenario 1: Complete Lot Purchase and Sale Workflow
 */
async function testCompleteLotWorkflow() {
  console.log('\n=== TEST 1: Complete Lot Purchase and Sale Workflow ===\n');

  try {
    // 1. Create lot purchase
    console.log('1. Creating lot purchase...');
    const lot = await LotPurchaseService.createLotPurchase({
      purchaseDate: new Date('2026-05-01'),
      supplierId: 'supplier-001',
      supplierName: 'Myanmar Gems Ltd',
      lotNumber: 'LOT-2026-001',
      totalStones: 10,
      totalCarats: 150,
      totalCost: 45000,
      notes: 'High quality rubies from Mogok'
    });
    console.log('✓ Lot created:', lot);

    // 2. Add stones to lot
    console.log('\n2. Adding stones to lot...');
    const stones = await LotPurchaseService.addStonesToLot(lot.id, [
      { carat_weight: 15, type: 'Ruby', color: 'Red', clarity: 'VS' },
      { carat_weight: 14, type: 'Ruby', color: 'Red', clarity: 'VS' },
      { carat_weight: 16, type: 'Ruby', color: 'Red', clarity: 'VVS' },
      { carat_weight: 15, type: 'Ruby', color: 'Red', clarity: 'VS' },
      { carat_weight: 17, type: 'Ruby', color: 'Red', clarity: 'VVS' },
      { carat_weight: 14, type: 'Ruby', color: 'Red', clarity: 'VS' },
      { carat_weight: 16, type: 'Ruby', color: 'Red', clarity: 'VS' },
      { carat_weight: 15, type: 'Ruby', color: 'Red', clarity: 'VS' },
      { carat_weight: 18, type: 'Ruby', color: 'Red', clarity: 'VVS' },
      { carat_weight: 14, type: 'Ruby', color: 'Red', clarity: 'VS' }
    ]);
    console.log(`✓ Added ${stones.length} stones to lot`);
    console.log('Sample stone:', stones[0]);

    // 3. Create sale
    console.log('\n3. Creating sale...');
    const sale = await ProfitLossService.createSale({
      saleDate: new Date('2026-05-15'),
      branchId: 'branch-001',
      buyerName: 'Luxury Jewels Inc',
      buyerType: 'WHOLESALE',
      totalStones: 8,
      totalCarats: 120,
      totalSalePrice: 72000,
      brokerCommissionPercentage: 2
    });
    console.log('✓ Sale created:', sale);

    // 4. Add sale items
    console.log('\n4. Adding items to sale...');
    for (let i = 0; i < 8; i++) {
      await ProfitLossService.addSaleItem(sale.id, {
        gemstoneId: stones[i].id,
        caratWeight: stones[i].caratWeight,
        salePrice: stones[i].caratWeight * 600,
        costBasis: stones[i].costBasis
      });
    }
    console.log('✓ Added 8 items to sale');

    // 5. Calculate profit
    console.log('\n5. Calculating sale profit...');
    const profit = await ProfitLossService.calculateSaleProfit(sale.id);
    console.log('✓ Sale profit calculated:');
    console.log(`  Total Sale Price: ${profit.totalSalePrice}`);
    console.log(`  Total Cost: ${profit.totalCost}`);
    console.log(`  Total Profit: ${profit.totalProfit}`);
    console.log(`  Profit Margin: ${profit.profitMarginPercentage.toFixed(2)}%`);

    // 6. Calculate lot profit
    console.log('\n6. Calculating lot profit...');
    const lotProfit = await ProfitLossService.calculateLotProfit(lot.id);
    console.log('✓ Lot profit calculated:');
    console.log(`  Total Purchase Cost: ${lotProfit.totalPurchaseCost}`);
    console.log(`  Total Sale Price: ${lotProfit.totalSalePrice}`);
    console.log(`  Total Profit: ${lotProfit.totalProfit}`);
    console.log(`  Inventory Carats: ${lotProfit.inventoryCarats}`);

    console.log('\n✓ TEST 1 PASSED\n');
    return true;
  } catch (error) {
    console.error('✗ TEST 1 FAILED:', error.message);
    return false;
  }
}

/**
 * Test Scenario 2: Lot Splitting with Cost Basis Tracking
 */
async function testLotSplitting() {
  console.log('\n=== TEST 2: Lot Splitting with Cost Basis Tracking ===\n');

  try {
    // 1. Create lot
    console.log('1. Creating lot for splitting...');
    const lot = await LotPurchaseService.createLotPurchase({
      purchaseDate: new Date('2026-05-01'),
      supplierId: 'supplier-002',
      supplierName: 'Jade Imports',
      lotNumber: 'LOT-2026-002',
      totalStones: 5,
      totalCarats: 100,
      totalCost: 20000
    });

    const stones = await LotPurchaseService.addStonesToLot(lot.id, [
      { carat_weight: 20, type: 'Jade', color: 'Green', clarity: 'VS' },
      { carat_weight: 20, type: 'Jade', color: 'Green', clarity: 'VS' },
      { carat_weight: 20, type: 'Jade', color: 'Green', clarity: 'VS' },
      { carat_weight: 20, type: 'Jade', color: 'Green', clarity: 'VS' },
      { carat_weight: 20, type: 'Jade', color: 'Green', clarity: 'VS' }
    ]);
    console.log('✓ Lot created with 5 stones');

    // 2. Split first stone
    console.log('\n2. Splitting first stone into 3 pieces...');
    const split = await LotSplittingService.splitStone(stones[0].id, {
      splitReason: 'Customer request for smaller stones',
      resultingStones: [
        { caratWeight: 8, name: 'Piece 1', type: 'Jade', color: 'Green', clarity: 'VS' },
        { caratWeight: 7, name: 'Piece 2', type: 'Jade', color: 'Green', clarity: 'VS' },
        { caratWeight: 3, name: 'Piece 3', type: 'Jade', color: 'Green', clarity: 'VS' }
      ],
      allocationMethod: 'EQUAL_WEIGHT'
    });
    console.log('✓ Stone split successfully');
    console.log(`  Original: ${split.originalCarats} carats, cost: ${split.originalCost}`);
    console.log(`  Resulting: ${split.resultingStones.length} stones`);
    console.log(`  Waste: ${split.wasteCarats} carats, cost: ${split.wasteCost}`);

    // 3. Get split lineage
    console.log('\n3. Getting split lineage...');
    const lineage = await LotSplittingService.getSplitLineage(stones[0].id);
    console.log('✓ Split lineage retrieved');

    console.log('\n✓ TEST 2 PASSED\n');
    return true;
  } catch (error) {
    console.error('✗ TEST 2 FAILED:', error.message);
    return false;
  }
}

/**
 * Test Scenario 3: Waste Stone Handling
 */
async function testWasteHandling() {
  console.log('\n=== TEST 3: Waste Stone Handling ===\n');

  try {
    // 1. Create lot
    console.log('1. Creating lot for waste testing...');
    const lot = await LotPurchaseService.createLotPurchase({
      purchaseDate: new Date('2026-05-01'),
      supplierId: 'supplier-003',
      supplierName: 'Sapphire Co',
      lotNumber: 'LOT-2026-003',
      totalStones: 3,
      totalCarats: 60,
      totalCost: 18000
    });

    const stones = await LotPurchaseService.addStonesToLot(lot.id, [
      { carat_weight: 20, type: 'Sapphire', color: 'Blue', clarity: 'VS' },
      { carat_weight: 20, type: 'Sapphire', color: 'Blue', clarity: 'VS' },
      { carat_weight: 20, type: 'Sapphire', color: 'Blue', clarity: 'VS' }
    ]);
    console.log('✓ Lot created with 3 stones');

    // 2. Mark stone as waste
    console.log('\n2. Marking stone as waste...');
    const waste = await WasteStoneService.markAsWaste(stones[0].id, {
      wasteReason: 'Internal fracture discovered during inspection',
      scrapValue: 500
    });
    console.log('✓ Stone marked as waste');
    console.log(`  Waste Cost: ${waste.wasteCost}`);
    console.log(`  Scrap Value: ${waste.scrapValue}`);

    // 3. Get waste summary
    console.log('\n3. Getting waste summary for lot...');
    const wasteSummary = await WasteStoneService.getLotWasteSummary(lot.id);
    console.log('✓ Waste summary retrieved');
    console.log(`  Waste Count: ${wasteSummary.waste_count}`);
    console.log(`  Total Waste Carats: ${wasteSummary.total_waste_carats}`);
    console.log(`  Total Waste Cost: ${wasteSummary.total_waste_cost}`);

    // 4. Calculate waste impact
    console.log('\n4. Calculating waste impact...');
    const impact = await WasteStoneService.calculateWasteImpact(lot.id);
    console.log('✓ Waste impact calculated');
    console.log(`  Waste Percentage: ${impact.wastePercentage.toFixed(2)}%`);
    console.log(`  Waste Impact on Cost: ${impact.wasteImpact.toFixed(2)}%`);

    console.log('\n✓ TEST 3 PASSED\n');
    return true;
  } catch (error) {
    console.error('✗ TEST 3 FAILED:', error.message);
    return false;
  }
}

/**
 * Test Scenario 4: Expense Allocation
 */
async function testExpenseAllocation() {
  console.log('\n=== TEST 4: Expense Allocation ===\n');

  try {
    // 1. Create lot and sale
    console.log('1. Setting up lot and sale...');
    const lot = await LotPurchaseService.createLotPurchase({
      purchaseDate: new Date('2026-05-01'),
      supplierId: 'supplier-004',
      supplierName: 'Diamond Traders',
      lotNumber: 'LOT-2026-004',
      totalStones: 5,
      totalCarats: 50,
      totalCost: 50000
    });

    const stones = await LotPurchaseService.addStonesToLot(lot.id, [
      { carat_weight: 10, type: 'Diamond', color: 'D', clarity: 'IF' },
      { carat_weight: 10, type: 'Diamond', color: 'D', clarity: 'IF' },
      { carat_weight: 10, type: 'Diamond', color: 'D', clarity: 'IF' },
      { carat_weight: 10, type: 'Diamond', color: 'D', clarity: 'IF' },
      { carat_weight: 10, type: 'Diamond', color: 'D', clarity: 'IF' }
    ]);
    console.log('✓ Lot created with 5 stones');

    // 2. Create expenses
    console.log('\n2. Creating expenses...');
    const workerExpense = await ExpenseAllocationService.createExpense({
      expenseDate: new Date('2026-05-05'),
      branchId: 'branch-001',
      category: 'WORKER',
      description: 'Stone cutting and polishing',
      amount: 5000,
      allocationMethod: 'EQUAL_WEIGHT',
      relatedLotId: lot.id
    });
    console.log('✓ Worker expense created: 5000');

    const toolExpense = await ExpenseAllocationService.createExpense({
      expenseDate: new Date('2026-05-05'),
      branchId: 'branch-001',
      category: 'TOOLS',
      description: 'Tool maintenance',
      amount: 1000,
      allocationMethod: 'EQUAL_STONES',
      relatedLotId: lot.id
    });
    console.log('✓ Tool expense created: 1000');

    // 3. Allocate expenses
    console.log('\n3. Allocating expenses to stones...');
    const workerAllocation = await ExpenseAllocationService.allocateExpenseToStones(
      workerExpense.id,
      {
        allocationMethod: 'EQUAL_WEIGHT',
        targetStones: stones.map(s => s.id)
      }
    );
    console.log('✓ Worker expense allocated');
    console.log(`  Allocated to ${workerAllocation.allocatedStones} stones`);
    console.log(`  Total allocated: ${workerAllocation.totalAllocated}`);

    // 4. Get expense summary
    console.log('\n4. Getting expense summary...');
    const expenseSummary = await ExpenseAllocationService.getExpenseSummaryByCategory(
      new Date('2026-05-01'),
      new Date('2026-05-31'),
      'branch-001'
    );
    console.log('✓ Expense summary retrieved');
    expenseSummary.forEach(cat => {
      console.log(`  ${cat.category}: ${cat.expense_count} expenses, Total: ${cat.total_amount}`);
    });

    console.log('\n✓ TEST 4 PASSED\n');
    return true;
  } catch (error) {
    console.error('✗ TEST 4 FAILED:', error.message);
    return false;
  }
}

/**
 * Test Scenario 5: Financial Validation and Reconciliation
 */
async function testFinancialValidation() {
  console.log('\n=== TEST 5: Financial Validation and Reconciliation ===\n');

  try {
    // 1. Perform reconciliation
    console.log('1. Performing financial reconciliation...');
    const reconciliation = await FinancialValidationService.performReconciliation('branch-001');
    console.log('✓ Reconciliation completed');
    console.log(`  Status: ${reconciliation.validationStatus}`);
    console.log(`  Errors: ${reconciliation.errors.length}`);
    console.log(`  Warnings: ${reconciliation.warnings.length}`);

    if (reconciliation.errors.length > 0) {
      console.log('  Errors:');
      reconciliation.errors.forEach(err => console.log(`    - ${err}`));
    }

    if (reconciliation.warnings.length > 0) {
      console.log('  Warnings:');
      reconciliation.warnings.forEach(warn => console.log(`    - ${warn}`));
    }

    // 2. Check financial anomalies
    console.log('\n2. Checking for financial anomalies...');
    const anomalies = await FinancialValidationService.checkFinancialAnomalies('branch-001');
    console.log('✓ Anomaly check completed');
    console.log(`  Found ${anomalies.length} anomalies`);
    anomalies.forEach(anom => {
      console.log(`  - ${anom.type}: ${anom.count} cases`);
    });

    // 3. Get reconciliation history
    console.log('\n3. Getting reconciliation history...');
    const history = await FinancialValidationService.getReconciliationHistory('branch-001', 5);
    console.log(`✓ Retrieved ${history.length} reconciliation records`);

    console.log('\n✓ TEST 5 PASSED\n');
    return true;
  } catch (error) {
    console.error('✗ TEST 5 FAILED:', error.message);
    return false;
  }
}

/**
 * Run all tests
 */
async function runAllTests() {
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║   Gemstone Profit & Loss Calculation Engine - Test Suite       ║');
  console.log('╚════════════════════════════════════════════════════════════════╝');

  const results = [];

  results.push(await testCompleteLotWorkflow());
  results.push(await testLotSplitting());
  results.push(await testWasteHandling());
  results.push(await testExpenseAllocation());
  results.push(await testFinancialValidation());

  // Summary
  console.log('\n╔════════════════════════════════════════════════════════════════╗');
  console.log('║                        TEST SUMMARY                            ║');
  console.log('╚════════════════════════════════════════════════════════════════╝');
  const passed = results.filter(r => r).length;
  const total = results.length;
  console.log(`\nTotal Tests: ${total}`);
  console.log(`Passed: ${passed}`);
  console.log(`Failed: ${total - passed}`);
  console.log(`Success Rate: ${((passed / total) * 100).toFixed(2)}%\n`);

  return passed === total;
}

// Export for use in other test runners
module.exports = {
  testCompleteLotWorkflow,
  testLotSplitting,
  testWasteHandling,
  testExpenseAllocation,
  testFinancialValidation,
  runAllTests
};

// Run tests if executed directly
if (require.main === module) {
  runAllTests().then(success => {
    process.exit(success ? 0 : 1);
  });
}
