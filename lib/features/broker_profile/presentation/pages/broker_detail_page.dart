import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gemstone_management/core/local/local_db.dart';
import 'package:gemstone_management/core/local/models.dart';
import 'package:gemstone_management/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class BrokerProfileDetailPage extends StatefulWidget {
  final String brokerId;

  const BrokerProfileDetailPage({
    Key? key,
    required this.brokerId,
  }) : super(key: key);

  @override
  State<BrokerProfileDetailPage> createState() => _BrokerProfileDetailPageState();
}

class _BrokerProfileDetailPageState extends State<BrokerProfileDetailPage> {
  BrokerProfile? _broker;
  List<BrokerConsignment> _brokerVouchers = [];
  late final DateFormat _dateFormat;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dateFormat = DateFormat('dd/MM/yyyy', 'my_MM');
    _loadBrokerData();
  }

  void _loadBrokerData() {
    try {
      // Validate broker ID
      if (widget.brokerId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'ပွဲစားအချက်အလက် မတွေ့ပါ။';
          });
        }
        return;
      }

      // Load broker profile
      _broker = LocalDb.brokerProfileById(widget.brokerId);
      if (_broker == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'ပွဲစားအချက်အလက် မတွေ့ပါ။';
          });
        }
        return;
      }

      // Load broker vouchers
      try {
        final box = LocalDb.brokerConsignments();
        final allConsignments = box.values.toList();
        _brokerVouchers = allConsignments
            .where((consignment) =>
                consignment.brokerName == _broker!.name &&
                consignment.isActive)
            .toList();

        // Sort by createdAt descending (newest first)
        if (_brokerVouchers.isNotEmpty) {
          _brokerVouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }
      } catch (e) {
        // If voucher loading fails, continue with empty list
        _brokerVouchers = [];
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading broker detail: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ပွဲစားအချက်အလက် ဖွင့်၍မရပါ။\n$e';
        });
      }
    }
  }

  Map<String, dynamic> _calculateSummary() {
    double totalConsigned = 0;
    double totalSold = 0;
    double totalReturned = 0;
    double totalRemaining = 0;

    for (final consignment in _brokerVouchers) {
      totalConsigned += consignment.consignedQuantity;
      totalSold += consignment.soldQuantity;
      totalReturned += consignment.returnedQuantity;
      totalRemaining += consignment.remainingQuantity;
    }

    return {
      'totalConsigned': totalConsigned,
      'totalSold': totalSold,
      'totalReturned': totalReturned,
      'totalRemaining': totalRemaining,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ပွဲစားအချက်အလက်'),
        backgroundColor: AppTheme.primaryAccent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show loading state
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error state
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

    // Show broker not found
    if (_broker == null) {
      return Center(
        child: Text(
          'ပွဲစားအချက်အလက် မတွေ့ပါ။',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final summary = _calculateSummary();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Broker Profile Section
          _buildBrokerProfileSection(),
          const SizedBox(height: 24),
          // Summary Box
          _buildSummaryBox(summary),
          const SizedBox(height: 24),
          // Voucher History
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ဘောင်ချာမှတ်တမ်း',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          _buildVoucherHistory(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBrokerProfileSection() {
    if (_broker == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Photo and Name
          Row(
            children: [
              _buildProfileAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _broker!.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _broker!.phone,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Additional Info
          if (_broker!.nationalId != null && _broker!.nationalId!.isNotEmpty)
            _buildInfoRow('အမှတ်တံဆိပ်နံပါတ်', _broker!.nationalId!),
          if (_broker!.address != null && _broker!.address!.isNotEmpty)
            _buildInfoRow('လိပ်စာ', _broker!.address!),
          if (_broker!.socialAccount != null &&
              _broker!.socialAccount!.isNotEmpty)
            _buildInfoRow('လူမှုကွန်ရက်အကောင့်', _broker!.socialAccount!),
          if (_broker!.note != null && _broker!.note!.isNotEmpty)
            _buildInfoRow('မှတ်ချက်', _broker!.note!),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    try {
      if (_broker?.profileImagePath != null &&
          _broker!.profileImagePath!.isNotEmpty) {
        final file = File(_broker!.profileImagePath!);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: 40,
            backgroundImage: FileImage(file),
          );
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }

    // Default icon if image not available or error
    return CircleAvatar(
      radius: 40,
      backgroundColor: AppTheme.primaryAccent,
      child: Icon(
        Icons.person,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(Map<String, dynamic> summary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'စုစုပေါင်းယူဘူးသောအလုံးရေ',
                      summary['totalConsigned'].toStringAsFixed(2),
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'ရောင်းချပေးပြီးသောစုစုပေါင်းအလုံးရေ',
                      summary['totalSold'].toStringAsFixed(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'ပြန်အပ်ပေးထားသောစုစုပေါင်းအလုံးရေ',
                      summary['totalReturned'].toStringAsFixed(2),
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'လက်ကျန်စုစုပေါင်းအလုံးရေ',
                      summary['totalRemaining'].toStringAsFixed(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildVoucherHistory() {
    if (_brokerVouchers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Center(
          child: Text(
            'ဤပွဲစားတွင် ဘောင်ချာမှတ်တမ်း မရှိသေးပါ။',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // Group vouchers by voucherId to get unique vouchers
    final voucherMap = <String, BrokerConsignment>{};
    for (final consignment in _brokerVouchers) {
      if (consignment.voucherId != null &&
          consignment.voucherId!.isNotEmpty) {
        if (!voucherMap.containsKey(consignment.voucherId)) {
          voucherMap[consignment.voucherId!] = consignment;
        }
      }
    }

    final uniqueVouchers = voucherMap.values.toList();
    if (uniqueVouchers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Center(
          child: Text(
            'ဘောင်ချာမှတ်တမ်း မရှိသေးပါ။',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: uniqueVouchers.length,
      itemBuilder: (context, index) {
        final voucher = uniqueVouchers[index];
        // Calculate totals for this voucher
        final voucherItems = _brokerVouchers
            .where((c) => c.voucherId == voucher.voucherId)
            .toList();
        double totalItems = 0;
        double totalRemaining = 0;
        for (final item in voucherItems) {
          totalItems += item.consignedQuantity;
          totalRemaining += item.remainingQuantity;
        }

        return GestureDetector(
          onTap: () {
            if (voucher.id.isNotEmpty) {
              context.push('/broker-consignment/${voucher.id}');
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        voucher.voucherNumber ?? 'N/A',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _dateFormat.format(
                          DateTime.fromMillisecondsSinceEpoch(voucher.createdAt),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'စုစုပေါင်းအလုံးရေ',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          Text(
                            totalItems.toStringAsFixed(2),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'လက်ကျန်အလုံးရေ',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          Text(
                            totalRemaining.toStringAsFixed(2),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: totalRemaining > 0
                              ? Colors.orange[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          totalRemaining > 0 ? 'လုပ်ဆောင်ခြင်း' : 'ပြီးစီး',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: totalRemaining > 0
                                    ? Colors.orange[900]
                                    : Colors.green[900],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
