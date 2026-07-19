import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:gemstone_management/core/local/local_db.dart';
import 'package:gemstone_management/core/local/models.dart';
import 'package:gemstone_management/core/theme/app_theme.dart';

class AddBrokerPage extends StatefulWidget {
  final BrokerProfile? existingBroker; // null = add mode, non-null = edit mode

  const AddBrokerPage({Key? key, this.existingBroker}) : super(key: key);

  @override
  State<AddBrokerPage> createState() => _AddBrokerPageState();
}

class _AddBrokerPageState extends State<AddBrokerPage> {
  late TextEditingController _nameController;
  late TextEditingController _nationalIdController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _socialAccountController;
  late TextEditingController _noteController;

  File? _selectedImage;
  bool _isSaving = false;

  bool get _isEditMode => widget.existingBroker != null;

  @override
  void initState() {
    super.initState();
    final broker = widget.existingBroker;
    _nameController = TextEditingController(text: broker?.name ?? '');
    _nationalIdController = TextEditingController(text: broker?.nationalId ?? '');
    _phoneController = TextEditingController(text: broker?.phone ?? '');
    _addressController = TextEditingController(text: broker?.address ?? '');
    _socialAccountController = TextEditingController(text: broker?.socialAccount ?? '');
    _noteController = TextEditingController(text: broker?.note ?? '');

    // Load existing image if in edit mode
    if (broker?.profileImagePath != null && broker!.profileImagePath!.isNotEmpty) {
      final file = File(broker.profileImagePath!);
      if (file.existsSync()) {
        _selectedImage = file;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _socialAccountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ကင်မရာ'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ပုံတ库'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('အမည်ကို ထည့်သွင်းပါ။')),
      );
      return false;
    }
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ဖုန်းနံပါတ်ကို ထည့်သွင်းပါ။')),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveBroker() async {
    if (!_validateForm()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      if (_isEditMode) {
        // Edit mode: update existing broker
        final existing = widget.existingBroker!;
        final updatedBroker = BrokerProfile(
          id: existing.id,
          name: _nameController.text,
          nationalId: _nationalIdController.text.isEmpty ? null : _nationalIdController.text,
          phone: _phoneController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          socialAccount: _socialAccountController.text.isEmpty ? null : _socialAccountController.text,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          profileImagePath: _selectedImage?.path ?? existing.profileImagePath,
          createdAt: existing.createdAt,
          updatedAt: now,
          isDeleted: false,
        );
        await LocalDb.saveBrokerProfile(updatedBroker);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ပွဲစားအချက်အလက် ပြုပြင်ပြီးပါပြီ။'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Add mode: create new broker
        final broker = BrokerProfile(
          id: const Uuid().v4(),
          name: _nameController.text,
          nationalId: _nationalIdController.text.isEmpty ? null : _nationalIdController.text,
          phone: _phoneController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          socialAccount: _socialAccountController.text.isEmpty ? null : _socialAccountController.text,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          profileImagePath: _selectedImage?.path,
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        );

        await LocalDb.saveBrokerProfile(broker);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ပွဲစားအချက်အလက် သိမ်းဆည်းပြီးပါပြီ။'),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('အမှားအယွင်း: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'ပွဲစားအချက်အလက် ပြုပြင်ခြင်း' : 'ပွဲစားအသစ် ထည့်သွင်းခြင်း'),
        backgroundColor: AppTheme.primaryAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Section
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: Colors.grey[600],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ပုံရိပ်ထည့်သွင်းခြင်း',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Form Fields
            _buildTextField('အမည်', _nameController, required: true),
            const SizedBox(height: 16),
            _buildTextField('မှတ်ပုံတင်နံပါတ်', _nationalIdController),
            const SizedBox(height: 16),
            _buildTextField('ဖုန်းနံပါတ်', _phoneController,
                required: true, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField('နေရပ်လိပ်စာ', _addressController, maxLines: 3),
            const SizedBox(height: 16),
            _buildTextField('လူမှုကွန်ရက်အကောင့်', _socialAccountController),
            const SizedBox(height: 16),
            _buildTextField('မှတ်ချက်', _noteController, maxLines: 3),
            const SizedBox(height: 32),
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveBroker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_isEditMode ? 'ပြုပြင်မည်' : 'သိမ်းမည်'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
