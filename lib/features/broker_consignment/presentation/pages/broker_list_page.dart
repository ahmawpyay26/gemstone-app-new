import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';

class BrokerListPage extends StatefulWidget {
  const BrokerListPage({Key? key}) : super(key: key);

  @override
  State<BrokerListPage> createState() => _BrokerListPageState();
}

class _BrokerListPageState extends State<BrokerListPage> {
  late final ValueNotifier<int> _refreshNotifier;

  @override
  void initState() {
    super.initState();
    _refreshNotifier = ValueNotifier(0);
    _setupHiveListener();
  }

  void _setupHiveListener() {
    final brokers = Hive.box<BrokerConsignment>(LocalDb.brokerConsignmentsBox);
    brokers.listenable().addListener(() {
      _refreshNotifier.value++;
    });
  }

  @override
  void dispose() {
    _refreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ပွဲစားအပ်မှတ်တမ်း'),
        elevation: 0,
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: _refreshNotifier,
        builder: (context, _, __) {
          final sortedGroups = LocalDb.getSortedBrokerGroups();

          if (sortedGroups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ပွဲစားအပ်မှတ်တမ်း မရှိသေးပါ။',
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
            itemCount: sortedGroups.length,
            itemBuilder: (context, index) {
              final entry = sortedGroups[index];
              final vouchers = entry.value;
              final summary = LocalDb.getBrokerSummary(vouchers);

              return _BrokerCard(
                summary: summary,
                vouchers: vouchers,
                onTap: () {
                  context.push(
                    '/broker-consignment/detail',
                    extra: {
                      'brokerName': summary['brokerName'],
                      'brokerPhone': summary['brokerPhone'],
                      'brokerAddress': summary['brokerAddress'],
                      'vouchers': vouchers,
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/broker-consignment/form');
        },
        tooltip: 'အသစ်ထည့်သွင်းရန်',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BrokerCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  final List<BrokerConsignment> vouchers;
  final VoidCallback onTap;

  const _BrokerCard({
    required this.summary,
    required this.vouchers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brokerName = summary['brokerName'] as String;
    final brokerPhone = summary['brokerPhone'] as String;
    final totalRemaining = summary['totalRemaining'] as double;
    final activeCount = summary['activeCount'] as int;
    final completedCount = summary['completedCount'] as int;
    final latestDate = summary['latestDate'] as int;

    final dateStr = _formatDate(latestDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Broker name and phone
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brokerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (brokerPhone.isNotEmpty)
                          Text(
                            brokerPhone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Total remaining
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'လက်ကျန်',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        totalRemaining.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(
                    label: 'လက်ရှိအပ်ထားဆဲ',
                    value: activeCount.toString(),
                  ),
                  _StatItem(
                    label: 'ပြီးဆုံးပြီး',
                    value: completedCount.toString(),
                  ),
                  _StatItem(
                    label: 'နောက်ဆုံးအပ်သည့်နေ့',
                    value: dateStr,
                  ),
                ],
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
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
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
