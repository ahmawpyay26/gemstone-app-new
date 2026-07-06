import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../../../shared/widgets/photo_attachment_widget.dart';
import '../../../../shared/widgets/photo_viewer.dart';


extension DateTimeExtension on DateTime {
  DateTime toDateOnly() => DateTime(year, month, day);
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _money = NumberFormat('#,##0', 'en_US');
  final _date = DateFormat('dd/MM/yyyy');
  String _selectedPeriod = 'all'; // all, daily, weekly, monthly, yearly
  final Set<String> _expandedBreakdowns = {}; // Track which breakdown sections are expanded

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  /// Get start date based on selected period
  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'daily':
        return DateTime(now.year, now.month, now.day);
      case 'weekly':
        final daysToSubtract = now.weekday - 1; // Monday = 1
        return now.subtract(Duration(days: daysToSubtract)).toDateOnly();
      case 'monthly':
        return DateTime(now.year, now.month, 1);
      case 'yearly':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(1970); // all time
    }
  }

  /// Filter gemstones by period
  List<Gemstone> _filterGemstonesByPeriod(List<Gemstone> gemstones) {
    if (_selectedPeriod == 'all') return gemstones;
    final startDate = _getStartDate();
    return gemstones.where((g) {
      final createdDate =
          DateTime.fromMillisecondsSinceEpoch(g.createdAt).toDateOnly();
      return createdDate.isAtSameMomentAs(startDate) ||
          createdDate.isAfter(startDate);
    }).toList();
  }

  /// Calculate total stone count for filtered period
  int _calculateTotalStoneCount(List<Gemstone> gemstones) {
    int total = 0;
    for (final g in gemstones) {
      total += g.quantity;
    }
    return total;
  }

  /// Calculate total remaining stock for filtered period
  int _calculateTotalRemainingStock(List<Gemstone> gemstones) {
    int total = 0;
    for (final g in gemstones) {
      total += LocalDb.gemstoneRemainingQuantity(g);
    }
    return total;
  }

  /// Get total stone count (reusable from LocalDb)
  int _getTotalStoneCount() => LocalDb.totalStoneCount();

  /// Get remaining stone count (reusable from LocalDb)
  int _getRemainingStoneCount() => LocalDb.remainingStoneCount();

  void _openForm({Gemstone? existing, dynamic key}) {
    // Check edit permission
    if (existing != null && !LocalDb.canEditPurchase()) {
      _showError(LocalDb.adminOnlyErrorMessage());
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GemstoneForm(existing: existing, hiveKey: key),
    );
  }

  void _showPhotoViewer(Gemstone gemstone) {
    if (gemstone.photoPaths.isEmpty) {
      _showError('ဤမှတ်တမ်းတွင် ဓာတ်ပုံမရှိသေးပါ။');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewer(photoUrls: gemstone.photoPaths),
      ),
    );
  }

  Future<void> _delete(dynamic key) async {
    // Check admin permission
    if (!LocalDb.canDeletePurchase()) {
      _showError(LocalDb.adminOnlyErrorMessage());
      return;
    }

    final gemstone = LocalDb.gemstones().get(key);
    if (gemstone == null) return;

    final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('ဝယ်ယူမှတ်တမ်း ဖျက်မည်'),
            content: const Text(
                'ဤဝယ်ယူမှတ်တမ်းကို ဖျက်မှာ သေချာပါသလား?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('မဖျက်တော့ပါ')),
              TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('ဖျက်မည်',
                      style: TextStyle(color: AppTheme.errorColor))),
            ],
          ),
        ) ??
        false;

    if (ok) {
      try {
        await LocalDb.deletePurchaseRecord(
          gemstone.id,
          key,
          gemstone.name,
          gemstone.quantity,
        );
        _showSuccess('ဝယ်ယူမှတ်တမ်း အောင်မြင်စွာ ဖျက်ပြီးပါပြီ။');
      } catch (e) {
        _showError('အမှားအယွင်းတစ်ခု ကျေးဇူးပြု၍ ထပ်မံကြိုးစားပါ');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _confirm(String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('အတည်ပြုရန်'),
            content: Text(msg),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('မလုပ်တော့ပါ')),
              TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('ဖျက်မည်',
                      style: TextStyle(color: AppTheme.errorColor))),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('အဝယ် စာရင်းများ'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/dashboard')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('အသစ်ထည့်ရန်'),
        onPressed: () => _openForm(),
      ),
      body: Column(
        children: [
          // Summary Filter Section
          Container(
            color: AppTheme.surfaceDark,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ပစ္စည်းစာရင်းအချုပ် အလျင်းအလျ',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodButton('အားလုံး', 'all'),
                      const SizedBox(width: 8),
                      _buildPeriodButton('တစ်ရက်ချုပ်', 'daily'),
                      const SizedBox(width: 8),
                      _buildPeriodButton('တစ်ပတ်ချုပ်', 'weekly'),
                      const SizedBox(width: 8),
                      _buildPeriodButton('တစ်လချုပ်', 'monthly'),
                      const SizedBox(width: 8),
                      _buildPeriodButton('တစ်နှစ်ချုပ်', 'yearly'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Summary Statistics
          ValueListenableBuilder(
            valueListenable: LocalDb.sales().listenable(),
            builder: (context, _, __) => ValueListenableBuilder(
              valueListenable: LocalDb.gemstones().listenable(),
              builder: (context, Box<Gemstone> box, _) {
                final totalStones = _getTotalStoneCount();
                final totalRemaining = _getRemainingStoneCount();
                return Container(
                color: AppTheme.surfaceLight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ကျောက်အလုံးရေ စုစုပေါင်း',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11),
                          ),
                          Text(
                            '$totalStones အလုံး',
                            style: const TextStyle(
                              color: AppTheme.primaryAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'လက်ကျန်စုစုပေါင်း အလုံး',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11),
                          ),
                          Text(
                            '$totalRemaining အလုံး',
                            style: const TextStyle(
                              color: Colors.lightGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
              },
            ),
          ),
          // Gemstone List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: LocalDb.sales().listenable(),
              builder: (context, _, __) => ValueListenableBuilder(
                valueListenable: LocalDb.gemstones().listenable(),
                builder: (context, Box<Gemstone> box, _) {
                  if (box.isEmpty) {
                    return _empty();
                  }
                  final allGems = box.values.toList();
                  final filteredGems = _filterGemstonesByPeriod(allGems);
                  if (filteredGems.isEmpty) {
                    return _empty();
                  }
                  final keys = filteredGems
                      .map((g) => box.keys.firstWhere(
                            (k) => box.get(k)?.id == g.id,
                            orElse: () => null,
                          ))
                      .where((k) => k != null)
                      .toList()
                      .reversed
                      .toList();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    itemCount: keys.length,
                    itemBuilder: (context, i) {
                      final key = keys[i];
                      final g = box.get(key)!;
                      return Card(
                        color: AppTheme.surfaceDark,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            // Date box at the top
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAccent.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                    size: 16,
                                    color: AppTheme.primaryAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _date.format(DateTime.fromMillisecondsSinceEpoch(g.createdAt)),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryAccent.withOpacity(0.2),
                            child: const Icon(Icons.diamond,
                                color: AppTheme.primaryAccent),
                          ),
                          title: Text(g.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${g.type} • ${_trim(g.weightCarat)} ${LocalDb.unitLabel(g.weightUnit)}',
                                  style: TextStyle(color: Colors.grey[400])),
                              Row(
                                children: [
                                  Expanded(
                                    child: Builder(builder: (c) {
                                      final remaining = LocalDb.gemstoneRemainingQuantity(g);
                                      return Text(
                                          'ဝယ်ဈေး: ${_money.format(g.costPrice)} ကျပ် • ဝယ်ထားသော: ${g.quantity} • ကျန်ရှိ: $remaining',
                                          style: const TextStyle(
                                              color: AppTheme.primaryAccent,
                                              fontSize: 12));
                                    }),
                                  ),
                                  if (LocalDb.gemstoneRemainingQuantity(g) <= 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.errorColor
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'အရောင်းအဆုံး',
                                        style: TextStyle(
                                          color: AppTheme.errorColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Builder(builder: (c) {
                                final totalCost = LocalDb.gemstoneTotalCost(g);
                                final result =
                                    LocalDb.calculateRemainingCostAndProfit(
                                        g.id);
                                final remainingCost =
                                    result['remainingCost'] as double? ?? 0;
                                final totalProfit =
                                    result['totalProfit'] as double? ?? 0;
                                final recoveredCost = g.recoveredCost;
                                final currentProfit =
                                    0.0; // Current profit shown in sales records

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'စုစုပေါင်း အရင်း: ${_money.format(totalCost)} ကျပ်',
                                        style: const TextStyle(
                                            color: Colors.orangeAccent,
                                            fontSize: 11)),
                                    Text(
                                        'ပြန်လည်ရရှိ: ${_money.format(recoveredCost)} ကျပ်',
                                        style: const TextStyle(
                                            color: Colors.lightBlue,
                                            fontSize: 11)),
                                    Text(
                                        'ကျန်ရှိအရင်း: ${_money.format(remainingCost)} ကျပ်',
                                        style: TextStyle(
                                            color: remainingCost > 0
                                                ? Colors.yellow
                                                : Colors.green,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                    if (currentProfit > 0)
                                      Text(
                                          'လက်ရှိအမြတ်: ${_money.format(currentProfit)} ကျပ်',
                                          style: const TextStyle(
                                              color: Colors.lightGreen,
                                              fontSize: 11)),
                                    if (totalProfit > 0)
                                      Text(
                                          'စုစုပေါင်းအမြတ်: ${_money.format(totalProfit)} ကျပ်',
                                          style: const TextStyle(
                                              color: Colors.lightGreen,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    if (g.quantity <= 0 && totalProfit <= 0)
                                      Text('အမြတ်မရှိသေးပါ',
                                          style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 11))
                                  ],
                                );
                              }),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            color: AppTheme.surfaceLight,
                            icon: Icon(Icons.more_vert,
                                color: LocalDb.canEditPurchase() ? Colors.white : Colors.grey[600]),
                            enabled: LocalDb.canEditPurchase(),
                            onSelected: (v) {
                              if (v == 'edit') _openForm(existing: g, key: key);
                              if (v == 'delete') _delete(key);
                              if (v == 'photos') _showPhotoViewer(g);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                  value: 'edit',
                                  enabled: LocalDb.canEditPurchase(),
                                  child: const Row(
                                    children: [
                                      Text('✏️'),
                                      SizedBox(width: 8),
                                      Text('ပြုပြင်ရန်'),
                                    ],
                                  )),
                              PopupMenuItem(
                                  value: 'delete',
                                  enabled: LocalDb.canDeletePurchase(),
                                  child: const Row(
                                    children: [
                                      Text('🗑️'),
                                      SizedBox(width: 8),
                                      Text('ဖျက်ရန်'),
                                    ],
                                  )),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                  value: 'photos',
                                  child: const Row(
                                    children: [
                                      Text('🖼️'),
                                      SizedBox(width: 8),
                                      Text('ဓာတ်ပုံကြည့်ရန်'),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                        // Breakdown summary section (collapsed/expandable)
                        if (g.breakdownItems.isNotEmpty)
                          _buildBreakdownSummarySection(g),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    ],
    ),
  );
}

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.diamond, size: 70, color: Colors.grey[700]),
            const SizedBox(height: 12),
            Text(
              _selectedPeriod == 'all'
                  ? 'ကျောက်မျက်စာရင်း မရှိသေးပါ'
                  : 'ရွေးချယ်ထားသည့် ကာလတွင် ကျောက်မျက် မရှိပါ',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            Text('အောက်က ခလုတ်ဖြင့် ထည့်ပါ',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      );

  /// Build collapsed/expandable breakdown summary section
  Widget _buildBreakdownSummarySection(Gemstone gemstone) {
    final isExpanded = _expandedBreakdowns.contains(gemstone.id);
    
    // Filter breakdown items with quantity > 0
    final activeItems = gemstone.breakdownItems.entries
        .where((e) => e.value > 0)
        .toList();
    
    if (activeItems.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Build summary text (collapsed view) - one item per line
    final summaryText = activeItems
        .map((e) => '${e.key} — ${e.value}')
        .join('\n');
    
    return GestureDetector(
      onTap: () => setState(() {
        if (isExpanded) {
          _expandedBreakdowns.remove(gemstone.id);
        } else {
          _expandedBreakdowns.add(gemstone.id);
        }
      }),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'ကျောက်အစိတ်စိတ်ပိုင်းများ:',
                    style: TextStyle(
                      color: AppTheme.primaryAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (activeItems.length > 1)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primaryAccent,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (isExpanded)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...activeItems.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: TextStyle(
                            color: AppTheme.primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              )
            else
              Text(
                summaryText,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                  height: 1.5,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  /// Build period filter button
  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAccent : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GemstoneForm extends StatefulWidget {
  final Gemstone? existing;
  final dynamic hiveKey;
  const _GemstoneForm({this.existing, this.hiveKey});

  @override
  State<_GemstoneForm> createState() => _GemstoneFormState();
}

class _GemstoneFormState extends State<_GemstoneForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _type;
  late final TextEditingController _weight;
  late final TextEditingController _cost;
  late final TextEditingController _commission;
  late final TextEditingController _processingFee;
  late final TextEditingController _repairFee;
  late final TextEditingController _breakageFee;
  late final TextEditingController _bloodFee;
  late final TextEditingController _laborFee;
  late final TextEditingController _miscFee;
  late final TextEditingController _qty;
  late final TextEditingController _color;
  late final TextEditingController _origin;
  late final TextEditingController _note;
  late final TextEditingController _breakdownItemNameCtrl; // breakdown item name input
  late final TextEditingController _breakdownItemQtyCtrl; // breakdown item quantity input
  String _weightUnit = 'kg';
  late List<String> _photoPaths;
  late Map<String, Map<String, dynamic>> _breakdownItems; // breakdown item name -> {quantity, weight, weightUnit}
  late List<String> _breakdownItemNames; // list of added breakdown item names (for ordering)
  String? _customItemName; // for custom item input
  bool _breakdownExpanded = false; // Track if breakdown section is expanded

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _photoPaths = List.from(e?.photoPaths ?? []);
    // Load saved breakdown items
    if (e?.breakdownItems != null && e!.breakdownItems.isNotEmpty) {
      _breakdownItems = Map.from(e.breakdownItems);
      _breakdownItemNames = List.from(e.breakdownItems.keys);
    } else {
      _breakdownItems = {};
      _breakdownItemNames = [];
    }
    _customItemName = null;
    _name = TextEditingController(text: e?.name ?? '');
    _type = TextEditingController(text: e?.type ?? '');
    _weight = TextEditingController(text: e?.weightCarat.toString() ?? '');
    _weightUnit = e?.weightUnit ?? 'kg';
    _cost = TextEditingController(text: e?.costPrice.toString() ?? '');
    _commission = TextEditingController(
        text: (e != null && e.commissionFee > 0)
            ? e.commissionFee.toString()
            : '');
    _processingFee = TextEditingController(
        text: (e != null && e.processingFee > 0)
            ? e.processingFee.toString()
            : '');
    _repairFee = TextEditingController(
        text: (e != null && e.repairFee > 0) ? e.repairFee.toString() : '');
    _breakageFee = TextEditingController(
        text: (e != null && e.breakageFee > 0) ? e.breakageFee.toString() : '');
    _bloodFee = TextEditingController(
        text: (e != null && e.bloodFee > 0) ? e.bloodFee.toString() : '');
    _laborFee = TextEditingController(
        text: (e != null && e.laborFee > 0) ? e.laborFee.toString() : '');
    _miscFee = TextEditingController(
        text: (e != null && e.miscFee > 0) ? e.miscFee.toString() : '');
    _qty = TextEditingController(text: e?.quantity.toString() ?? '1');
    _color = TextEditingController(text: e?.color ?? '');
    _origin = TextEditingController(text: e?.origin ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _breakdownItemNameCtrl = TextEditingController();
    _breakdownItemQtyCtrl = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _type,
      _weight,
      _cost,
      _commission,
      _processingFee,
      _repairFee,
      _breakageFee,
      _bloodFee,
      _laborFee,
      _miscFee,
      _qty,
      _color,
      _origin,
      _note,
      _breakdownItemNameCtrl,
      _breakdownItemQtyCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _d(String s) => double.tryParse(s.trim()) ?? 0;
  int _i(String s) => int.tryParse(s.trim()) ?? 0;

  void _addBreakdownItem(String itemName, int quantity) {
    if (itemName.isEmpty || quantity <= 0) return;
    setState(() {
      if (!_breakdownItems.containsKey(itemName)) {
        _breakdownItemNames.add(itemName);
      }
      _breakdownItems[itemName] = {
        'quantity': quantity,
        'weight': null,
        'weightUnit': null,
      };
      _customItemName = null;
    });
  }

  void _removeBreakdownItem(String itemName) {
    setState(() {
      _breakdownItems.remove(itemName);
      _breakdownItemNames.remove(itemName);
    });
  }

  List<String> _getBreakdownItemOptions() => [
    "ဖျက်စ",
    "လွှာချက်",
    "လက်ကောက်",
    "လက်စွပ်",
    "ပုတီး",
    "ပန်းပု",
    "မိမိစိတ်ကြိုက်",
  ];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final box = LocalDb.gemstones();
    if (widget.existing != null && widget.hiveKey != null) {
      final g = widget.existing!;
      g.name = _name.text.trim();
      g.type = _type.text.trim();
      g.weightCarat = _d(_weight.text);
      g.weightUnit = _weightUnit;
      g.costPrice = _d(_cost.text);
      g.commissionFee = _d(_commission.text);
      g.processingFee = _d(_processingFee.text);
      g.repairFee = _d(_repairFee.text);
      g.breakageFee = _d(_breakageFee.text);
      g.bloodFee = _d(_bloodFee.text);
      g.laborFee = _d(_laborFee.text);
      g.miscFee = _d(_miscFee.text);
      g.quantity = _i(_qty.text);
      g.color = _color.text.trim();
      g.origin = _origin.text.trim();
      g.note = _note.text.trim();
      g.photoPaths = _photoPaths;
      g.breakdownItems = _breakdownItems;
      await box.put(widget.hiveKey, g);
    } else {
      await box.add(Gemstone(
        id: LocalDb.genId(),
        name: _name.text.trim(),
        type: _type.text.trim(),
        weightCarat: _d(_weight.text),
        weightUnit: _weightUnit,
        costPrice: _d(_cost.text),
        commissionFee: _d(_commission.text),
        processingFee: _d(_processingFee.text),
        repairFee: _d(_repairFee.text),
        breakageFee: _d(_breakageFee.text),
        bloodFee: _d(_bloodFee.text),
        laborFee: _d(_laborFee.text),
        miscFee: _d(_miscFee.text),
        quantity: _i(_qty.text),
        color: _color.text.trim(),
        origin: _origin.text.trim(),
        status: 'in_stock',
        note: _note.text.trim(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        photoPaths: _photoPaths,
        breakdownItems: _breakdownItems,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(isEdit ? 'ကျောက်မျက် ပြင်ဆင်ရန်' : 'ကျောက်မျက်အသစ်',
                    style: const TextStyle(
                        color: AppTheme.primaryAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _field(_name, 'အမည်', required: true),
                _field(_type, 'အမျိုးအစား (ဥပမာ - ပတ္တမြား)'),
                Row(children: [
                  Expanded(
                      flex: 2,
                      child: _field(_weight, 'အလေးချိန်', number: true)),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: _weightUnit,
                        isExpanded: true,
                        dropdownColor: AppTheme.surfaceLight,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'ယူနစ်'),
                        items: LocalDb.weightUnits.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _weightUnit = v ?? 'kg'),
                      ),
                    ),
                  ),
                ]),
                _field(_qty, 'အရေအတွက်', number: true),
                _field(_cost, 'ဝယ်ဈေး', number: true),
                const Divider(color: Colors.grey),
                const SizedBox(height: 8),
                Text('ကုန်ကျစရိတ်များ',
                    style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _field(_commission, 'ဝယ်ယူစဉ် ပွဲခ', number: true),
                _field(_processingFee, 'ဆီဖိုး', number: true),
                _field(_repairFee, 'ပြုပြင်ခ', number: true),
                _field(_breakageFee, 'ဖျက်ခ', number: true),
                _field(_bloodFee, 'သွေးခ', number: true),
                _field(_laborFee, 'အလုပ်သမားခ', number: true),
                _field(_miscFee, 'အထွေထွေ', number: true),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _field(_color, 'အရောင်')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_origin, 'မူရင်းနေရာ')),
                ]),
                _field(_note, 'မှတ်ချက်'),
                const SizedBox(height: 20),
                // Breakdown Items Section (Collapsed/Expandable)
                _buildBreakdownSection(),
                const SizedBox(height: 20),
                PhotoAttachmentWidget(
                  photoPaths: _photoPaths,
                  onPhotosChanged: (photos) {
                    setState(() => _photoPaths = photos);
                  },
                  recordType: 'purchase',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(isEdit ? 'သိမ်းဆည်းမည်' : 'ထည့်သွင်းမည်',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build collapsed/expandable breakdown section
  Widget _buildBreakdownSection() {
    return GestureDetector(
      onTap: () => setState(() => _breakdownExpanded = !_breakdownExpanded),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ကျောက်အစိတ်စိတ်ပိုင်းများ',
                  style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  _breakdownExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.primaryAccent,
                  size: 20,
                ),
              ],
            ),
            if (_breakdownExpanded) ...[const SizedBox(height: 12), _buildBreakdownItemsSection()],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItemsSection() {
    return Column(
      children: [
        // Added breakdown items display
        if (_breakdownItemNames.isNotEmpty)
          Column(
            children: _breakdownItemNames.map((itemName) {
              final itemData = (_breakdownItems[itemName] ?? {}) as Map<String, dynamic>;
              final qty = (itemData['quantity'] as int?) ?? 0;
              final weight = (itemData['weight'] as num?)?.toDouble();
              final weightUnit = itemData['weightUnit'] as String?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '— $qty',
                              style: TextStyle(
                                color: AppTheme.primaryAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (weight != null && weight > 0)
                              Text(
                                '${weight.toStringAsFixed(2)} ${weightUnit ?? "kg"}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeBreakdownItem(itemName),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        if (_breakdownItemNames.isNotEmpty) const SizedBox(height: 12),
        // Add breakdown item form
        _buildAddBreakdownItemForm(),
      ],
    );
  }

  Widget _buildAddBreakdownItemForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _breakdownItemNameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'အမည် ရေးရန်',
                  hintText: 'ဥပမာ - ဖျက်စ',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _breakdownItemQtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'အရေအတွက်',
                  hintText: '0',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final itemName = _breakdownItemNameCtrl.text.trim();
              final qty = int.tryParse(_breakdownItemQtyCtrl.text.trim()) ?? 0;
              if (itemName.isNotEmpty && qty > 0) {
                _addBreakdownItem(itemName, qty);
                _breakdownItemNameCtrl.clear();
                _breakdownItemQtyCtrl.clear();
              }
            },
            child: const Text(
              'ထည့်ရန်',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool number = false, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'ဖြည့်ပါ' : null
            : null,
      ),
    );
  }
}
