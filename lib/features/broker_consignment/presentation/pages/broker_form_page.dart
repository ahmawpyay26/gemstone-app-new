import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/photo_viewer.dart';
import '../widgets/photo_media_box.dart';
import '../../domain/broker_consignment_validation.dart';
import '../../../../core/rca/rca_log_collector.dart';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/diagnostic_log_service.dart';

/// Extension method to add firstWhereOrNull to List
extension FirstWhereOrNullExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}

/// Temporary model for consignment items during form editing
class ConsignmentItemTemp {
  String id;
  Gemstone? gemstone;
  double consignedQuantity;
  String sourceType; // 'whole_stone' or 'breakdown_item'
  Gemstone? selectedPurchase; // For breakdown_item source type
  String? selectedBreakdownItem; // Selected breakdown item name
  Map<String, int> availableBreakdownItems; // Filtered breakdown items from purchase
  List<String> photoPaths; // Independent photo list for this item
  
  // Weight Tracking (NEW)
  double? weight; // Optional weight value
  String? weightUnit; // Unit of weight
  
  // Edit mode tracking
  String? originalBcId; // Original BrokerConsignment record ID (for updates)
  bool isNew; // true = new item, false = existing item
  bool isDeleted; // true = marked for deletion
  double originalQuantity; // Original consigned qty (for inventory delta)

  ConsignmentItemTemp({
    required this.id,
    this.gemstone,
    this.consignedQuantity = 0,
    this.sourceType = 'whole_stone',
    this.selectedPurchase,
    this.selectedBreakdownItem,
    this.availableBreakdownItems = const {},
    this.photoPaths = const [],
    this.weight,
    this.weightUnit,
    this.originalBcId,
    this.isNew = true,
    this.isDeleted = false,
    this.originalQuantity = 0,
  });
}

class BrokerFormPage extends StatefulWidget {
  // Edit mode parameters (null = create mode, set = edit mode)
  final String? editVoucherId;
  final String? editVoucherNumber;
  final String? editBrokerName;
  final String? editBrokerPhone;
  final String? editBrokerAddress;
  final String? editBrokerSocial;
  final DateTime? editConsignmentDate;
  final String? editNotes;
  final List<ConsignmentItemTemp>? editExistingItems;
  final Map<String, double>? editOriginalQuantities;

  const BrokerFormPage({
    Key? key,
    this.editVoucherId,
    this.editVoucherNumber,
    this.editBrokerName,
    this.editBrokerPhone,
    this.editBrokerAddress,
    this.editBrokerSocial,
    this.editConsignmentDate,
    this.editNotes,
    this.editExistingItems,
    this.editOriginalQuantities,
  }) : super(key: key);

  @override
  State<BrokerFormPage> createState() => _BrokerFormPageState();
}

class _BrokerFormPageState extends State<BrokerFormPage> {
  // Header fields
  late TextEditingController _brokerNameCtrl;
  late TextEditingController _brokerPhoneCtrl;
  late TextEditingController _brokerAddressCtrl;
  late TextEditingController _brokerSocialCtrl;
  late TextEditingController _notesCtrl;
  
  DateTime _consignmentDate = DateTime.now();
  
  // Form mode tracking
  bool _isEditMode = false; // true = edit mode, false = create mode
  String? _editVoucherId; // Preserve during edit
  String? _editVoucherNumber; // Preserve during edit
  Map<String, double> _editOriginalQuantities = {}; // For inventory safety
  
  // Edit mode tracking (item level)
  String? _editingItemId; // null = new item, set = editing existing item
  late String _brokerConsignmentNumber;
  late String _tempBrokerId; // Temporary ID for form photos
  List<String> _formPhotoPaths = []; // Photos collected during form
  int _photoPickerResetKey = 0; // Key to force PhotoMediaBox rebuild
  
  // Items list - confirmed items ready to save
  List<ConsignmentItemTemp> _confirmedItems = [];
  // Currently editing item
  late ConsignmentItemTemp _currentEditingItem;
  List<Gemstone> _availableGemstones = [];
  
  // Edit mode: separate original and draft items
  List<ConsignmentItemTemp> _originalItems = []; // Original preloaded items (read-only reference)
  List<ConsignmentItemTemp> _currentDraftItems = []; // Editable draft items (user can modify)
  
  // Duplicate broker check result
  String? _forcedBrokerProfileId; // Set by duplicate check in _saveBrokerConsignment
  
  final _date = DateFormat('dd/MM/yyyy');
  final _dateNum = DateFormat('yyyyMMdd');

  @override
  void initState() {
    super.initState();
    _brokerNameCtrl = TextEditingController();
    _brokerPhoneCtrl = TextEditingController();
    _brokerAddressCtrl = TextEditingController();
    _brokerSocialCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    
    _availableGemstones = LocalDb.gemstones().values.toList();
    
    // Check if in edit mode
    if (widget.editVoucherId != null) {
      _isEditMode = true;
      _editVoucherId = widget.editVoucherId;
      _editVoucherNumber = widget.editVoucherNumber;
      _brokerConsignmentNumber = widget.editVoucherNumber ?? 'BC-UNKNOWN';
      _editOriginalQuantities = widget.editOriginalQuantities ?? {};
      
      // Preload header data
      _brokerNameCtrl.text = widget.editBrokerName ?? '';
      _brokerPhoneCtrl.text = widget.editBrokerPhone ?? '';
      _brokerAddressCtrl.text = widget.editBrokerAddress ?? '';
      _brokerSocialCtrl.text = widget.editBrokerSocial ?? '';
      _consignmentDate = widget.editConsignmentDate ?? DateTime.now();
      _notesCtrl.text = widget.editNotes ?? '';
      
      // Preload existing items - keep separate original and draft
      if (widget.editExistingItems != null && widget.editExistingItems!.isNotEmpty) {
        // Store original items (read-only reference)
        _originalItems = List<ConsignmentItemTemp>.from(widget.editExistingItems!);
        
        // Create editable draft items (deep copy to allow modifications)
        _currentDraftItems = widget.editExistingItems!.map((item) {
          return ConsignmentItemTemp(
            id: item.id,
            gemstone: item.gemstone,
            consignedQuantity: item.consignedQuantity,
            sourceType: item.sourceType,
            selectedPurchase: item.selectedPurchase,
            selectedBreakdownItem: item.selectedBreakdownItem,
            availableBreakdownItems: Map<String, int>.from(item.availableBreakdownItems),
            photoPaths: List<String>.from(item.photoPaths),
            weight: item.weight,
            weightUnit: item.weightUnit,
            originalBcId: item.originalBcId,
            isNew: item.isNew,
            isDeleted: item.isDeleted,
            originalQuantity: item.originalQuantity,
          );
        }).toList();
        
        // Use draft items for display
        _confirmedItems = List<ConsignmentItemTemp>.from(_currentDraftItems);
      }
    } else {
      // Create mode
      _isEditMode = false;
      _generateBrokerConsignmentNumber();
    }
    
    _tempBrokerId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentEditingItem = ConsignmentItemTemp(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  void _generateBrokerConsignmentNumber() {
    final dateStr = _dateNum.format(_consignmentDate);
    final randomSuffix = DateTime.now().millisecondsSinceEpoch % 10000;
    _brokerConsignmentNumber = 'BC-$dateStr-${randomSuffix.toString().padLeft(4, '0')}';
  }

  void _updateFormPhotoPaths() {
    // Callback when photos are updated in the media box
    setState(() {});
  }

  double _getTotalConsignmentQuantity() {
    return _confirmedItems.fold<double>(0, (sum, item) => sum + item.consignedQuantity);
  }

  /// Auto-search for matching BrokerProfile by name or phone
  void _autoSearchBrokerProfile() {
    final nameQuery = _brokerNameCtrl.text.trim();
    final phoneQuery = _brokerPhoneCtrl.text.trim();

    // Skip if both fields are empty
    if (nameQuery.isEmpty && phoneQuery.isEmpty) {
      return;
    }

    try {
      // Get all active broker profiles
      final brokers = LocalDb.activeBrokerProfiles();

      // Search by name first (case-insensitive)
      if (nameQuery.isNotEmpty) {
        final matchedByName = brokers.firstWhereOrNull(
          (broker) => broker.name.toLowerCase().contains(nameQuery.toLowerCase()),
        );
        if (matchedByName != null) {
          _fillBrokerProfile(matchedByName);
          return;
        }
      }

      // Search by phone (exact match)
      if (phoneQuery.isNotEmpty) {
        final matchedByPhone = brokers.firstWhereOrNull(
          (broker) => broker.phone == phoneQuery,
        );
        if (matchedByPhone != null) {
          _fillBrokerProfile(matchedByPhone);
          return;
        }
      }
    } catch (e) {
      print('Error searching broker profile: $e');
    }
  }

  /// Fill broker form fields from BrokerProfile
  void _fillBrokerProfile(BrokerProfile broker) {
    setState(() {
      _brokerNameCtrl.text = broker.name;
      _brokerPhoneCtrl.text = broker.phone;
      _brokerAddressCtrl.text = broker.address ?? '';
      _brokerSocialCtrl.text = broker.socialAccount ?? '';
    });
  }

  /// Extension method to find first element or null
  /// (Dart doesn't have firstWhereOrNull in older versions)
  /// 
  /// Get purchases that have breakdown items with quantity > 0
  List<Gemstone> _getPurchasesWithBreakdownItems() {
    return _availableGemstones.where((gemstone) {
      if (gemstone.breakdownItems.isEmpty) return false;
      return gemstone.breakdownItems.values.any((item) {
        // Extract quantity from nested map (new format: Map<String, dynamic>)
        final itemData = item as Map<String, dynamic>?;
        if (itemData == null) return false;
        final quantity = (itemData['quantity'] as num?)?.toInt() ?? 0;
        return quantity > 0;
      });
    }).toList();
  }

  @override
  void dispose() {
    _brokerNameCtrl.dispose();
    _brokerPhoneCtrl.dispose();
    _brokerAddressCtrl.dispose();
    _brokerSocialCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _isHeaderValid() {
    return _brokerNameCtrl.text.isNotEmpty &&
        _brokerPhoneCtrl.text.isNotEmpty &&
        _brokerAddressCtrl.text.isNotEmpty;
  }

  bool _isCurrentItemValid() {
    // Convert current editing item to validation model
    final draftItem = DraftConsignmentItem(
      id: _currentEditingItem.id,
      gemstone: _currentEditingItem.gemstone,
      consignedQuantity: _currentEditingItem.consignedQuantity,
      sourceType: _currentEditingItem.sourceType,
      selectedPurchase: _currentEditingItem.selectedPurchase,
      selectedBreakdownItem: _currentEditingItem.selectedBreakdownItem,
      availableBreakdownItems: _currentEditingItem.availableBreakdownItems,
    );

    // Use Draft-Aware validation
    final result = BrokerConsignmentValidation.validateItemQuantity(
      item: draftItem,
      existingDraftItems: _confirmedItems
          .map((item) => DraftConsignmentItem(
                id: item.id,
                gemstone: item.gemstone,
                consignedQuantity: item.consignedQuantity,
                sourceType: item.sourceType,
                selectedPurchase: item.selectedPurchase,
                selectedBreakdownItem: item.selectedBreakdownItem,
                availableBreakdownItems: item.availableBreakdownItems,
              ))
          .toList(),
      editingItemId: _editingItemId,
    );

    return result.isValid;
  }

  bool _isFormValid() {
    if (!_isHeaderValid()) return false;
    if (_confirmedItems.isEmpty) return false;
    
    // Validate all confirmed items
    for (final item in _confirmedItems) {
      // Validate quantity first
      if (item.consignedQuantity <= 0) {
        return false;
      }
      
      // Branch validation by sourceType
      if (item.sourceType == 'breakdown_item') {
        // For breakdown items: require purchase, breakdown item, and quantity
        if (item.selectedPurchase == null || item.selectedBreakdownItem == null) {
          return false;
        }
        
        // Edit mode: apply inventory safety formula for breakdown items
        if (_isEditMode) {
          final originalQty = _editOriginalQuantities[item.id] ?? 0.0;
          
          if (item.availableBreakdownItems.containsKey(item.selectedBreakdownItem)) {
            final currentAvailable = item.availableBreakdownItems[item.selectedBreakdownItem]!.toDouble();
            final effectiveAvailable = currentAvailable + originalQty;
            
            developer.log(
              'INVENTORY_VALIDATION (EDIT BREAKDOWN): id=${item.id}, '
              'breakdownItem=${item.selectedBreakdownItem}, '
              'currentAvailable=$currentAvailable, '
              'originalQty=$originalQty, '
              'editedQty=${item.consignedQuantity}, '
              'effectiveAvailable=$effectiveAvailable',
              name: 'BrokerFormPage',
            );
            
            if (item.consignedQuantity > effectiveAvailable) {
              developer.log(
                'VALIDATION_FAILED: breakdown item edited quantity exceeds effective available',
                name: 'BrokerFormPage',
              );
              return false;
            }
          }
        } else {
          // Create mode: validate against current available only
          if (item.availableBreakdownItems.containsKey(item.selectedBreakdownItem)) {
            final availableQty = item.availableBreakdownItems[item.selectedBreakdownItem]!;
            
            developer.log(
              'INVENTORY_VALIDATION (CREATE BREAKDOWN): id=${item.id}, '
              'breakdownItem=${item.selectedBreakdownItem}, '
              'availableQty=$availableQty, '
              'editedQty=${item.consignedQuantity}',
              name: 'BrokerFormPage',
            );
            
            if (item.consignedQuantity > availableQty) {
              developer.log(
                'VALIDATION_FAILED: breakdown item edited quantity exceeds available',
                name: 'BrokerFormPage',
              );
              return false;
            }
          }
        }
      } else {
        // For whole stone: require gemstone and quantity
        if (item.gemstone == null) {
          return false;
        }
        
        // Edit mode: apply inventory safety formula
        // effectiveAvailable = currentRemaining + originalQuantity - editedQuantity
        if (_isEditMode) {
          final originalQty = _editOriginalQuantities[item.id] ?? 0.0;
          final currentRemaining = LocalDb.gemstoneRemainingQuantity(item.gemstone!);
          final effectiveAvailable = currentRemaining + originalQty;
          
          developer.log(
            'INVENTORY_VALIDATION (EDIT): id=${item.id}, '
            'currentRemaining=$currentRemaining, '
            'originalQty=$originalQty, '
            'editedQty=${item.consignedQuantity}, '
            'effectiveAvailable=$effectiveAvailable',
            name: 'BrokerFormPage',
          );
          
          if (item.consignedQuantity > effectiveAvailable) {
            developer.log(
              'VALIDATION_FAILED: edited quantity exceeds effective available',
              name: 'BrokerFormPage',
            );
            return false;
          }
        } else {
          // Create mode: validate against current remaining only
          final currentRemaining = LocalDb.gemstoneRemainingQuantity(item.gemstone!);
          
          developer.log(
            'INVENTORY_VALIDATION (CREATE): id=${item.id}, '
            'currentRemaining=$currentRemaining, '
            'editedQty=${item.consignedQuantity}',
            name: 'BrokerFormPage',
          );
          
          if (item.consignedQuantity > currentRemaining) {
            developer.log(
              'VALIDATION_FAILED: edited quantity exceeds current remaining',
              name: 'BrokerFormPage',
            );
            return false;
          }
        }
      }
    }
    
    return true;
  }

  void _confirmCurrentItem() {
    if (!_isCurrentItemValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ကျောက်ရွေးချယ်ခြင်း၊ အရင်းအမြစ်အမျိုးအစား နှင့် အရေအတွက်ကို ဖြည့်သွင်းပါ။'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    setState(() {
      // Copy current form photos to the item (independent copy)
      _currentEditingItem.photoPaths = List<String>.from(_formPhotoPaths);
      
      if (_editingItemId != null) {
        // UPDATE existing item (Feature 2: Edit mode)
        final index = _confirmedItems.indexWhere((item) => item.id == _editingItemId);
        if (index != -1) {
          _confirmedItems[index] = _currentEditingItem;
        }
      } else {
        // ADD new item
        _confirmedItems.add(_currentEditingItem);
      }
      
      // Reset the form completely
      _resetCurrentItemForm();
    });
  }

  void _resetCurrentItemForm() {
    setState(() {
      // Reset all form fields
      _currentEditingItem = ConsignmentItemTemp(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      // Create NEW empty list instance (not cleared reference)
      _formPhotoPaths = <String>[];
      // Generate NEW temp broker ID to ensure PhotoMediaBox reads from empty directory
      // This prevents stale photos from being reloaded from persistent storage
      _tempBrokerId = DateTime.now().millisecondsSinceEpoch.toString();
      // Force PhotoMediaBox rebuild by changing ValueKey
      _photoPickerResetKey++;
      // Clear edit mode
      _editingItemId = null;
    });
  }
  
  void _editConfirmedItem(ConsignmentItemTemp item) {
    setState(() {
      // Mark as editing mode
      _editingItemId = item.id;
      
      // Restore ALL fields from the temporary item
      _currentEditingItem = ConsignmentItemTemp(
        id: item.id,
        gemstone: item.gemstone,
        consignedQuantity: item.consignedQuantity,
        sourceType: item.sourceType,
        selectedPurchase: item.selectedPurchase,
        selectedBreakdownItem: item.selectedBreakdownItem,
        availableBreakdownItems: item.availableBreakdownItems,
        photoPaths: List<String>.from(item.photoPaths), // Independent copy
      );
      
      // Restore form photo paths
      _formPhotoPaths = List<String>.from(item.photoPaths);
      
      // Generate new temp broker ID for editing
      _tempBrokerId = DateTime.now().millisecondsSinceEpoch.toString();
      _photoPickerResetKey++;
      
      // Scroll to top to show form
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }
  
  void _deleteConfirmedItem(String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ဖျက်ရန် အတည်ပြုပါ'),
        content: const Text('ဤအရာကို ဖျက်ပြီးသည်နှင့် ပြန်လည်ရယူ၍ မရနိုင်ပါ။'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ပယ်ဖျက်ပါ'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // FIX: Mark as deleted instead of removing, to preserve originalBcId for soft-delete
                // For existing items (with originalBcId): mark isDeleted = true
                // For new items (without originalBcId): remove them since they don't exist in Hive
                final itemIndex = _confirmedItems.indexWhere((item) => item.id == itemId);
                if (itemIndex >= 0) {
                  final item = _confirmedItems[itemIndex];
                  if (item.originalBcId != null) {
                    // Existing item: mark as deleted to preserve originalBcId for soft-delete
                    item.isDeleted = true;
                  } else {
                    // New item: remove it since it doesn't exist in Hive
                    _confirmedItems.removeAt(itemIndex);
                  }
                }
                // If we were editing this item, clear the form
                if (_editingItemId == itemId) {
                  _resetCurrentItemForm();
                }
              });
            },
            child: const Text('ဖျက်မည်', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
  
  void _viewItemPhotos(List<String> photoPaths) {
    if (photoPaths.isEmpty) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewer(
          photoUrls: photoPaths,
          initialIndex: 0,
        ),
      ),
    );
  }

  void _removeConfirmedItem(String itemId) {
    // This method is kept for backward compatibility but is no longer used
    // Use _deleteConfirmedItem instead which shows confirmation dialog
    setState(() {
      _confirmedItems.removeWhere((item) => item.id == itemId);
      if (_editingItemId == itemId) {
        _resetCurrentItemForm();
      }
    });
  }

  void _updateCurrentItemGemstone(Gemstone? gemstone) {
    setState(() {
      _currentEditingItem.gemstone = gemstone;
      // Reset quantity if gemstone changed
      _currentEditingItem.consignedQuantity = 0;
      
      // Auto-prefill weight and unit from purchase record if not in edit mode
      if (gemstone != null && !_isEditMode) {
        _autoPrefillWeightFromPurchase(gemstone);
      } else if (gemstone == null) {
        // Clear weight/unit if gemstone is deselected
        _currentEditingItem.weight = null;
        _currentEditingItem.weightUnit = null;
      }
    });
  }
  
  void _autoPrefillWeightFromPurchase(Gemstone gemstone) {
    // Extract weight and unit from the purchase record
    // ONLY auto-prefill if valid data exists; otherwise leave fields empty
    
    // Only set weight if it's a valid positive value
    if (gemstone.weightCarat > 0) {
      _currentEditingItem.weight = gemstone.weightCarat;
    } else {
      // Ensure weight is null (empty) if purchase has no valid weight
      _currentEditingItem.weight = null;
    }
    
    // Only set unit if it's a non-empty string
    if (gemstone.weightUnit.isNotEmpty) {
      _currentEditingItem.weightUnit = gemstone.weightUnit;
    } else {
      // Ensure unit is null (unselected) if purchase has no unit
      _currentEditingItem.weightUnit = null;
    }
  }

  void _updateCurrentItemQuantity(double quantity) {
    setState(() {
      _currentEditingItem.consignedQuantity = quantity;
    });
  }

  void _updateCurrentItemSourceType(String sourceType) {
    setState(() {
      _currentEditingItem.sourceType = sourceType;
      _currentEditingItem.consignedQuantity = 0;
      if (sourceType == 'whole_stone') {
        _currentEditingItem.selectedPurchase = null;
        _currentEditingItem.selectedBreakdownItem = null;
        _currentEditingItem.availableBreakdownItems = {};
      }
    });
  }

  void _updateCurrentItemPurchase(Gemstone? purchase) {
    setState(() {
      _currentEditingItem.selectedPurchase = purchase;
      _currentEditingItem.selectedBreakdownItem = null;
      if (purchase != null && purchase.breakdownItems.isNotEmpty) {
        _currentEditingItem.availableBreakdownItems = {};
        purchase.breakdownItems.forEach((name, item) {
          // Extract quantity from nested map (new format: Map<String, dynamic>)
          final itemData = item as Map<String, dynamic>?;
          final qty = (itemData?['quantity'] as num?)?.toInt() ?? 0;
          if (qty > 0) {
            _currentEditingItem.availableBreakdownItems[name] = qty;
          }
        });
      } else {
        _currentEditingItem.availableBreakdownItems = {};
      }
    });
  }

  void _updateCurrentItemBreakdownItem(String? breakdownItemName) {
    setState(() {
      _currentEditingItem.selectedBreakdownItem = breakdownItemName;
      _currentEditingItem.consignedQuantity = 0;
    });
  }

  Future<void> _saveBrokerConsignment() async {
    if (!_isFormValid()) return;

    debugPrint('[BROKER_DUPLICATE] final save entered');
    developer.log('ENTRY: _saveBrokerConsignment() called, isEditMode=$_isEditMode');

    try {
      if (_isEditMode) {
        // CRITICAL: Sync _confirmedItems (user-edited list) to _currentDraftItems before save
        // This ensures newly added items are included in the save process
        _currentDraftItems = List<ConsignmentItemTemp>.from(_confirmedItems);
        await _saveEditMode();
      } else {
        // PHASE 0: Duplicate broker check (CREATE MODE ONLY)
        final brokerPhone = _brokerPhoneCtrl.text.trim();
        final normalizedPhone = _normalizePhone(brokerPhone);
        
        debugPrint('[BROKER_DUPLICATE] normalized phone=$normalizedPhone');
        
        if (normalizedPhone.isNotEmpty) {
          // Get all active broker profiles
          final allBrokers = LocalDb.activeBrokerProfiles();
          debugPrint('[BROKER_DUPLICATE] broker count=${allBrokers.length}');
          
          // Search for phone match
          BrokerProfile? matchedBroker;
          for (final broker in allBrokers) {
            final normalizedExistingPhone = _normalizePhone(broker.phone);
            if (normalizedExistingPhone == normalizedPhone) {
              matchedBroker = broker;
              debugPrint('[BROKER_DUPLICATE] matched broker id=${broker.id}, name=${broker.name}');
              break;
            }
          }
          
          if (matchedBroker != null) {
            // Phone match found - use local non-null variable
            final confirmedBroker = matchedBroker;
            debugPrint('[BROKER_DUPLICATE] showing dialog');
            
            if (mounted) {
              final shouldUseExisting = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text('ပွဲစားအချက်အလက် တွေ့ရှိပါသည်'),
                  content: Text(
                    'ဤဖုန်းနံပါတ်ဖြင့် ပွဲစားမှတ်တမ်းရှိပြီးသားဖြစ်ပါသည်။\n'
                    'အမည်: ${confirmedBroker.name}\n'
                    'ဖုန်းနံပါတ်: ${confirmedBroker.phone}\n\n'
                    'ရှိပြီးသားပွဲစားကို အသုံးပြုမလား?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('မသုံးတော့ပါ'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('အသုံးပြုမည်'),
                    ),
                  ],
                ),
              ) ?? false;
              
              if (!shouldUseExisting) {
                debugPrint('[BROKER_DUPLICATE] user rejected, cancelling save');
                developer.log('DUPLICATE CHECK: User rejected existing broker');
                return;
              }
              
              debugPrint('[BROKER_DUPLICATE] user accepted, using existing broker');
            }
            
            // User accepted - use existing broker, skip _saveCreateMode duplicate check
            // Pass matched broker ID to _saveCreateMode via a flag
            _forcedBrokerProfileId = confirmedBroker.id;
          }
        }
        
        await _saveCreateMode();
      }
    } catch (e, stackTrace) {
      developer.log('EXCEPTION: $e\nStackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('အမှားအယွင်း: $e')),
        );
      }
    }
  }

  String _normalizePhone(String phone) {
    return phone
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .trim();
  }

  Future<void> _saveCreateMode() async {
    final voucherId = const Uuid().v4();
    final voucherNumber = LocalDb.generateNextVoucherNumber();
    
    developer.log('CREATE MODE: Generated voucherId=$voucherId, voucherNumber=$voucherNumber');
    
    // PHASE 1: Broker Profile Resolution
    String? brokerProfileId;
    
    // Check if duplicate check already resolved this in _saveBrokerConsignment
    if (_forcedBrokerProfileId != null) {
      brokerProfileId = _forcedBrokerProfileId;
      debugPrint('[BROKER_DUPLICATE] _saveCreateMode using forced broker id=$brokerProfileId');
      developer.log('CREATE MODE: Using forced broker profile from duplicate check: id=$brokerProfileId');
      _forcedBrokerProfileId = null; // Reset for next save
    } else {
      // No forced broker - create new one
      final brokerName = _brokerNameCtrl.text.trim();
      final brokerPhone = _brokerPhoneCtrl.text.trim();
      
      final newProfile = BrokerProfile(
        id: const Uuid().v4(),
        name: brokerName,
        phone: brokerPhone,
        address: _brokerAddressCtrl.text.trim(),
        socialAccount: _brokerSocialCtrl.text.trim().isEmpty ? null : _brokerSocialCtrl.text.trim(),
        profileImagePath: null,
        note: '',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      
      await LocalDb.saveBrokerProfile(newProfile);
      brokerProfileId = newProfile.id;
      debugPrint('[BROKER_DUPLICATE] _saveCreateMode created new broker id=$brokerProfileId');
      developer.log('CREATE MODE: Created new broker profile: id=${newProfile.id}, name=${newProfile.name}');
    }
    
    // PHASE 2: Save voucher items with broker profile link
    int itemCount = 0;
    for (final item in _confirmedItems) {
      itemCount++;
      
      String purchaseId;
      if (item.sourceType == 'whole_stone') {
        if (item.gemstone == null) continue;
        purchaseId = item.gemstone!.id;
      } else {
        if (item.selectedPurchase == null) continue;
        purchaseId = item.selectedPurchase!.id;
      }
      
      await LocalDb.createBrokerConsignment(
        purchaseId: purchaseId,
        consignedQuantity: item.consignedQuantity,
        sourceType: item.sourceType,
        breakdownItemName: item.selectedBreakdownItem,
        brokerName: _brokerNameCtrl.text,
        brokerPhone: _brokerPhoneCtrl.text,
        brokerAddress: _brokerAddressCtrl.text,
        brokerSocialAccount: _brokerSocialCtrl.text.isEmpty ? null : _brokerSocialCtrl.text,
        brokerProfileId: brokerProfileId, // Link to broker profile
        photoPaths: item.photoPaths,
        voucherId: voucherId,
        voucherNumber: voucherNumber,
        weight: item.weight,
        weightUnit: item.weightUnit,
      );
    }
    
    developer.log('CREATE MODE: All $itemCount items saved successfully with brokerProfileId=$brokerProfileId');
    
    if (mounted) {
      context.pop(true);
    }
  }

  Future<void> _saveEditMode() async {
    try {
      // Initialize diagnostic logging
      await DiagnosticLogService.init();
      DiagnosticLogService.addLog('========== EDIT SAVE STARTED ==========');
      DiagnosticLogService.addLog('Voucher Number: $_editVoucherNumber');
      DiagnosticLogService.addLog('Voucher ID: $_editVoucherId');
      
      // ===== STAGE 1: LOG DRAFT ITEMS BEFORE SAVE =====
      DiagnosticLogService.addLog('\n===== STAGE 1: DRAFT ITEMS BEFORE SAVE =====');
      DiagnosticLogService.addLog('Total draft items: ${_currentDraftItems.length}');
      int existingItemCount = 0;
      int newItemCountDraft = 0;
      int deletedItemCount = 0;
      List<String> existingIds = [];
      List<String> newIds = [];
      List<String> deletedIds = [];
      for (int i = 0; i < _currentDraftItems.length; i++) {
        final item = _currentDraftItems[i];
        if (item.isDeleted) {
          deletedItemCount++;
          if (item.originalBcId != null) deletedIds.add(item.originalBcId!);
          DiagnosticLogService.addLog('  [$i] DELETED | originalBcId=${item.originalBcId} | sourceType=${item.sourceType} | gemName=${item.gemstone?.name}');
          continue;
        }
        if (item.isNew) {
          newItemCountDraft++;
          newIds.add(item.id);
        } else {
          existingItemCount++;
          if (item.originalBcId != null) existingIds.add(item.originalBcId!);
        }
        DiagnosticLogService.addLog('  [$i] isNew=${item.isNew} | isDeleted=${item.isDeleted} | originalBcId=${item.originalBcId} | sourceType=${item.sourceType} | gemstoneId=${item.gemstone?.id} | gemName=${item.gemstone?.name} | breakdownItem=${item.selectedBreakdownItem} | qty=${item.consignedQuantity}');
      }
      DiagnosticLogService.addLog('Existing items: $existingItemCount | New items (draft): $newItemCountDraft | Deleted items: $deletedItemCount');
      DiagnosticLogService.addLog('Existing IDs: $existingIds');
      DiagnosticLogService.addLog('New IDs (draft): $newIds');
      DiagnosticLogService.addLog('Deleted IDs: $deletedIds');
      
      developer.log('EDIT MODE: Starting atomic save');
      developer.log('STAGE 1: DRAFT ITEMS BEFORE SAVE');
      developer.log('Total draft items: ${_currentDraftItems.length}');
      
      // Validate aggregate quantities
      final Map<String, double> sourceQuantities = {};
      for (final item in _currentDraftItems) {
        if (item.isDeleted) continue;
        
        String sourceKey = item.sourceType == 'whole_stone'
            ? 'whole_stone_${item.gemstone?.id}'
            : 'breakdown_${item.gemstone?.id}_${item.selectedBreakdownItem}';
        
        sourceQuantities[sourceKey] = (sourceQuantities[sourceKey] ?? 0) + item.consignedQuantity;
      }
      
      // Validate each source
      for (final entry in sourceQuantities.entries) {
        double totalOriginal = 0.0;
        for (final origItem in _originalItems) {
          if (origItem.isDeleted) continue;
          String origKey = origItem.sourceType == 'whole_stone'
              ? 'whole_stone_${origItem.gemstone?.id}'
              : 'breakdown_${origItem.gemstone?.id}_${origItem.selectedBreakdownItem}';
          if (origKey == entry.key) totalOriginal += origItem.originalQuantity;
        }
        
        double currentRemaining = 0.0;
        if (entry.key.startsWith('whole_stone')) {
          final gemstoneId = entry.key.replaceFirst('whole_stone_', '');
          for (final item in _currentDraftItems) {
            if (item.gemstone?.id == gemstoneId && item.sourceType == 'whole_stone') {
              currentRemaining = LocalDb.gemstoneRemainingQuantity(item.gemstone!).toDouble();
              break;
            }
          }
        }
        
        final effectiveAvailable = currentRemaining + totalOriginal;
        if (entry.value > effectiveAvailable) {
          throw Exception('အရင်းအမြစ်မှ အလွန်ကျော်လွန်သည့်အရေအတွက်ကို အပ်ခွင့်မရှိပါ။');
        }
      }
      
      developer.log('EDIT MODE: Aggregate validation passed');
      DiagnosticLogService.addLog('Aggregate validation passed');
      
      // Update existing items
      for (final item in _currentDraftItems) {
        if (item.isNew || item.isDeleted) continue;
        if (item.originalBcId == null) continue;
        
        final record = LocalDb.getBrokerConsignment(item.originalBcId!);
        if (record != null && record.voucherId == _editVoucherId) {
          record.consignedQuantity = item.consignedQuantity;
          record.brokerName = _brokerNameCtrl.text;
          record.brokerPhone = _brokerPhoneCtrl.text;
          record.brokerAddress = _brokerAddressCtrl.text;
          record.brokerSocialAccount = _brokerSocialCtrl.text.isEmpty ? null : _brokerSocialCtrl.text;
          // Note: brokerProfileId should not change during edit, keep original value
          record.notes = _notesCtrl.text;
          record.photoPaths = item.photoPaths;
          record.weight = item.weight; // Update weight
          record.weightUnit = item.weightUnit; // Update weight unit
          record.updatedAt = DateTime.now().millisecondsSinceEpoch;
          final brokers = Hive.box<BrokerConsignment>('brokerConsignments');
          await brokers.put(record.id, record);
          developer.log('EDIT MODE: Updated ${record.id}');
        }
      }
      
      // ===== STAGE 2: ADD NEW ITEMS =====
      DiagnosticLogService.addLog('\n===== STAGE 2: ADDING NEW ITEMS =====');
      developer.log('STAGE 2: ADDING NEW ITEMS');
      int newItemCountCreated = 0;
      List<String> validationErrors = [];
      for (final item in _currentDraftItems) {
        if (!item.isNew) continue;
        
        String purchaseId;
        if (item.sourceType == 'whole_stone') {
          if (item.gemstone == null) {
            validationErrors.add('Whole stone item missing gemstone reference');
            continue;
          }
          purchaseId = item.gemstone!.id;
        } else {
          // For breakdown_item, use parent gemstone as purchaseId
          if (item.gemstone == null) {
            validationErrors.add('Breakdown item missing parent gemstone reference');
            continue;
          }
          purchaseId = item.gemstone!.id;
        }
        
        newItemCountCreated++;
        DiagnosticLogService.addLog('  [NEW-$newItemCountCreated] BEFORE createBrokerConsignment | sourceType=${item.sourceType} | purchaseId=$purchaseId | breakdownItem=${item.selectedBreakdownItem} | qty=${item.consignedQuantity}');
        developer.log('  [NEW-$newItemCountCreated] BEFORE createBrokerConsignment | sourceType=${item.sourceType} | purchaseId=$purchaseId | breakdownItem=${item.selectedBreakdownItem} | qty=${item.consignedQuantity}');
        
        // Get existing brokerProfileId from first item in this voucher
        String? brokerProfileId;
        final editVoucherId = _editVoucherId;
        final existingBrokerConsignments = editVoucherId == null
            ? <BrokerConsignment>[]
            : LocalDb.getBrokerConsignmentsByVoucherId(editVoucherId);
        if (existingBrokerConsignments.isNotEmpty) {
          brokerProfileId = existingBrokerConsignments.first.brokerProfileId;
        }
        
        await LocalDb.createBrokerConsignment(
          purchaseId: purchaseId,
          consignedQuantity: item.consignedQuantity,
          sourceType: item.sourceType,
          breakdownItemName: item.selectedBreakdownItem,
          brokerName: _brokerNameCtrl.text,
          brokerPhone: _brokerPhoneCtrl.text,
          brokerAddress: _brokerAddressCtrl.text,
          brokerSocialAccount: _brokerSocialCtrl.text.isEmpty ? null : _brokerSocialCtrl.text,
          brokerProfileId: brokerProfileId, // Use same profile as existing items
          photoPaths: item.photoPaths,
          voucherId: _editVoucherId,
          voucherNumber: _editVoucherNumber,
          weight: item.weight,
          weightUnit: item.weightUnit,
        );
        DiagnosticLogService.addLog('  [NEW-$newItemCountCreated] AFTER createBrokerConsignment');
        developer.log('  [NEW-$newItemCountCreated] AFTER createBrokerConsignment');
      }
      DiagnosticLogService.addLog('Total new items created: $newItemCountCreated');
      developer.log('STAGE 2: Total new items added: $newItemCountCreated');
      
      // ===== STAGE 2B: SOFT DELETE REMOVED ITEMS =====
      DiagnosticLogService.addLog('\n===== STAGE 2B: SOFT DELETE REMOVED ITEMS =====');
      int softDeletedCount = 0;
      for (final item in _currentDraftItems) {
        if (!item.isDeleted) continue;
        if (item.originalBcId == null) continue;
        
        final record = LocalDb.getBrokerConsignment(item.originalBcId!);
        if (record != null && record.voucherId == _editVoucherId) {
          softDeletedCount++;
          DiagnosticLogService.addLog('  [SOFT-DELETE-$softDeletedCount] BEFORE: id=${record.id} | sourceType=${record.sourceType} | breakdownItem=${record.breakdownItemName}');
          record.deletedAt = DateTime.now().millisecondsSinceEpoch;
          final brokers = Hive.box<BrokerConsignment>('brokerConsignments');
          await brokers.put(record.id, record);
          developer.log('EDIT MODE: Soft deleted ${record.id}');
          DiagnosticLogService.addLog('  [SOFT-DELETE-$softDeletedCount] AFTER: id=${record.id} | deletedAt=${record.deletedAt}');
        }
      }
      DiagnosticLogService.addLog('Total soft deleted: $softDeletedCount');
      
      developer.log('EDIT MODE: All changes saved successfully');
      
      // ===== STAGE 3: VERIFY HIVE AFTER SAVE =====
      DiagnosticLogService.addLog('\n===== STAGE 3: VERIFYING HIVE AFTER SAVE =====');
      developer.log('STAGE 3: VERIFYING HIVE AFTER SAVE');
      final brokers = Hive.box<BrokerConsignment>(LocalDb.brokerConsignmentsBox);
      final savedItems = brokers.values.where((b) => b.voucherId == _editVoucherId && b.deletedAt == null).toList();
      List<String> hiveIds = [];
      DiagnosticLogService.addLog('Total items in Hive for voucherId=$_editVoucherId (non-deleted): ${savedItems.length}');
      developer.log('Total items in Hive for voucherId=$_editVoucherId: ${savedItems.length}');
      for (int i = 0; i < savedItems.length; i++) {
        final item = savedItems[i];
        hiveIds.add(item.id);
        DiagnosticLogService.addLog('  [$i] id=${item.id} | sourceType=${item.sourceType} | purchaseId=${item.purchaseId} | breakdownItem=${item.breakdownItemName} | qty=${item.consignedQuantity} | createdAt=${item.createdAt}');
        developer.log('  [$i] id=${item.id} | sourceType=${item.sourceType} | purchaseId=${item.purchaseId} | breakdownItem=${item.breakdownItemName} | qty=${item.consignedQuantity}');
      }
      DiagnosticLogService.addLog('Hive IDs (non-deleted): $hiveIds');
      
      // Check for validation errors
      if (validationErrors.isNotEmpty) {
        DiagnosticLogService.addLog('\n⚠️ VALIDATION ERRORS DURING ITEM CREATION:');
        for (final error in validationErrors) {
          DiagnosticLogService.addLog('  - $error');
        }
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('⚠️ အမှားအယွင်း'),
              content: SingleChildScrollView(
                child: SelectableText(
                  'အရေးအသားများ သိမ်းဆည်းရန်အတွင်း အမှားအယွင်းများ ရှိသည်:\n\n' + validationErrors.join('\n'),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('နားလည်ပါသည်'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      // Compare counts and IDs
      List<String> expectedIds = [...existingIds];
      int expectedHiveCount = existingItemCount + newItemCountCreated;
      DiagnosticLogService.addLog('\n===== VERIFICATION SUMMARY =====');
      DiagnosticLogService.addLog('Draft items (non-deleted): ${existingItemCount + newItemCountDraft}');
      DiagnosticLogService.addLog('  - Existing: $existingItemCount (IDs: $existingIds)');
      DiagnosticLogService.addLog('  - New: $newItemCountDraft');
      DiagnosticLogService.addLog('  - Deleted: $deletedItemCount (IDs: $deletedIds)');
      DiagnosticLogService.addLog('Items created in Hive: $newItemCountCreated');
      DiagnosticLogService.addLog('Expected Hive count: $expectedHiveCount');
      DiagnosticLogService.addLog('Actual Hive count: ${savedItems.length}');
      DiagnosticLogService.addLog('Expected IDs (existing only): $expectedIds');
      DiagnosticLogService.addLog('Actual Hive IDs: $hiveIds');
      
      // Find extra or missing records
      final extraIds = hiveIds.where((id) => !expectedIds.contains(id)).toList();
      final missingIds = expectedIds.where((id) => !hiveIds.contains(id)).toList();
      
      if (extraIds.isNotEmpty) {
        DiagnosticLogService.addLog('\n⚠️ EXTRA RECORDS IN HIVE:');
        for (final extraId in extraIds) {
          final record = LocalDb.getBrokerConsignment(extraId);
          if (record != null) {
            DiagnosticLogService.addLog('  EXTRA: id=$extraId | sourceType=${record.sourceType} | purchaseId=${record.purchaseId} | breakdownItem=${record.breakdownItemName} | createdAt=${record.createdAt} | updatedAt=${record.updatedAt}');
          }
        }
      }
      
      if (missingIds.isNotEmpty) {
        DiagnosticLogService.addLog('\n⚠️ MISSING RECORDS IN HIVE:');
        for (final missingId in missingIds) {
          DiagnosticLogService.addLog('  MISSING: id=$missingId');
        }
      }
      
      if (savedItems.length != expectedHiveCount) {
        DiagnosticLogService.addLog('\n⚠️ MISMATCH DETECTED!');
        DiagnosticLogService.addLog('Expected: $expectedHiveCount items');
        DiagnosticLogService.addLog('Found: ${savedItems.length} items');
        
        if (mounted) {
          _showDiagnosticErrorDialog(
            draftCount: existingItemCount + newItemCountDraft,
            existingCount: existingItemCount,
            newCount: newItemCountDraft,
            hiveCount: savedItems.length,
            expectedCount: expectedHiveCount,
          );
        }
      } else {
        DiagnosticLogService.addLog('✓ All items saved correctly!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ဘောင်ချာပြင်ဆင်မှု သိမ်းဆည်းပြီးပါပြီ။')),
          );
          context.pop(true);
        }
      }
    } catch (e, stackTrace) {
      DiagnosticLogService.addLog('\n⚠️ ERROR DURING SAVE:');
      DiagnosticLogService.addLog('Exception: $e');
      DiagnosticLogService.addLog('StackTrace: $stackTrace');
      developer.log('ERROR: $e\n$stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('အမှားအယွင်း: $e')),
        );
      }
    }
  }

  void _showDiagnosticErrorDialog({
    required int draftCount,
    required int existingCount,
    required int newCount,
    required int hiveCount,
    required int expectedCount,
  }) {
    final diagnosticLog = DiagnosticLogService.getCurrentLog();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ အရေးအသားများ မသိမ်းဆည်းနိုင်ခြင်း'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('အရေးအသားများ မသိမ်းဆည်းနိုင်ခြင်း ရှိသည်။'),
              const SizedBox(height: 16),
              const Text('ရှင်းလင်းချက်:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('ပြင်ဆင်မှုမတိုင်မီ အရေးအသားများ: $draftCount'),
              Text('  - အဟောင်း: $existingCount'),
              Text('  - အသစ်: $newCount'),
              Text('Hive သို့ သိမ်းဆည်းထားသည့် အရေးအသားများ: $hiveCount'),
              Text('မျှော်လင့်ထားသည့် အရေးအသားများ: $expectedCount'),
              const SizedBox(height: 16),
              const Text('ဒီဗတ်ဂ်လော့ အချက်အလက်:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  diagnosticLog,
                  style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ပိတ်မည်'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('ကူးယူ'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: diagnosticLog));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ဒီဗတ်ဂ်လော့ ကူးယူပြီးပါပြီ')),
              );
            },
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(_isEditMode ? 'ပွဲစားအပ်ဘောင်ချာ ပြုပြင်ရန်' : 'ပွဲစားအပ်စာရင်း'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HEADER SECTION =====
            Text(
              'ပွဲစားအချက်အလက်',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Broker Consignment Number
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryAccent),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[900],
              ),
              child: Row(
                children: [
                  Icon(Icons.tag, color: AppTheme.primaryAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'အပ်စာရင်းအမှတ်',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        Text(
                          _brokerConsignmentNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Date picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _consignmentDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _consignmentDate = picked;
                    _generateBrokerConsignmentNumber();
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[900],
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppTheme.primaryAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _date.format(_consignmentDate),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Broker name
            TextField(
              controller: _brokerNameCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) {
                _autoSearchBrokerProfile();
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'ပွဲစားအမည် *',
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
            ),
            const SizedBox(height: 12),
            
            // Phone
            TextField(
              controller: _brokerPhoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(color: Colors.white),
              onChanged: (_) {
                _autoSearchBrokerProfile();
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'ဖုန်းနံပါတ် *',
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
            ),
            const SizedBox(height: 12),
            
            // Address
            TextField(
              controller: _brokerAddressCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'လိပ်စာ *',
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
            ),
            const SizedBox(height: 12),
            
            // Social account
            TextField(
              controller: _brokerSocialCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'လူမှုကွန်ယက်အကောင့်',
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
            ),
            const SizedBox(height: 12),
            
            // Notes
            TextField(
              controller: _notesCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'မှတ်ချက်များ',
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
            ),
            const SizedBox(height: 24),
            
            // ===== ITEMS SECTION =====
            // Running totals card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryAccent),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[900],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'စုစုပေါင်းအရေအတွက်',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_confirmedItems.length}',
                        style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'စုစုပေါင်းအပ်စာရင်းအရေအတွက်',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getTotalConsignmentQuantity().toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ===== EDITING SECTION =====
            Text(
              'ကျောက်ထည့်သွင်းခြင်း',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildEditingItemForm(),
            const SizedBox(height: 12),
            
            // Photo section title
            if (_currentEditingItem.gemstone != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'လက\u1031\u1038ယ\u1010\u103d\u1000\u103aအ\u1015\u103c\u102f\u1014\u102d\u102f\u1004\u103a: ${_currentEditingItem.gemstone!.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            
            // Photo Media Box
            _buildPhotoMediaBox(),
            
            const SizedBox(height: 12),
            
            // Add Item button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('ထည့်ရန်'),
                onPressed: _confirmCurrentItem,
              ),
            ),
            const SizedBox(height: 24),
            
            // ===== CONFIRMED ITEMS SECTION =====
            if (_confirmedItems.isNotEmpty)
              Text(
                'ထည့်သွင်းထားသောကျောက်များ (${_confirmedItems.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (_confirmedItems.isNotEmpty)
              const SizedBox(height: 12),
            
            // Items list
            // Filter to show only non-deleted items in the UI
            ..._buildConfirmedItemsList(),
            
            const SizedBox(height: 24),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid() 
                    ? AppTheme.primaryAccent 
                    : Colors.grey[700],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isFormValid() ? _saveBrokerConsignment : null,
                child: Text(
                  _isEditMode ? 'ပြင်ဆင်မှု သိမ်းဆည်းမည်' : 'သိမ်းဆည်းရန်',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingItemForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryAccent, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[900],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ကျောက်ထည့်သွင်းခြင်း',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Source Type selector
          Text(
            'အရင်းအမြစ်အမျိုးအစား',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 4),
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
            selected: <String>{_currentEditingItem.sourceType},
            onSelectionChanged: (Set<String> newSelection) {
              _updateCurrentItemSourceType(newSelection.first);
            },
          ),
          const SizedBox(height: 12),
          
          // Gemstone selection dropdown - only for whole stone mode
          if (_currentEditingItem.sourceType == 'whole_stone')
            DropdownButtonFormField<String?>(
              value: _currentEditingItem.gemstone?.id,
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
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('— ကျောက်မျက်ရွေးချယ်ပါ —'),
              ),
              ..._availableGemstones.map((g) => DropdownMenuItem<String?>(
                value: g.id,
                child: Text(
                  '${g.name} (${g.type} • ကျန်: ${LocalDb.gemstoneRemainingQuantity(g)} • ID: ${g.id.substring(0, 8)}...)',
                  overflow: TextOverflow.ellipsis,
                ),
              )).toList(),
            ],
            onChanged: (String? gemstoneId) {
              if (gemstoneId != null) {
                final gemstone = _availableGemstones.firstWhere(
                  (g) => g.id == gemstoneId,
                  orElse: () => _availableGemstones.first,
                );
                _updateCurrentItemGemstone(gemstone);
              } else {
                _updateCurrentItemGemstone(null);
              }
            },
            ),
            const SizedBox(height: 8),

            // Display selected gemstone details
            if (_currentEditingItem.gemstone != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                      const Icon(Icons.source_outlined,
                          color: AppTheme.primaryAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'အရင်းအမြစ်: ${_currentEditingItem.sourceType == 'whole_stone' ? 'အပြည့်အစုံ' : 'အခွဲ'}',
                          style: const TextStyle(
                              color: AppTheme.primaryAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          color: AppTheme.primaryAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ကျန်ရှိအရေအတွက်: ${LocalDb.gemstoneRemainingQuantity(_currentEditingItem.gemstone!)}',
                          style: const TextStyle(
                              color: AppTheme.primaryAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
          
          const SizedBox(height: 8),
          
          // Purchase Record selector (for breakdown items)
          if (_currentEditingItem.sourceType == 'breakdown_item')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ဝယ်ယူမှုမှတ်တမ်းရွေးချယ်ပါ',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String?>(
                  value: _currentEditingItem.selectedPurchase?.id,
                  isExpanded: true,
                  dropdownColor: AppTheme.surfaceDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'မှတ်တမ်းရွေးချယ်ပါ',
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
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('— မှတ်တမ်းရွေးချယ်ပါ —'),
                    ),
                    ..._getPurchasesWithBreakdownItems().map((g) {
                      final fragmentCount = g.breakdownItems?.length ?? 0;
                      final fragmentDisplay = fragmentCount > 0 ? ' • အစိတ်စိတ်: $fragmentCount' : '';
                      return DropdownMenuItem<String?>(
                        value: g.id,
                        child: Text(
                          '${g.name} (${g.type}$fragmentDisplay • ID: ${g.id.substring(0, 8)}...)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (String? gemstoneId) {
                    if (gemstoneId != null) {
                      final gemstone = _getPurchasesWithBreakdownItems().firstWhere(
                        (g) => g.id == gemstoneId,
                        orElse: () => _getPurchasesWithBreakdownItems().first,
                      );
                      _updateCurrentItemPurchase(gemstone);
                    } else {
                      _updateCurrentItemPurchase(null);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          
          // Breakdown Item selector
          if (_currentEditingItem.sourceType == 'breakdown_item' && _currentEditingItem.selectedPurchase != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ကျောက်အစိတ်စိတ်ရွေးချယ်ပါ',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 4),
                if (_currentEditingItem.availableBreakdownItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[900],
                    ),
                    child: Text(
                      'အစိတ်စိတ်မရှိသေးပါ',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                else
                  DropdownButtonFormField<String?>(
                    value: _currentEditingItem.selectedBreakdownItem,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'အစိတ်စိတ်ရွေးချယ်ပါ',
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
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— အစိတ်စိတ်ရွေးချယ်ပါ —'),
                      ),
                      ..._currentEditingItem.availableBreakdownItems.entries.map((e) {
                        final gemstone = _currentEditingItem.gemstone;
                        final itemData = gemstone?.breakdownItems?[e.key] as Map<String, dynamic>?;
                        final weight = (itemData?['weight'] as num?)?.toDouble() ?? 0;
                        final weightUnit = itemData?['weightUnit'] as String? ?? '';
                        final weightDisplay = weight > 0 ? ' — $weight $weightUnit' : '';
                        return DropdownMenuItem<String?>(
                          value: e.key,
                          child: Text('${e.key} (ကျန်: ${e.value}$weightDisplay)'),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? breakdownItem) {
                      _updateCurrentItemBreakdownItem(breakdownItem);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          
          // Display remaining weight for breakdown items
          if (_currentEditingItem.sourceType == 'breakdown_item' && _currentEditingItem.selectedBreakdownItem != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Builder(
                builder: (context) {
                  final gemstone = _currentEditingItem.gemstone;
                  final itemData = gemstone?.breakdownItems?[_currentEditingItem.selectedBreakdownItem] as Map<String, dynamic>?;
                  final weight = (itemData?['weight'] as num?)?.toDouble() ?? 0;
                  final weightUnit = itemData?['weightUnit'] as String? ?? '';
                  return Text(
                    'ကျန်ရှိအလေးချိန်: $weight $weightUnit',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  );
                },
              ),
            ),
          
          // Quantity input
          if (_currentEditingItem.gemstone != null || _currentEditingItem.selectedBreakdownItem != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'အပ်စာရင်းအရေအတွက်',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 4),
                TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _currentEditingItem.sourceType == 'breakdown_item' && _currentEditingItem.selectedBreakdownItem != null
                        ? 'အရေအတွက် (ကျန်ရှိ: ${_currentEditingItem.availableBreakdownItems[_currentEditingItem.selectedBreakdownItem] ?? 0})'
                        : 'အရေအတွက် (ကျန်ရှိ: ${LocalDb.gemstoneRemainingQuantity(_currentEditingItem.gemstone!)})',
                    hintStyle: TextStyle(color: Colors.grey[600]),
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
                  onChanged: (value) {
                    final qty = double.tryParse(value) ?? 0;
                    
                    // Use Draft-Aware validation
                    final draftItem = DraftConsignmentItem(
                      id: _currentEditingItem.id,
                      gemstone: _currentEditingItem.gemstone,
                      consignedQuantity: qty,
                      sourceType: _currentEditingItem.sourceType,
                      selectedPurchase: _currentEditingItem.selectedPurchase,
                      selectedBreakdownItem: _currentEditingItem.selectedBreakdownItem,
                      availableBreakdownItems: _currentEditingItem.availableBreakdownItems,
                    );
                    
                    final result = BrokerConsignmentValidation.validateItemQuantity(
                      item: draftItem,
                      existingDraftItems: _confirmedItems
                          .map((item) => DraftConsignmentItem(
                                id: item.id,
                                gemstone: item.gemstone,
                                consignedQuantity: item.consignedQuantity,
                                sourceType: item.sourceType,
                                selectedPurchase: item.selectedPurchase,
                                selectedBreakdownItem: item.selectedBreakdownItem,
                                availableBreakdownItems: item.availableBreakdownItems,
                              ))
                          .toList(),
                      editingItemId: _editingItemId,
                    );
                    
                    if (!result.isValid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.errorMessage ?? 'အရေအတွက်မှားနေသည်။'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                      return;
                    }
                    
                    _updateCurrentItemQuantity(qty);
                  },
                ),
              ],
            ),
            
            // Weight and Unit input (NEW)
            if (_currentEditingItem.gemstone != null || _currentEditingItem.selectedBreakdownItem != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'အလေးချိန်နှင့်ယူနစ်',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'အလေးချိန်',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            hintText: 'ဥပမာ: 5.2',
                            hintStyle: TextStyle(color: Colors.grey[600]),
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
                          controller: TextEditingController(
                            text: _currentEditingItem.weight != null && _currentEditingItem.weight! > 0
                                ? _currentEditingItem.weight.toString()
                                : '',
                          ),
                          onChanged: (value) {
                            final weight = double.tryParse(value);
                            if (weight != null && weight > 0) {
                              _currentEditingItem.weight = weight;
                            } else if (value.isEmpty) {
                              _currentEditingItem.weight = null;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _currentEditingItem.weightUnit,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceDark,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'ယူနစ်',
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
                          items: const [
                            DropdownMenuItem(value: 'ပိသာ', child: Text('ပိသာ')),
                            DropdownMenuItem(value: 'ကျပ်သား', child: Text('ကျပ်သား')),
                            DropdownMenuItem(value: 'ကာရက်', child: Text('ကာရက်')),
                            DropdownMenuItem(value: 'kg', child: Text('ကီလို (kg)')),
                            DropdownMenuItem(value: 'g', child: Text('ဂရမ် (g)')),
                            DropdownMenuItem(value: 'lb', child: Text('ပေါင် (lb)')),
                            DropdownMenuItem(value: 'oz', child: Text('အောင်စ (oz)')),
                          ],
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _currentEditingItem.weightUnit = value;
                              });
                            }
                          },
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

  Widget _buildConfirmedItemRow(ConsignmentItemTemp item) {
    String gemName = 'Unknown';
    double? weight;
    
    if (item.sourceType == 'whole_stone' && item.gemstone != null) {
      gemName = item.gemstone!.name;
      weight = item.gemstone!.weightCarat;
    } else if (item.sourceType == 'breakdown_item') {
      if (item.selectedPurchase != null && item.selectedBreakdownItem != null) {
        gemName = '${item.selectedPurchase!.name} / ${item.selectedBreakdownItem}';
        weight = item.selectedPurchase!.weightCarat;
      } else if (item.gemstone != null && item.selectedBreakdownItem != null) {
        // Fallback: resolve gemstone from gemstone object if selectedPurchase is null
        gemName = '${item.gemstone!.name} / ${item.selectedBreakdownItem}';
        weight = item.gemstone!.weightCarat;
      }
    }
    
    final photoCount = item.photoPaths.length;
    final isEditing = _editingItemId == item.id;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isEditing ? AppTheme.primaryAccent : Colors.grey[700]!,
          width: isEditing ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
        color: isEditing ? Colors.grey[850] : Colors.grey[900],
      ),
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
                      gemName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (weight != null && weight > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'အလေးချိန်: $weight viss',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (item.weight != null && item.weight! > 0 && item.weightUnit != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'အလေးချိန်: ${item.weight} ${item.weightUnit}',
                          style: TextStyle(
                            color: AppTheme.primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Feature 1: Photo badge opens PhotoViewer
              if (photoCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _viewItemPhotos(item.photoPaths),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '📷 $photoCount',
                        style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'အရေအတွက်: ${item.consignedQuantity}',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  // Feature 2: Edit button restores entire item
                  IconButton(
                    icon: Icon(
                      isEditing ? Icons.check_circle : Icons.edit,
                      color: isEditing ? Colors.green : AppTheme.primaryAccent,
                      size: 18,
                    ),
                    onPressed: () => _editConfirmedItem(item),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // Feature 3: Delete with confirmation
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppTheme.errorColor, size: 18),
                    onPressed: () => _deleteConfirmedItem(item.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build the filtered items list for the UI
  List<Widget> _buildConfirmedItemsList() {
    final visibleItems = _confirmedItems.where((item) => !item.isDeleted).toList();
    
    if (visibleItems.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[900],
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, color: Colors.grey[600], size: 32),
                const SizedBox(height: 8),
                Text(
                  'ထည့်သွင်းထားသောကျောက်မရှိသေးပါ',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ];
    } else {
      return [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleItems.length,
          itemBuilder: (context, index) {
            final item = visibleItems[index];
            return _buildConfirmedItemRow(item);
          },
        ),
      ];
    }
  }

  // Helper method to build compact summary text for confirmed items
  String _buildConfirmedItemSummary(ConsignmentItemTemp item) {
    if (item.sourceType == 'whole_stone' && item.gemstone != null) {
      return '${item.gemstone!.name} — ${item.consignedQuantity}';
    } else if (item.sourceType == 'breakdown_item' && item.selectedBreakdownItem != null && item.selectedPurchase != null) {
      return '${item.selectedPurchase!.name} / ${item.selectedBreakdownItem} — ${item.consignedQuantity}';
    } else {
      return 'Unknown — ${item.consignedQuantity}';
    }
  }

  /// Build photo media box widget
  Widget _buildPhotoMediaBox() {
    // Show title indicating these are current item photos
    final itemDescription = _currentEditingItem.gemstone != null
        ? _currentEditingItem.gemstone!.name
        : 'လက်ရှိကျောက်';

    // Create a temporary broker consignment for the form
    // This will be replaced with the real one after save
    final now = DateTime.now().millisecondsSinceEpoch;
    final tempHistoricalData = BrokerHistoricalData(
      purchaseName: 'ယာယီ',
      purchaseDate: now,
      originalSeller: '',
      gemstoneType: '',
      sourceType: 'whole_stone',
      originalQuantity: 0,
      originalWeight: 0,
      capturedAt: now,
    );

    final tempBrokerConsignment = BrokerConsignment(
      id: _tempBrokerId,
      purchaseId: '',
      sourceType: 'whole_stone',
      consignedQuantity: 0,
      historicalData: tempHistoricalData,
      brokerName: _brokerNameCtrl.text,
      brokerPhone: _brokerPhoneCtrl.text,
      brokerAddress: _brokerAddressCtrl.text,
      brokerSocialAccount: _brokerSocialCtrl.text.isEmpty ? null : _brokerSocialCtrl.text,
      photoPaths: _formPhotoPaths,
      createdAt: now,
    );

    return PhotoMediaBox(
      key: ValueKey(_photoPickerResetKey),
      brokerId: _tempBrokerId,
      brokerConsignment: tempBrokerConsignment,
      onPhotosUpdated: () {
        // Update the form photo paths when photos change
        setState(() {
          _formPhotoPaths = tempBrokerConsignment.photoPaths;
        });
      },
    );
  }

}
