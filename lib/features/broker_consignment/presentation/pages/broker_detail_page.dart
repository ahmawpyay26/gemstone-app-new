import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

class BrokerDetailPage extends StatefulWidget {
  final String brokerName;
  final String brokerPhone;
  final String brokerAddress;
  final List<BrokerConsignment> vouchers;

  const BrokerDetailPage({
    Key? key,
    required this.brokerName,
    required this.brokerPhone,
    required this.brokerAddress,
    required this.vouchers,
  }) : super(key: key);

  @override
  State<BrokerDetailPage> createState() => _BrokerDetailPageState();
}

class _BrokerDetailPageState extends State<BrokerDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = LocalDb.getActiveBrokerVouchers(widget.vouchers);
    final completed = LocalDb.getCompletedBrokerVouchers(widget.vouchers);

    // Group by voucherNumber
    final activeGrouped = LocalDb.groupBrokerConsignmentsByVoucher(active);
    final completedGrouped = LocalDb.groupBrokerSaleRecordsByVoucher(completed);

    double totalRemaining = 0;
    for (final bc in widget.vouchers) {
      totalRemaining += bc.remainingQuantity;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.brokerName),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with broker info
          _BrokerHeader(
            brokerName: widget.brokerName,
            brokerPhone: widget.brokerPhone,
            brokerAddress: widget.brokerAddress,
            totalRemaining: totalRemaining,
            activeVouchers: activeGrouped.length,
            completedVouchers: completedGrouped.length,
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text: 'လက်ရှိအပ်ထားဆဲ (${activeGrouped.length})',
              ),
              Tab(
                text: 'ပြီးဆုံးပြီး (${completedGrouped.length})',
              ),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ActiveTab(groupedVouchers: activeGrouped),
                _CompletedTab(groupedVouchers: completedGrouped),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrokerHeader extends StatelessWidget {
  final String brokerName;
  final String brokerPhone;
  final String brokerAddress;
  final double totalRemaining;
  final int activeVouchers;
  final int completedVouchers;

  const _BrokerHeader({
    required this.brokerName,
    required this.brokerPhone,
    required this.brokerAddress,
    required this.totalRemaining,
    required this.activeVouchers,
    required this.completedVouchers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            brokerName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ဖုန်း: $brokerPhone',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            'လိပ်စာ: $brokerAddress',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'လက်ရှိ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '$activeVouchers',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'ပြီးဆုံး',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '$completedVouchers',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'ကျန်ရှိ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    totalRemaining.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveTab extends StatelessWidget {
  final Map<String, List<BrokerConsignment>> groupedVouchers;

  const _ActiveTab({required this.groupedVouchers});

  @override
  Widget build(BuildContext context) {
    if (groupedVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'လက်ရှိအပ်ထားဆဲ ဘောင်ချာ မရှိပါ။',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final voucherNumbers = groupedVouchers.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: voucherNumbers.length,
      itemBuilder: (context, index) {
        final voucherNum = voucherNumbers[index];
        final items = groupedVouchers[voucherNum]!;

        return _VoucherGroupCard(
          voucherNumber: voucherNum,
          items: items,
          status: 'လက်ရှိအပ်ထားဆဲ',
          statusColor: Colors.orange,
        );
      },
    );
  }
}

class _CompletedTab extends StatelessWidget {
  final Map<String, List<BrokerSaleRecord>> groupedVouchers;

  const _CompletedTab({required this.groupedVouchers});

  @override
  Widget build(BuildContext context) {
    if (groupedVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.done_all,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'ပြီးဆုံးပြီး ဘောင်ချာ မရှိပါ။',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final voucherNumbers = groupedVouchers.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: voucherNumbers.length,
      itemBuilder: (context, index) {
        final voucherNum = voucherNumbers[index];
        final sales = groupedVouchers[voucherNum]!;

        return _CompletedVoucherCard(
          voucherNumber: voucherNum,
          sales: sales,
        );
      },
    );
  }
}

class _VoucherGroupCard extends StatefulWidget {
  final String voucherNumber;
  final List<BrokerConsignment> items;
  final String status;
  final Color statusColor;

  const _VoucherGroupCard({
    required this.voucherNumber,
    required this.items,
    required this.status,
    required this.statusColor,
  });

  @override
  State<_VoucherGroupCard> createState() => _VoucherGroupCardState();
}

class _VoucherGroupCardState extends State<_VoucherGroupCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    double totalWholeQty = 0;
    double totalFragmentQty = 0;
    double totalRemaining = 0;

    for (final item in widget.items) {
      totalWholeQty += item.wholeStoneQuantity;
      totalFragmentQty += item.breakdownItemQuantity;
      totalRemaining += item.remainingQuantity;
    }

    final firstItem = widget.items.first;
    final dateStr = DateTime.fromMillisecondsSinceEpoch(firstItem.createdAt)
        .toString()
        .split(' ')[0];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.receipt, color: widget.statusColor),
            title: Text(
              widget.voucherNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(dateStr),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${widget.items.length} ခု',
                    style: TextStyle(
                      color: widget.statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow('စုစုပေါင်းခုနှုန်း', '${widget.items.length}'),
                  _SummaryRow('စုစုပေါင်း (ကျောက်အလုံး)', totalWholeQty.toStringAsFixed(2)),
                  _SummaryRow('စုစုပေါင်း (အစိတ်စိတ်)', totalFragmentQty.toStringAsFixed(2)),
                  _SummaryRow('ကျန်ရှိ', totalRemaining.toStringAsFixed(2)),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'အရေးအသားများ:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.items.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'အရေးအသား $idx',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('ကျောက်အလုံး: ${item.wholeStoneQuantity}'),
                            Text('အစိတ်စိတ်: ${item.breakdownItemQuantity}'),
                            Text('ကျန်ရှိ: ${item.remainingQuantity}'),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CompletedVoucherCard extends StatefulWidget {
  final String voucherNumber;
  final List<BrokerSaleRecord> sales;

  const _CompletedVoucherCard({
    required this.voucherNumber,
    required this.sales,
  });

  @override
  State<_CompletedVoucherCard> createState() => _CompletedVoucherCardState();
}

class _CompletedVoucherCardState extends State<_CompletedVoucherCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    double totalSoldQty = 0;
    double totalAmount = 0;

    for (final sale in widget.sales) {
      totalSoldQty += sale.soldQuantity;
      totalAmount += sale.totalSaleAmount;
    }

    final firstSale = widget.sales.first;
    final dateStr = DateTime.fromMillisecondsSinceEpoch(firstSale.saleDate)
        .toString()
        .split(' ')[0];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(
              widget.voucherNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(dateStr),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${widget.sales.length} ခု',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow('စုစုပေါင်းခုနှုန်း', '${widget.sales.length}'),
                  _SummaryRow('စုစုပေါင်းရောင်းချ', totalSoldQty.toStringAsFixed(2)),
                  _SummaryRow('စုစုပေါင်းငွေ', totalAmount.toStringAsFixed(2)),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'ရောင်းချမှတ်တမ်းများ:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.sales.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final sale = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'မှတ်တမ်း $idx',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('ရောင်းချ: ${sale.soldQuantity}'),
                            Text('ယူနစ်စျေး: ${sale.unitPrice}'),
                            Text('စုစုပေါင်းငွေ: ${sale.totalSaleAmount}'),
                            Text('ပွဲစားခ: ${sale.brokerCommission}'),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
