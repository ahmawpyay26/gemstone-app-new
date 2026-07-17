import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:printing/printing.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../../broker_consignment/domain/builders/broker_voucher_document_builder.dart';
import '../../../broker_consignment/domain/services/broker_voucher_export_service.dart';
import '../../../broker_consignment/domain/services/broker_voucher_image_exporter.dart';
import '../widgets/photo_gallery_viewer.dart';

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

  void _showVoucherEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ဘောင်ချာပြုပြင်ရန်'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ဘောင်ချာနို့: ${widget.voucherNumber}'),
              const SizedBox(height: 8),
              Text('အပ်ထားသည့်ခုနှုန်း: ${widget.items.length}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'သတိ: ဘောင်ချာသည်ပြီးသားမရပါ။ ဤ အပ်ထားသည့်ခုနှုန်းသည် ပြီးသားမရပါ။',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('မပြုပြင်တော့ပါ'),
            ),
          ],
        );
      },
    );
  }

  void _showVoucherPhotoViewer(BuildContext context) {
    // Get all photos from items in this voucher
    final allPhotos = <String>[];
    for (final item in widget.items) {
      if (item.photoPaths != null && item.photoPaths!.isNotEmpty) {
        allPhotos.addAll(item.photoPaths!);
      }
    }

    if (allPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ဓာတ်ပုံ မရှိပါ။')),
      );
      return;
    }

    // Open full-screen gallery
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoGalleryViewer(
          photoPaths: allPhotos,
          title: 'ဘောင်ချာ ဓာတ်ပုံများ - ${widget.voucherNumber}',
        ),
      ),
    );
  }

  void _showVoucherDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ဘောင်ချာဖျက်မည်သည်'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ဤ ဘောင်ချာကို ဖျက်ရန် သေချာပါသလား?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'သတိ: ဘောင်ချာသည် လက်ကျန်ခုနှုန်း မရပါသား ဖျက်လို့ မရပါ။',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('မဖျက်တော့ပါ'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Delete all items in this voucher
                  final brokers = Hive.box<BrokerConsignment>('broker_consignments');
                  for (final item in widget.items) {
                    await brokers.delete(item.id);
                  }

                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ဘောင်ချာ အောင်မြင်စွာ ဖျက်ပြီးပါပြီ'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Trigger parent refresh
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('အမှားအယွင်း: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('ဖျက်မည်'),
            ),
          ],
        );
      },
    );
  }

  void _handleVoucherMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _showVoucherEditDialog(context);
        break;
      case 'delete':
        _showVoucherDeleteConfirmation(context);
        break;
      case 'print':
        _handlePrintAction(context);
        break;
      case 'image':
        _handleImageExportAction(context);
        break;
      case 'pdf':
        _handlePdfExportAction(context);
        break;
      case 'photos':
        _showVoucherPhotoViewer(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalConsigned = 0;
    double totalSold = 0;
    double totalReturned = 0;
    double totalRemaining = 0;

    for (final item in widget.items) {
      totalConsigned += item.consignedQuantity;
      totalSold += item.soldQuantity;
      totalReturned += item.returnedQuantity;
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
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    _handleVoucherMenuAction(context, value);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('ဘောင်ချာပြုပြင်ရန်'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('ဘောင်ချာဖျက်ရန်'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'print',
                      child: Row(
                        children: [
                          Icon(Icons.print, size: 20),
                          SizedBox(width: 8),
                          Text('ပရင့်ထုတ်ရန်'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'image',
                      child: Row(
                        children: [
                          Icon(Icons.image, size: 20),
                          SizedBox(width: 8),
                          Text('ပုံထုတ်ရန်'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, size: 20),
                          SizedBox(width: 8),
                          Text('PDF ထုတ်ရန်'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'photos',
                      child: Row(
                        children: [
                          Icon(Icons.photo_library, size: 20),
                          SizedBox(width: 8),
                          Text('ဓာတ်ပုံကြည့်ရန်'),
                        ],
                      ),
                    ),
                  ],
                ),
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
                  _SummaryRow('စုစုပေါင်းအပ်ထားသည့်ခုနှုန်း', totalConsigned.toStringAsFixed(2)),
                  _SummaryRow('စုစုပေါင်းရောင်းချ', totalSold.toStringAsFixed(2)),
                  _SummaryRow('စုစုပေါင်းပြန်လည်ရယူ', totalReturned.toStringAsFixed(2)),
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
                    return _ItemCard(
                      itemIndex: idx,
                      item: item,
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handlePdfExportAction(BuildContext context) async {
    try {
      // Show loading dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'PDF ပြင်ဆင်နေသည်...',
                  style: TextStyle(fontFamily: 'Padauk'),
                ),
              ],
            ),
          ),
        ),
      );

      // Build document data
      final documentData = BrokerVoucherDocumentBuilder.buildFromVoucher(
        voucherItems: widget.items,
        voucherNumber: widget.voucherNumber,
        voucherDate: widget.items.first.createdAt,
      );

      // Export PDF
      final success = await BrokerVoucherExportService.exportPdfAndShare(documentData);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF သိမ်းဆည်းပြီးပါပြီ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF သိမ်းဆည်းရန် ပരिवर्तन ဖြစ်ခဲ့သည်')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('အမှားအယွင်း: ${e.toString()}')),
      );
    }
  }

  Future<void> _handlePrintAction(BuildContext context) async {
    try {
      // Build document data
      final documentData = BrokerVoucherDocumentBuilder.buildFromVoucher(
        voucherItems: widget.items,
        voucherNumber: widget.voucherNumber,
        voucherDate: widget.items.first.createdAt,
      );

      // Get PDF bytes
      final pdfBytes = await BrokerVoucherExportService.getPdfBytes(documentData);

      // Open print preview
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'ပွဲစားအပ်နှံဘောင်ချာ-${widget.voucherNumber}',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ပရင့်ထုတ်ရန် အမှားအယွင်း: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleImageExportAction(BuildContext context) async {
    try {
      // Show loading dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'ပုံ ပြင်ဆင်နေသည်...',
                  style: TextStyle(fontFamily: 'Padauk'),
                ),
              ],
            ),
          ),
        ),
      );

      // Build document data
      final documentData = BrokerVoucherDocumentBuilder.buildFromVoucher(
        voucherItems: widget.items,
        voucherNumber: widget.voucherNumber,
        voucherDate: widget.items.first.createdAt,
      );

      // Export image
      final success = await BrokerVoucherImageExporter.exportImageAndShare(
        documentData,
        context,
      );

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ပုံ သိမ်းဆည်းပြီးပါပြီ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ပုံ သိမ်းဆည်းရန် ပരिवर्तन ဖြစ်ခဲ့သည်')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('အမှားအယွင်း: ${e.toString()}')),
      );
    }
  }
}

class _ItemCard extends StatefulWidget {
  final int itemIndex;
  final BrokerConsignment item;

  const _ItemCard({
    required this.itemIndex,
    required this.item,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  void _showItemEditDialog(BuildContext context) {
    final consignedController = TextEditingController(
      text: widget.item.consignedQuantity.toString(),
    );
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Item ပြုပြင်ရန်'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ယခင်အပ်ထားသည့်ခုနှုန်း: ${widget.item.consignedQuantity}'),
                    Text('ရောင်းချ: ${widget.item.soldQuantity}'),
                    Text('ပြန်လည်ရယူ: ${widget.item.returnedQuantity}'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: consignedController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'အပ်ထားသည့်ခုနှုန်း (အသစ်)',
                        hintText: '0.00',
                        errorText: errorMessage,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'သတိ: အပ်ထားသည့်ခုနှုန်းသည် ရောင်းချ + ပြန်လည်ရယူ ထက် ကြီးရမည်။',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('မပြုပြင်တော့ပါ'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newConsignedStr = consignedController.text.trim();
                    if (newConsignedStr.isEmpty) {
                      setState(() {
                        errorMessage = 'ခုနှုန်းထည့်သွင်းပါ';
                      });
                      return;
                    }

                    final newConsigned = double.tryParse(newConsignedStr);
                    if (newConsigned == null || newConsigned <= 0) {
                      setState(() {
                        errorMessage = 'ခုနှုန်းသည် သုည ထက် ကြီးရမည်';
                      });
                      return;
                    }

                    final totalUsed = widget.item.soldQuantity + widget.item.returnedQuantity;
                    if (newConsigned < totalUsed) {
                      setState(() {
                        errorMessage = 'အပ်ထားသည့်ခုနှုန်းသည် ရောင်းချ + ပြန်လည်ရယူ (${totalUsed.toStringAsFixed(2)}) ထက် ကြီးရမည်';
                      });
                      return;
                    }

                    try {
                      widget.item.consignedQuantity = newConsigned;
                      final brokers = Hive.box<BrokerConsignment>('broker_consignments');
                      await brokers.put(widget.item.id, widget.item);

                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Item အောင်မြင်စွာ ပြုပြင်ပြီးပါပြီ'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Trigger parent refresh
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        }
                      }
                    } catch (e) {
                      setState(() {
                        errorMessage = e.toString();
                      });
                    }
                  },
                  child: const Text('ပြုပြင်မည်'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showItemDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Item ဖျက်မည်သည်'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ဤ Item ကို ဖျက်ရန် သေချာပါသလား?'),
              const SizedBox(height: 16),
              if (widget.item.soldQuantity > 0)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'သတိ: ဤ Item သည် ရောင်းချပြီးသားဖြစ်သည်။ ဖျက်လို့ မရပါ။',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'သတိ: ဖျက်ပြီးသည်နောက် ပြန်လည်ရယူ၍ မရပါ။',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('မဖျက်တော့ပါ'),
            ),
            if (widget.item.soldQuantity == 0)
              ElevatedButton(
                onPressed: () async {
                  try {
                    final brokers = Hive.box<BrokerConsignment>('broker_consignments');
                    await brokers.delete(widget.item.id);

                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Item အောင်မြင်စွာ ဖျက်ပြီးပါပြီ'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Trigger parent refresh
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      }
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('အမှားအယွင်း: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('ဖျက်မည်'),
              ),
          ],
        );
      },
    );
  }

  void _showItemReturnDialog(BuildContext context) {
    final returnController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('ပစ္စည်းပြန်အပ်ရန်'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('အပ်ထားသည့်ခုနှုန်း: ${widget.item.consignedQuantity}'),
                    Text('ရောင်းချ: ${widget.item.soldQuantity}'),
                    Text('ယခင်ပြန်လည်ရယူ: ${widget.item.returnedQuantity}'),
                    Text('လက်ကျန်ခုနှုန်း: ${widget.item.remainingQuantity}'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: returnController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'ပြန်လည်ရယူမည့်ခုနှုန်း',
                        hintText: '0.00',
                        errorText: errorMessage,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'မှတ်ချက် (ရွေးချယ်ခွင့်)',
                        hintText: 'ပြန်လည်ရယူရခြင်းအကြောင်း မှတ်ချက်',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('မပြန်အပ်တော့ပါ'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final returnQtyStr = returnController.text.trim();
                    if (returnQtyStr.isEmpty) {
                      setState(() {
                        errorMessage = 'ခုနှုန်းထည့်သွင်းပါ';
                      });
                      return;
                    }

                    final returnQty = double.tryParse(returnQtyStr);
                    if (returnQty == null || returnQty <= 0) {
                      setState(() {
                        errorMessage = 'ခုနှုန်းသည် သုည ထက် ကြီးရမည်';
                      });
                      return;
                    }

                    if (returnQty > widget.item.remainingQuantity) {
                      setState(() {
                        errorMessage = 'ပြန်လည်ရယူမည့်ခုနှုန်း လက်ကျန်ထက် မများရပါ';
                      });
                      return;
                    }

                    try {
                      await LocalDb.processBrokerReturn(
                        brokerConsignmentId: widget.item.id,
                        returnedQuantity: returnQty,
                      );

                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${returnQty.toStringAsFixed(2)} ခု ပြန်လည်ရယူခြင်း အောင်မြင်ပြီး'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Trigger parent refresh
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        }
                      }
                    } catch (e) {
                      setState(() {
                        errorMessage = e.toString();
                      });
                    }
                  },
                  child: const Text('ပြန်အပ်မည်'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleItemMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _showItemEditDialog(context);
        break;
      case 'delete':
        _showItemDeleteConfirmation(context);
        break;
      case 'return':
        _showItemReturnDialog(context);
        break;
      case 'photos':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ဓာတ်ပုံကြည့်ရန် - လုပ်ဆောင်နေသည်')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'အရေးအသား ${widget.itemIndex}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    _handleItemMenuAction(context, value);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Item ပြုပြင်ရန်'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Item ဖျက်ရန်'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'return',
                      child: Row(
                        children: [
                          Icon(Icons.undo, size: 20),
                          SizedBox(width: 8),
                          Text('ပစ္စည်းပြန်အပ်ရန်'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'photos',
                      child: Row(
                        children: [
                          Icon(Icons.photo_library, size: 20),
                          SizedBox(width: 8),
                          Text('ဓာတ်ပုံကြည့်ရန်'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('အပ်ထားသည့်ခုနှုန်း: ${widget.item.consignedQuantity}'),
            Text('ရောင်းချ: ${widget.item.soldQuantity}'),
            Text('ပြန်လည်ရယူ: ${widget.item.returnedQuantity}'),
            Text('ကျန်ရှိ: ${widget.item.remainingQuantity}'),
          ],
        ),
      ),
    );
  }

  Future<void> _handleItemPdfExportAction(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item PDF ထုတ်ရန် - လုပ်ဆောင်နေသည်')),
    );
  }

  Future<void> _handleItemPrintAction(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item ပရင့်ထုတ်ရန် - လုပ်ဆောင်နေသည်')),
    );
  }

  Future<void> _handleItemImageExportAction(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item ပုံထုတ်ရန် - လုပ်ဆောင်နေသည်')),
    );
  }

  void _showItemPhotoViewer(BuildContext context) {
    if (widget.item.photoPaths == null || widget.item.photoPaths!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ဓာတ်ပုံ မရှိပါ။')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoGalleryViewer(
          photoPaths: widget.item.photoPaths!,
          title: 'အရည်အသွေး ${widget.itemIndex + 1} ဓာတ်ပုံများ',
        ),
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

  void _handleVoucherMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ဘောင်ချာပြုပြင်ရန် - လုပ်ဆောင်နေသည်')),
        );
        break;
      case 'delete':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ဘောင်ချာဖျက်ရန် - လုပ်ဆောင်နေသည်')),
        );
        break;
      case 'print':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ပွဲစား ပရင့်ထုတ်ရန် - လုပ်ဆောင်နေသည်')),
        );
        break;
      case 'image':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ပွဲစား ပုံထုတ်ရန် - လုပ်ဆောင်နေသည်')),
        );
        break;
      case 'pdf':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ပွဲစား PDF ထုတ်ရန် - လုပ်ဆောင်နေသည်')),
        );
        break;
      case 'photos':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ပွဲစား ဓာတ်ပုံများ - လုပ်ဆောင်နေသည်')),
        );
        break;
    }
  }

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
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    _handleVoucherMenuAction(context, value);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('ဘောင်ချာပြုပြင်ရန်'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('ဘောင်ချာဖျက်ရန်'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'print',
                      child: Row(
                        children: [
                          Icon(Icons.print, size: 20),
                          SizedBox(width: 8),
                          Text('ပရင့်ထုတ်ရန်'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'image',
                      child: Row(
                        children: [
                          Icon(Icons.image, size: 20),
                          SizedBox(width: 8),
                          Text('ပုံထုတ်ရန်'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, size: 20),
                          SizedBox(width: 8),
                          Text('PDF ထုတ်ရန်'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'photos',
                      child: Row(
                        children: [
                          Icon(Icons.photo_library, size: 20),
                          SizedBox(width: 8),
                          Text('ဓာတ်ပုံကြည့်ရန်'),
                        ],
                      ),
                    ),
                  ],
                ),
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

// Photo Gallery Dialog Widget
class _PhotoGalleryDialog extends StatefulWidget {
  final List<String> photos;

  const _PhotoGalleryDialog({required this.photos});

  @override
  State<_PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();
}

class _PhotoGalleryDialogState extends State<_PhotoGalleryDialog> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: Text('ဓာတ်ပုံ (${_currentIndex + 1}/${widget.photos.length})'),
            automaticallyImplyLeading: true,
          ),
          Expanded(
            child: PageView.builder(
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.photos.length,
              itemBuilder: (context, index) {
                return Image.network(
                  widget.photos[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, size: 64),
                          const SizedBox(height: 8),
                          const Text('ဓာတ်ပုံ ဖွင့်မရပါ။'),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _currentIndex > 0
                      ? () {
                          setState(() {
                            _currentIndex--;
                          });
                        }
                      : null,
                  child: const Text('ယခင်'),
                ),
                ElevatedButton(
                  onPressed: _currentIndex < widget.photos.length - 1
                      ? () {
                          setState(() {
                            _currentIndex++;
                          });
                        }
                      : null,
                  child: const Text('နောက်'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Extension for export functionality
extension VoucherExport on _VoucherGroupCardState {
  void _handleVoucherPrint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ပရင့်ထုတ်ခြင်း - လုပ်ဆောင်နေသည်'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleVoucherImageExport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ပုံထုတ်ခြင်း - လုပ်ဆောင်နေသည်'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleVoucherPdfExport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF ထုတ်ခြင်း - လုပ်ဆောင်နေသည်'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
