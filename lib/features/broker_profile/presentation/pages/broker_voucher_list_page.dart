import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gemstone_management/core/local/local_db.dart';
import 'package:gemstone_management/core/local/models.dart';
import 'package:gemstone_management/core/theme/app_theme.dart';

class BrokerVoucherListPage extends StatefulWidget {
  final String brokerId;

  const BrokerVoucherListPage({Key? key, required this.brokerId})
      : super(key: key);

  @override
  State<BrokerVoucherListPage> createState() => _BrokerVoucherListPageState();
}

class _BrokerVoucherListPageState extends State<BrokerVoucherListPage> {
  BrokerProfile? _broker;
  List<_VoucherGroup> _voucherGroups = [];
  bool _isLoading = true;
  String? _errorMessage;
  late final DateFormat _dateFormat;

  @override
  void initState() {
    super.initState();
    _dateFormat = DateFormat('dd/MM/yyyy');
    _loadData();
  }

  void _loadData() {
    try {
      if (widget.brokerId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ပွဲစားအချက်အလက် မတွေ့ပါ။';
        });
        return;
      }

      // Load broker profile
      _broker = LocalDb.brokerProfileById(widget.brokerId);
      if (_broker == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ပွဲစားအချက်အလက် မတွေ့ပါ။';
        });
        return;
      }

      // Load all consignments for this broker
      final box = LocalDb.brokerConsignments();
      final allConsignments = box.values.toList();

      final brokerConsignments = allConsignments.where((c) {
        final matchById = c.brokerProfileId == _broker!.id;
        final matchByName = c.brokerProfileId == null &&
            c.brokerName == _broker!.name;
        return (matchById || matchByName) && c.isActive;
      }).toList();

      // Group by voucherId
      final voucherMap = <String, List<BrokerConsignment>>{};
      for (final c in brokerConsignments) {
        final key = c.voucherId ?? c.id; // fallback to item id if no voucherId
        voucherMap.putIfAbsent(key, () => []).add(c);
      }

      // Build voucher groups sorted by createdAt descending (newest first)
      _voucherGroups = voucherMap.entries.map((entry) {
        final items = entry.value;
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        final representative = items.first;
        final totalConsigned =
            items.fold<double>(0, (sum, c) => sum + c.consignedQuantity);
        final totalSold =
            items.fold<double>(0, (sum, c) => sum + c.soldQuantity);
        final totalReturned =
            items.fold<double>(0, (sum, c) => sum + c.returnedQuantity);
        final totalRemaining =
            items.fold<double>(0, (sum, c) => sum + c.remainingQuantity);
        return _VoucherGroup(
          voucherId: entry.key,
          voucherNumber: representative.voucherNumber,
          representative: representative,
          items: items,
          totalConsigned: totalConsigned,
          totalSold: totalSold,
          totalReturned: totalReturned,
          totalRemaining: totalRemaining,
          createdAt: representative.createdAt,
        );
      }).toList();

      // Sort newest first
      _voucherGroups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ဘောင်ချာများ ဖွင့်၍မရပါ။\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/brokers');
            }
          },
        ),
        title: Text(
          _broker != null
              ? '${_broker!.name} ၏ ဘောင်ချာများ'
              : 'ဘောင်ချာများ',
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    if (_voucherGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              'ဘောင်ချာမှတ်တမ်း မရှိသေးပါ။',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _voucherGroups.length,
      itemBuilder: (context, index) {
        return _buildVoucherCard(_voucherGroups[index]);
      },
    );
  }

  Widget _buildVoucherCard(_VoucherGroup group) {
    final isCompleted = group.totalRemaining <= 0;

    return GestureDetector(
      onTap: () {
        // Navigate to broker consignment detail using representative item id
        if (group.representative.id.isNotEmpty) {
          context.push('/broker-consignment/${group.representative.id}');
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: voucher number + date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    group.voucherNumber ?? 'BC-${group.voucherId.substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryAccent,
                        ),
                  ),
                  Text(
                    _dateFormat.format(
                      DateTime.fromMillisecondsSinceEpoch(group.createdAt),
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Stats row
              Row(
                children: [
                  _statChip('ယူဘူး', group.totalConsigned),
                  const SizedBox(width: 8),
                  _statChip('ရောင်းပြီး', group.totalSold),
                  const SizedBox(width: 8),
                  _statChip('ပြန်အပ်', group.totalReturned),
                  const Spacer(),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green[800]
                          : Colors.orange[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCompleted ? 'ပြီးစီး' : 'လုပ်ဆောင်ဆဲ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isCompleted) ...[
                const SizedBox(height: 6),
                Text(
                  'လက်ကျန်: ${group.totalRemaining.toStringAsFixed(2)} အလုံး',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[300],
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.grey[500]),
        ),
        Text(
          value.toStringAsFixed(2),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Internal data class for grouped voucher display
class _VoucherGroup {
  final String voucherId;
  final String? voucherNumber;
  final BrokerConsignment representative;
  final List<BrokerConsignment> items;
  final double totalConsigned;
  final double totalSold;
  final double totalReturned;
  final double totalRemaining;
  final int createdAt;

  _VoucherGroup({
    required this.voucherId,
    required this.voucherNumber,
    required this.representative,
    required this.items,
    required this.totalConsigned,
    required this.totalSold,
    required this.totalReturned,
    required this.totalRemaining,
    required this.createdAt,
  });
}
