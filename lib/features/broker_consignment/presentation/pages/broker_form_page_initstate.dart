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
      
      // Preload existing items
      if (widget.editExistingItems != null && widget.editExistingItems!.isNotEmpty) {
        _confirmedItems = List<ConsignmentItemTemp>.from(widget.editExistingItems!);
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
