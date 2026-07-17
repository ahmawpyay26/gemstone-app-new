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
            totalVouchers: widget.vouchers.length,
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text: 'လက်ရှိအပ်ထားဆဲ (${active.length})',
              ),
              Tab(
                text: 'ပြီးဆုံးပြီး (${completed.length})',
              ),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ActiveTab(vouchers: active),
                _CompletedTab(vouchers: completed),
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
  final int totalVouchers;

  const _BrokerHeader({
    required this.brokerName,
    required this.brokerPhone,
    required this.brokerAddress,
    required this.totalRemaining,
    required this.totalVouchers,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
            if (brokerPhone.isNotEmpty)
              Text(
                'ဖုန်း: $brokerPhone',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            if (brokerAddress.isNotEmpty)
              Text(
                'လိပ်စာ: $brokerAddress',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HeaderStat(
                  label: 'လက်ကျန်',
                  value: totalRemaining.toStringAsFixed(0),
                ),
                _HeaderStat(
                  label: 'ဘောင်ချာစုစုပေါင်း',
                  value: totalVouchers.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ActiveTab extends StatelessWidget {
  final List<BrokerConsignment> vouchers;

  const _ActiveTab({required this.vouchers});

  @override
  Widget build(BuildContext context) {
    if (vouchers.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: vouchers.length,
      itemBuilder: (context, index) {
        final bc = vouchers[index];
        return _VoucherCard(
          bc: bc,
          status: 'လက်ရှိအပ်ထားဆဲ',
          statusColor: Colors.orange,
          onTap: () {
            context.push(
              '/broker-consignment/${bc.id}',
              extra: bc,
            );
          },
        );
      },
    );
  }
}

class _CompletedTab extends StatelessWidget {
  final List<BrokerConsignment> vouchers;

  const _CompletedTab({required this.vouchers});

  @override
  Widget build(BuildContext context) {
    if (vouchers.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: vouchers.length,
      itemBuilder: (context, index) {
        final bc = vouchers[index];
        return _VoucherCard(
          bc: bc,
          status: 'ပြီးဆုံးပြီး',
          statusColor: Colors.green,
          onTap: () {
            context.push(
              '/broker-consignment/${bc.id}',
              extra: bc,
            );
          },
        );
      },
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final BrokerConsignment bc;
  final String status;
  final Color statusColor;
  final VoidCallback onTap;

  const _VoucherCard({
    required this.bc,
    required this.status,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(bc.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voucher number and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bc.voucherNumber ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Quantities row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuantityItem(
                    label: 'မူလအပ်',
                    value: bc.consignedQuantity.toStringAsFixed(0),
                  ),
                  _QuantityItem(
                    label: 'ရောင်းချ',
                    value: bc.soldQuantity.toStringAsFixed(0),
                  ),
                  _QuantityItem(
                    label: 'ပြန်လည်ရယူ',
                    value: bc.returnedQuantity.toStringAsFixed(0),
                  ),
                  _QuantityItem(
                    label: 'လက်ကျန်',
                    value: bc.remainingQuantity.toStringAsFixed(0),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _QuantityItem extends StatelessWidget {
  final String label;
  final String value;

  const _QuantityItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
