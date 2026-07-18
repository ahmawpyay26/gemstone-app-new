import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../../../core/theme/app_theme.dart';

/// Business Profile page — allows the user to set shop name, logo,
/// phone, address, and optional social/contact fields.
/// Only ONE BusinessProfile exists (singleton key: 'profile').
class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({Key? key}) : super(key: key);

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _shopName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _email;
  late final TextEditingController _facebook;
  late final TextEditingController _viber;
  late final TextEditingController _website;

  String? _logoPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = LocalDb.getBusinessProfile();
    _shopName = TextEditingController(text: profile.shopName);
    _phone = TextEditingController(text: profile.phone ?? '');
    _address = TextEditingController(text: profile.address ?? '');
    _email = TextEditingController(text: profile.email ?? '');
    _facebook = TextEditingController(text: profile.facebook ?? '');
    _viber = TextEditingController(text: profile.viber ?? '');
    _website = TextEditingController(text: profile.website ?? '');
    _logoPath = profile.logoPath;
  }

  @override
  void dispose() {
    _shopName.dispose();
    _phone.dispose();
    _address.dispose();
    _email.dispose();
    _facebook.dispose();
    _viber.dispose();
    _website.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _logoPath = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ဓာတ်ပုံ ရွေးချယ်၍မရပါ: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showLogoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryAccent),
              title: const Text('ကင်မရာ', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickLogo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryAccent),
              title: const Text('ဓာတ်ပုံ Gallery', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickLogo(ImageSource.gallery);
              },
            ),
            if (_logoPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                title: const Text('Logo ဖျက်မည်', style: TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _logoPath = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final profile = BusinessProfile(
        shopName: _shopName.text.trim(),
        logoPath: _logoPath,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        facebook: _facebook.text.trim().isEmpty ? null : _facebook.text.trim(),
        viber: _viber.text.trim().isEmpty ? null : _viber.text.trim(),
        website: _website.text.trim().isEmpty ? null : _website.text.trim(),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await LocalDb.saveBusinessProfile(profile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ဆိုင်အချက်အလက် သိမ်းဆည်းပြီးပါပြီ'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('သိမ်းဆည်း၍မရပါ: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'ဆိုင်အချက်အလက်',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppTheme.primaryAccent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo section
              _buildLogoSection(),
              const SizedBox(height: 24),
              // Required fields
              _buildSectionHeader('အဓိကအချက်အလက်'),
              const SizedBox(height: 12),
              _buildField(
                controller: _shopName,
                label: 'ဆိုင်အမည် *',
                icon: Icons.store,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'ဆိုင်အမည် ထည့်ပေးပါ' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _phone,
                label: 'ဖုန်းနံပါတ်',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _address,
                label: 'လိပ်စာ',
                icon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              // Optional fields
              _buildSectionHeader('ဆက်သွယ်ရေး (ရွေးချယ်ရန်)'),
              const SizedBox(height: 12),
              _buildField(
                controller: _email,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _facebook,
                label: 'Facebook',
                icon: Icons.facebook,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _viber,
                label: 'Viber',
                icon: Icons.chat,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _website,
                label: 'Website',
                icon: Icons.language,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 32),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryDark,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'သိမ်းဆည်းနေသည်...' : 'သိမ်းဆည်းမည်'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: AppTheme.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showLogoOptions,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryAccent, width: 2),
              ),
              child: ClipOval(
                child: _logoPath != null && File(_logoPath!).existsSync()
                    ? Image.file(
                        File(_logoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.business,
                          size: 48,
                          color: AppTheme.primaryAccent,
                        ),
                      )
                    : const Icon(
                        Icons.business,
                        size: 48,
                        color: AppTheme.primaryAccent,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _showLogoOptions,
            icon: const Icon(Icons.edit, size: 16, color: AppTheme.primaryAccent),
            label: const Text(
              'Logo ပြောင်းမည်',
              style: TextStyle(color: AppTheme.primaryAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.primaryAccent,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryAccent, size: 20),
        filled: true,
        fillColor: AppTheme.surfaceDark,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.secondaryAccent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.secondaryAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
      ),
    );
  }
}
