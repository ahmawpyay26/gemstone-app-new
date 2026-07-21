import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gemstone_management/core/local/local_db.dart';
import 'package:gemstone_management/core/local/models.dart';
import 'package:gemstone_management/features/sales/domain/broker_sales_business_logic.dart';
import 'package:gemstone_management/core/theme/app_theme.dart';
import 'dart:io';

/// Refactored Broker Sales Form with Draft → Final Save Architecture
class BrokerSaleForm extends StatefulWidget {
  const BrokerSaleForm({Key? key}) : super(key: key);

  @override
  State<BrokerSaleForm> createState() => _BrokerSaleFormState();
}

class _BrokerSaleFormState extends State<BrokerSaleForm> {
  // Form Controllers
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _commissionController;
  late TextEditingController _buyerNameController;
  late TextEditingController _remarkController;
  late TextEditingController _customerNameController;

  // State Variables
  DateTime _selectedSaleDate = DateTime.now();
  BrokerProfile? _selectedBroker;
  BrokerConsignment? _selectedConsignment;
  String _selectedSourceType = 'whole_stone';
  List<String> _selectedPhotos = [];
  List<DraftBrokerSaleItem> _draftItems = []; // Using DraftBrokerSaleItem from business logic
  String _selectedUnit = 'ပိသာ'; // Default unit
  late TextEditingController _weightController;
  late TextEditingController _sellingPriceController;

  // Validation Errors
  String? _quantityError;
  String? _priceError;
  String? _commissionError;
  
  // Duplicate-save protection
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _unitPriceController = TextEditingController();
    _commissionController = TextEditingController();
    _buyerNameController = TextEditingController();
    _remarkController = TextEditingController();
    _customerNameController = TextEditingController();
    _weightController = TextEditingController();
    _sellingPriceController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitPriceController.dispose();
    _commissionController.dispose();
    _buyerNameController.dispose();
    _remarkController.dispose();
    _customerNameController.dispose();
    _weightController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  /// Reset form fields after adding item to draft
  void _resetFormFields() {
    setState(() {
      _quantityController.clear();
      _unitPriceController.clear();
      _commissionController.clear();
      _buyerNameController.clear();
      _remarkController.clear();
      _weightController.clear();
      _sellingPriceController.clear();
      _selectedPhotos = [];
      _selectedConsignment = null;
      _quantityError = null;
      _priceError = null;
      _commissionError = null;
      _selectedUnit = 'ပိသာ';
    });
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedPhotos.add(image.path);
        });
        _showSuccess('ဓါတ်ပုံ ကင်မရာမှ ထည့်သွင်းပြီးပါပြီ။');
      }
    } catch (e) {
      _showError('ကင်မရာ အမှားအယွင်း: $e');
    }
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedPhotos.addAll(images.map((img) => img.path).toList());
        });
        _showSuccess('ဓါတ်ပုံ ${images.length} ခု ပြခန်းမှ ထည့်သွင်းပြီးပါပြီ။');
      }
    } catch (e) {
      _showError('ပြခန်း အမှားအယွင်း: $e');
    }
  }

  /// Remove photo from selected photos
  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
    _showSuccess('ဓါတ်ပုံ ဖျက်ပြီးပါပြီ။');
  }

  /// Get broker consignments for selected broker
  List<BrokerConsignment> _getBrokerConsignments() {
    if (_selectedBroker == null) return [];
    
    final box = LocalDb.brokerConsignments();
    final allConsignments = box.values.toList();
    
    return allConsignments.where((c) {
      final matchById = c.brokerProfileId == _selectedBroker!.id;
      final matchByName = c.brokerProfileId == null && c.brokerName == _selectedBroker!.name;
      return (matchById || matchByName) && c.isActive && c.remainingQuantity > 0;
    }).toList();
  }

  /// Validate and add item to draft
  Future<void> _addItemToDraft() async {
    // Validate consignment selection
    final consignmentValidation =
        BrokerSalesBusinessLogic.validateConsignmentSelection(_selectedConsignment);
    if (!consignmentValidation.isValid) {
      _showError(consignmentValidation.errorMessage!);
      return;
    }

    // Validate quantity
    final quantityValidation = BrokerSalesBusinessLogic.validateSoldQuantity(
      _quantityController.text,
      _selectedConsignment,
    );
    if (!quantityValidation.isValid) {
      _showError(quantityValidation.errorMessage!);
      return;
    }

    // Validate selling price
    final priceValidation =
        BrokerSalesBusinessLogic.validateUnitPrice(_sellingPriceController.text);
    if (!priceValidation.isValid) {
      _showError(priceValidation.errorMessage!);
      return;
    }

    // Validate commission
    final commissionValidation =
        BrokerSalesBusinessLogic.validateCommission(_commissionController.text);
    if (!commissionValidation.isValid) {
      _showError(commissionValidation.errorMessage!);
      return;
    }

    // Validate source type compatibility
    final sourceTypeValidation = BrokerSalesBusinessLogic.validateSourceType(
      _selectedConsignment!,
      _selectedSourceType,
    );
    if (!sourceTypeValidation.isValid) {
      _showError(sourceTypeValidation.errorMessage!);
      return;
    }

    // Validate broker remaining quantity
    final quantity = double.parse(_quantityController.text);
    final brokerValidation =
        BrokerSalesBusinessLogic.validateBrokerRemaining(_selectedConsignment!, quantity);
    if (!brokerValidation.isValid) {
      _showError(brokerValidation.errorMessage!);
      return;
    }

    // Create draft item
    final draftItem = BrokerSalesBusinessLogic.createDraftItem(
      consignment: _selectedConsignment!,
      quantity: quantity,
      unitPrice: double.parse(_sellingPriceController.text),
      commission: double.tryParse(_commissionController.text) ?? 0,
      buyerName: null,
      remark: _remarkController.text.trim(),
      saleDate: _selectedSaleDate,
      photoUrls: _selectedPhotos,
    );

    // Add to draft list
    setState(() {
      _draftItems.add(draftItem);
    });

    _showSuccess('ပစ္စည်းကို Draft စာရင်းထဲ ထည့်သွင်းပြီးပါပြီ။');
    _resetFormFields();
  }

  /// Remove item from draft
  void _removeItemFromDraft(int index) {
    setState(() {
      _draftItems.removeAt(index);
    });
    _showSuccess('ပစ္စည်းကို Draft စာရင်းမှ ဖျက်ပြီးပါပြီ။');
  }

  /// Edit item in draft
  void _editItemInDraft(int index) {
    final item = _draftItems[index];
    setState(() {
      _selectedConsignment = item.brokerConsignment;
      _selectedSourceType = item.brokerConsignment.historicalData.sourceType;
      _quantityController.text = item.soldQuantity.toString();
      _unitPriceController.text = item.unitPrice.toString();
      _commissionController.text = item.commission.toString();
      _buyerNameController.text = item.buyerName ?? '';
      _remarkController.text = item.remark;
      _selectedSaleDate = item.saleDate;
      _selectedPhotos = item.photoUrls;
      _draftItems.removeAt(index);
    });
    _showSuccess('ပစ္စည်းကို ပြင်ဆင်ရန် အသင့်ဖြစ်ပါပြီ။');
  }

  /// Commit all draft items to database
  Future<void> _commitDraftItems() async {
    // Prevent duplicate saves
    if (_isSaving) {
      _showError('ရောင်းချမှု သိမ်းဆည်းမှု ပြီးစီးခြင်းအတွင်းရှိသည်။');
      return;
    }
    
    if (_draftItems.isEmpty) {
      _showError('ရောင်းချမည့်ပစ္စည်း မရှိပါ။');
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      await BrokerSalesBusinessLogic.commitDraftItems(
        draftItems: _draftItems,
        customerName: _customerNameController.text.trim().isNotEmpty
            ? _customerNameController.text.trim()
            : null,
        invoiceDate: DateTime.now(),
      );

      _showSuccess('ရောင်းချမှု သိမ်းဆည်းပြီးပါပြီ။');
      
      // Clear draft state
      setState(() {
        _draftItems = [];
        _isSaving = false;
      });
      
      // Refresh parent Sales page by popping with result
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Navigator.pop(context, true); // Return true to signal refresh
        });
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('အမှားအယွင်း: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brokerConsignmentsBox = Hive.box<BrokerConsignment>('brokerConsignments');
    final brokerConsignments = brokerConsignmentsBox.values
        .where((c) => c.remainingQuantity > 0)
        .where((c) => c.historicalData.sourceType == _selectedSourceType)
        .where((c) {
          if (_selectedBroker == null) return false;
          final matchById = c.brokerProfileId == _selectedBroker!.id;
          final matchByName = c.brokerProfileId == null && c.brokerName == _selectedBroker!.name;
          return matchById || matchByName;
        })
        .toList();

    final draftSummary = DraftSummary.fromItems(_draftItems);

    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ပွဲစားထံမှ ရောင်းချမှု',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 1: Sale Date
            Text(
              'ရောင်းချသည့်နေ့စွဲ',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedSaleDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedSaleDate = date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_selectedSaleDate)),
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: Customer Name
            Text(
              'ဝယ်ယူသူအမည်',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: 'ဝယ်ယူသူအမည် (ရွေးချယ်ခွင့်)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // Section 2.5: Broker Selection
            Text(
              'ပွဲစားအမည်',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: Hive.box<BrokerProfile>(LocalDb.brokerProfilesBox).listenable(),
              builder: (context, box, _) {
                final brokers = box.values.where((b) => !b.isDeleted).toList();
                return DropdownButtonFormField<BrokerProfile>(
                  value: _selectedBroker,
                  isExpanded: true,
                  dropdownColor: AppTheme.surfaceDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'ပွဲစားရွေးချယ်ပါ',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryAccent),
                    ),
                    filled: true,
                    fillColor: Colors.grey[900],
                  ),
                  items: brokers
                      .map((broker) => DropdownMenuItem(
                            value: broker,
                            child: Text(broker.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBroker = value;
                      _selectedConsignment = null;
                      _selectedSourceType = 'whole_stone';
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Section 3: Broker Items
            Text(
              'ပွဲစားထံမှ ကျောက်ထည့်သွင်းခြင်း',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryAccent, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[900],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source Type Toggle
                  Text(
                    'အရင်းအမြစ်အမျိုးအစား',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'whole_stone',
                        label: Text('အပြည့်အစုံ'),
                      ),
                      ButtonSegment<String>(
                        value: 'breakdown_item',
                        label: Text('အခွဲ'),
                      ),
                    ],
                    selected: <String>{_selectedSourceType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedSourceType = newSelection.first;
                        _selectedConsignment = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Gemstone Selection
                  DropdownButtonFormField<BrokerConsignment>(
                    value: _selectedConsignment,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'ကျောက်ရွေးချယ်ပါ',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryAccent),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                    ),
                    items: brokerConsignments
                        .map((consignment) {
                          final gemstone = LocalDb.gemstoneById(consignment.purchaseId);
                          final gemstoneName = gemstone?.name ?? 'Unknown';
                          final sourceTypeLabel =
                              consignment.historicalData.sourceType == 'whole_stone'
                                  ? 'အပ်စာရင်း'
                                  : 'အတွက်';
                          final remainingQty = consignment.remainingQuantity;

                          return DropdownMenuItem(
                            value: consignment,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  gemstoneName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  'အရေအတွက်: $remainingQty',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedConsignment = value);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Quantity with Remaining Quantity Display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Remaining Quantity Display (Read-only)
                      if (_selectedConsignment != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[600]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[900],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ကျန်ရှိ အရေအတွက်:',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${_selectedConsignment!.remainingQuantity}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Quantity Input Field
                      TextField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'ရောင်းချမည့် အရေအတွက်',
                          hintText: 'အပ်စာရင်းမှ ရောင်းချမည့် အရေအတွက် ထည့်သွင်းပါ',
                          errorText: _quantityError,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[800],
                        ),
                        onChanged: (value) {
                          final validation = BrokerSalesBusinessLogic.validateSoldQuantity(
                            value,
                            _selectedConsignment,
                          );
                          setState(() =>
                              _quantityError = validation.isValid ? null : validation.errorMessage);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Selling Price
                  TextField(
                    controller: _sellingPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'ရောင်းချမည့်ဈေး',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Weight and Unit Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'အလေးချိန်',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: InputDecoration(
                            labelText: 'ယူနစ်',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.grey[900],
                          ),
                          dropdownColor: AppTheme.surfaceDark,
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(value: 'ပိသာ', child: Text('ပိသာ')),
                            DropdownMenuItem(value: 'ကျပ်သား', child: Text('ကျပ်သား')),
                            DropdownMenuItem(value: 'ကာရက်', child: Text('ကာရက်')),
                            DropdownMenuItem(value: 'kg', child: Text('ကီလို (kg)')),
                            DropdownMenuItem(value: 'g', child: Text('ဂရမ် (g)')),
                            DropdownMenuItem(value: 'lb', child: Text('ပေါင် (lb)')),
                            DropdownMenuItem(value: 'oz', child: Text('အောင်စ (oz)')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedUnit = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Commission
                  TextField(
                    controller: _commissionController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'ကော်မရှင် (ရွေးချယ်ခွင့်)',
                      errorText: _commissionError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (value) {
                      final validation = BrokerSalesBusinessLogic.validateCommission(value);
                      setState(() => _commissionError =
                          validation.isValid ? null : validation.errorMessage);
                    },
                  ),
                  const SizedBox(height: 12),



                  // Remark
                  TextField(
                    controller: _remarkController,
                    decoration: InputDecoration(
                      labelText: 'မှတ်ချက်',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),

                  // Photo Gallery Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[700]!, width: 1),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[900],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ဓါတ်ပုံမှတ်တမ်း',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickImageFromCamera,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('ကင်မရာ'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[800],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickImageFromGallery,
                                icon: const Icon(Icons.image),
                                label: const Text('ပြခန်း'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[800],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedPhotos.isNotEmpty) ...
                          [
                            const SizedBox(height: 12),
                            Text(
                              'မြတေဒဓုတေတေဒ်တြတက် ဓါတ်ပုံမှတ် (${_selectedPhotos.length})',
                              style: TextStyle(color: Colors.grey[400], fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _selectedPhotos.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_selectedPhotos[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removePhoto(index),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ]
                        else
                          ...
                            [
                              const SizedBox(height: 8),
                              Text(
                                'ဓါတ်ပုံမှတ်မြတေဒ်တြတက်တေတေဒ်း',
                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                              ),
                            ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Add Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addItemToDraft,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('ထည့်မည်'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section 6: Draft Items List
            if (_draftItems.isNotEmpty) ...[
              Text(
                'ရောင်းချမည့်ပစ္စည်းစာရင်း',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              ..._draftItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.gemstoneName} • ${item.sourceTypeLabel}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'အရေအတွက်: ${item.soldQuantity} | စျေးနှုန်း: ${item.unitPrice}',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'စုစုပေါင်း: ${item.totalSaleAmount} | ကော်မရှင်: ${item.commission}',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _editItemInDraft(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                  onPressed: () => _removeItemFromDraft(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),

              // Draft Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryAccent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Draft အကျဉ်းချုပ်',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ပစ္စည်းအရေအတွက်: ${draftSummary.itemCount}'),
                        Text('စုစုပေါင်းအရေအတွက်: ${draftSummary.totalQuantity}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('စုစုပေါင်းရောင်းချမှု: ${draftSummary.totalSaleAmount}'),
                        Text('စုစုပေါင်းကော်မရှင်: ${draftSummary.totalCommission}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'စုစုပေါင်းသုံးခြင်း: ${draftSummary.totalNetAmount}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Section 7: Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _draftItems.isEmpty ? null : _commitDraftItems,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  disabledBackgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'ရောင်းချမည်',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
