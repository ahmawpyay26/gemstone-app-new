import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentPassword;
  late final TextEditingController _newPassword;
  late final TextEditingController _confirmPassword;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPassword = TextEditingController();
    _newPassword = TextEditingController();
    _confirmPassword = TextEditingController();
  }

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = LocalDb.currentUser();
      final email = user['email'] as String;

      // Verify current password
      final loggedInUser = LocalDb.login(email, _currentPassword.text.trim());
      if (loggedInUser == null) {
        _showError('လက်ရှိ password မှားနေပါတယ်');
        setState(() => _isLoading = false);
        return;
      }

      // Update password in database
      final users = LocalDb.users();
      for (final key in users.keys) {
        final u = users.get(key);
        if (u != null && u.email.toLowerCase() == email.toLowerCase()) {
          u.password = _newPassword.text.trim();
          await users.put(key, u);
          break;
        }
      }

      _showSuccess('Password အောင်မြင်စွာ ပြောင်းလဲပြီးပါပြီ');
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
    } catch (e) {
      _showError('အမှားအယွင်းတစ်ခု ကျေးဇူးပြု၍ ထပ်မံကြိုးစားပါ');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = LocalDb.currentUser();
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('အကောင့် ဆက်တင်'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/dashboard')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primaryAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('အကောင့် အချက်အလက်',
                      style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('အမည်: ${user['name'] ?? 'Admin'}',
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('အီမေးလ်: ${user['email'] ?? ''}',
                      style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 8),
                  Text('အခန်းကဏ္ဍ: ${user['role'] ?? 'owner'}',
                      style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Password Change Form
            Text('Password ပြောင်းလဲရန်',
                style: const TextStyle(
                    color: AppTheme.primaryAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Current Password
                  TextFormField(
                    controller: _currentPassword,
                    obscureText: _obscureCurrentPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'လက်ရှိ Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppTheme.primaryAccent,
                        ),
                        onPressed: () => setState(
                            () => _obscureCurrentPassword =
                                !_obscureCurrentPassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Password ထည့်သွင်းပါ'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // New Password
                  TextFormField(
                    controller: _newPassword,
                    obscureText: _obscureNewPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'နည်းလမ်း Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppTheme.primaryAccent,
                        ),
                        onPressed: () => setState(
                            () => _obscureNewPassword = !_obscureNewPassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'နည်းလမ်း Password ထည့်သွင်းပါ';
                      }
                      if (v.length < 6) {
                        return 'Password သည် အနည်းဆုံး အက္ခရာ ၆ လုံး ရှိရမည်';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password အတည်ပြုရန်',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppTheme.primaryAccent,
                        ),
                        onPressed: () => setState(() =>
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Password အတည်ပြုရန် ထည့်သွင်းပါ';
                      }
                      if (v != _newPassword.text) {
                        return 'Password များ မကိုက်ညီပါ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black),
                              ),
                            )
                          : const Text('Password ပြောင်းလဲမည်',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
