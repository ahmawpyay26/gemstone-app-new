import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/models.dart';
import '../../../../shared/widgets/photo_count_badge.dart';

/// Phase C.2: Expandable Voucher Group Card
/// Displays grouped broker consignments with collapsible items
class VoucherGroupCard extends StatefulWidget {
  final String groupKey; // voucherId or record ID for legacy
  final List<BrokerConsignment> items;
  final Map<String, dynamic> summary;
  final bool isLegacy;
  
  // Callbacks for item-level actions
  final Function(BrokerConsignment)? onViewPhotos;
  final Function(BrokerConsignment)? onEdit;
  final Function(BrokerConsignment)? onDelete;
  final Function(BrokerConsignment)? onReturn;
  final Function(BrokerConsignment)? onSale;
  
  // Callbacks for voucher-level actions
  final Function()? onViewAllPhotos;
  final Function()? onPrint;
  final Function()? onExport;

  const VoucherGroupCard({
    Key? key,
    required this.groupKey,
    required this.items,
    required this.summary,
    this.isLegacy = false,
    this.onViewPhotos,
    this.onEdit,
    this.onDelete,
    this.onReturn,
    this.onSale,
    this.onViewAllPhotos,
    this.onPrint,
    this.onExport,
  }) : super(key: key);

  @override
  State<VoucherGroupCard> createState() => _VoucherGroupCardState();
}

class _VoucherGroupCardState extends State<VoucherGroupCard> {
  late bool _isExpanded;
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isLegacy; // Legacy records start expanded
  }

  String _getStatusColor(String status) {
    switch (status) {
      case 'ပြီးစီး':
        return '🟢';
      case 'တစ်စိတ်တစ်ပိုင်း ပြန်လည်အပ်':
        return '🟠';
      case 'လုပ်ဆောင်ဆဲ':
        return '🔵';
      default:
        return '⚪';
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'ပြီးစီး':
        return Colors.green.withOpacity(0.2);
      case 'တစ်စိတ်တစ်ပိုင်း ပြန်လည်အပ်':
        return Colors.orange.withOpacity(0.2);
      case 'လုပ်ဆောင်ဆဲ':
        return AppTheme.primaryAccent.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'ပြီးစီး':
        return Colors.green;
      case 'တစ်စိတ်တစ်ပိုင်း ပြန်လည်အပ်':
        return Colors.orange;
      case 'လုပ်ဆောင်ဆဲ':
        return AppTheme.primaryAccent;
      default:
        return Colors.grey;
    }
  }

  void _showVoucherMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: AppTheme.surfaceDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryAccent),
              title: const Text('ဓာတ်ပုံများ အားလုံး ကြည့်ရန်'),
              onTap: () {
                Navigator.pop(context);
                widget.onViewAllPhotos?.call();
              },
            ),
            if (widget.onPrint != null)
              ListTile(
                leading: const Icon(Icons.print, color: AppTheme.primaryAccent),
                title: const Text('ပုံနှိပ်ရန်'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onPrint?.call();
                },
              ),
            if (widget.onExport != null)
              ListTile(
                leading: const Icon(Icons.download, color: AppTheme.primaryAccent),
                title: const Text('PDF အဖြင့် တင်ပို့ရန်'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onExport?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showItemMenu(BuildContext context, BrokerConsignment item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: AppTheme.surfaceDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryAccent),
              title: const Text('ဓာတ်ပုံများ ကြည့်ရန်'),
              onTap: () {
                Navigator.pop(context);
                widget.onViewPhotos?.call(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryAccent),
              title: const Text('ပြင်ဆင်ရန်'),
              onTap: () {
                Navigator.pop(context);
                widget.onEdit?.call(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: AppTheme.primaryAccent),
              title: const Text('ရောင်းချမည်'),
              onTap: () {
                Navigator.pop(context);
                widget.onSale?.call(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.undo, color: AppTheme.primaryAccent),
              title: const Text('ပြန်လည်လက်ခံမည်'),
              onTap: () {
                Navigator.pop(context);
                widget.onReturn?.call(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('ဖျက်ရန်', style: TextStyle(color: AppTheme.errorColor)),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete?.call(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.summary['status'] as String? ?? 'လုပ်ဆောင်ဆဲ';
    final totalConsigned = widget.summary['totalConsigned'] as double? ?? 0;
    final totalSold = widget.summary['totalSold'] as double? ?? 0;
    final totalReturned = widget.summary['totalReturned'] as double? ?? 0;
    final totalRemaining = widget.summary['totalRemaining'] as double? ?? 0;
    final itemCount = widget.summary['itemCount'] as int? ?? 0;
    final brokerName = widget.summary['brokerName'] as String? ?? 'Unknown';
    final createdAt = widget.summary['createdAt'] as int? ?? 0;
    final voucherNumber = widget.summary['voucherNumber'] as String?;

    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Voucher Header (Collapsed View)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Voucher Number and Broker Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (voucherNumber != null)
                              Text(
                                '🎫 $voucherNumber',
                                style: const TextStyle(
                                  color: AppTheme.primaryAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              brokerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _dateFormat.format(
                              DateTime.fromMillisecondsSinceEpoch(createdAt),
                            ),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusBgColor(status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_getStatusColor(status)} $status',
                              style: TextStyle(
                                color: _getStatusTextColor(status),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Row 2: Summary Totals
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          '📦 အရေအတွက်',
                          itemCount.toString(),
                          isSmall: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryItem(
                          '🔢 အပ်ထား',
                          totalConsigned.toStringAsFixed(0),
                          isSmall: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryItem(
                          '💰 ရောင်းပြီး',
                          totalSold.toStringAsFixed(0),
                          isSmall: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryItem(
                          '📥 ပြန်ရရှိ',
                          totalReturned.toStringAsFixed(0),
                          isSmall: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryItem(
                          '📦 ကျန်',
                          totalRemaining.toStringAsFixed(0),
                          isSmall: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Row 3: Expand/Collapse and Menu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppTheme.primaryAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isExpanded ? 'အကျုံးဝင်' : 'ချဲ့ရန်',
                            style: const TextStyle(
                              color: AppTheme.primaryAccent,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          PhotoCountBadge(
                            count: widget.items.fold<int>(
                              0,
                              (sum, item) => sum + (item.photoPaths?.length ?? 0),
                            ),
                            fontSize: 11,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        color: AppTheme.primaryAccent,
                        onPressed: () => _showVoucherMenu(context),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expanded Items List
          if (_isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[800]!,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < widget.items.length; i++) ...[
                    VoucherItemRow(
                      item: widget.items[i],
                      onViewPhotos: () => widget.onViewPhotos?.call(widget.items[i]),
                      onEdit: () => widget.onEdit?.call(widget.items[i]),
                      onDelete: () => widget.onDelete?.call(widget.items[i]),
                      onReturn: () => widget.onReturn?.call(widget.items[i]),
                      onSale: () => widget.onSale?.call(widget.items[i]),
                      onMenu: () => _showItemMenu(context, widget.items[i]),
                    ),
                    if (i < widget.items.length - 1)
                      Divider(
                        color: Colors.grey[800],
                        height: 1,
                        indent: 12,
                        endIndent: 12,
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isSmall = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: isSmall ? 10 : 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.primaryAccent,
            fontSize: isSmall ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Phase C.2: Individual Item Row within Voucher
class VoucherItemRow extends StatelessWidget {
  final BrokerConsignment item;
  final Function()? onViewPhotos;
  final Function()? onEdit;
  final Function()? onDelete;
  final Function()? onReturn;
  final Function()? onSale;
  final Function()? onMenu;

  const VoucherItemRow({
    Key? key,
    required this.item,
    this.onViewPhotos,
    this.onEdit,
    this.onDelete,
    this.onReturn,
    this.onSale,
    this.onMenu,
  }) : super(key: key);

  String _getItemStatus(BrokerConsignment bc) {
    if (bc.remainingQuantity == 0) {
      return 'အပြီးစီး';
    } else if (bc.returnedQuantity > 0) {
      return 'အခြေခံ ပြန်လည်လက်ခံ';
    } else {
      return 'လုပ်ဆောင်ခြင်းတွင်';
    }
  }

  Color _getItemStatusColor(BrokerConsignment bc) {
    if (bc.remainingQuantity == 0) {
      return Colors.green;
    } else if (bc.returnedQuantity > 0) {
      return Colors.orange;
    } else {
      return AppTheme.primaryAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gemName = item.historicalData.sourceType == 'breakdown_item'
        ? item.historicalData.breakdownItemName
        : item.historicalData.purchaseName;

    final weight = item.historicalData.originalWeight;
    final weightUnit = 'viss'; // Default unit from historical data
    final weightStr = weight != null && weight > 0
        ? ' ($weight $weightUnit)'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (gemName ?? 'Unknown') + (weightStr ?? ''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.photoPaths != null && item.photoPaths!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: PhotoCountBadge(count: item.photoPaths!.length, fontSize: 10),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getItemStatusColor(item).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getItemStatus(item),
                        style: TextStyle(
                          color: _getItemStatusColor(item),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                color: AppTheme.primaryAccent,
                onPressed: onMenu,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                iconSize: 18,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Quantities Row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildQuantityBadge('🔢 အပ်', item.consignedQuantity.toStringAsFixed(0)),
              _buildQuantityBadge('💰 ရောင်း', item.soldQuantity.toStringAsFixed(0)),
              _buildQuantityBadge('📥 ပြန်', item.returnedQuantity.toStringAsFixed(0)),
              _buildQuantityBadge('📦 ကျန်', item.remainingQuantity.toStringAsFixed(0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 9,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primaryAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Phase C.2: Legacy Single-Item Voucher Card
/// Used for records with null voucherId
class LegacyVoucherCard extends StatelessWidget {
  final BrokerConsignment item;
  final Function()? onViewPhotos;
  final Function()? onEdit;
  final Function()? onDelete;
  final Function()? onReturn;
  final Function()? onSale;
  final Function()? onMenu;

  const LegacyVoucherCard({
    Key? key,
    required this.item,
    this.onViewPhotos,
    this.onEdit,
    this.onDelete,
    this.onReturn,
    this.onSale,
    this.onMenu,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Wrap single legacy item in VoucherGroupCard format
    final summary = {
      'totalConsigned': item.consignedQuantity,
      'totalSold': item.soldQuantity,
      'totalReturned': item.returnedQuantity,
      'totalRemaining': item.remainingQuantity,
      'itemCount': 1,
      'status': item.remainingQuantity == 0
          ? 'Completed'
          : item.returnedQuantity > 0
              ? 'Partial Return'
              : 'Active',
      'brokerName': item.brokerName,
      'createdAt': item.createdAt,
      'voucherId': null,
      'voucherNumber': null,
      'isLegacy': true,
    };

    return VoucherGroupCard(
      groupKey: item.id,
      items: [item],
      summary: summary,
      isLegacy: true,
      onViewPhotos: (_) => onViewPhotos?.call(),
      onEdit: (_) => onEdit?.call(),
      onDelete: (_) => onDelete?.call(),
      onReturn: (_) => onReturn?.call(),
      onSale: (_) => onSale?.call(),
    );
  }
}
