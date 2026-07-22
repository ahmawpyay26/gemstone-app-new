import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/password_service.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _changeUsernameFormKey = GlobalKey<FormState>();
  final _changePasswordFormKey = GlobalKey<FormState>();

  late final TextEditingController _newUsername;
  late final TextEditingController _currentPassword;
  late final TextEditingController _newPassword;
  late final TextEditingController _confirmPassword;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoadingUsername = false;
  bool _isLoadingPassword = false;
  bool _isLoadingLogout = false;

  @override
  void initState() {
    super.initState();
    _newUsername = TextEditingController();
    _currentPassword = TextEditingController();
    _newPassword = TextEditingController();
    _confirmPassword = TextEditingController();
  }

  @override
  void dispose() {
    _newUsername.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _changeUsername() async {
    if (!_changeUsernameFormKey.currentState!.validate()) return;

    setState(() => _isLoadingUsername = true);

    try {
      final user = LocalDb.currentUser();
      final userId = user['id'] as String;
      final newUsername = _newUsername.text.trim();

      // Validate username
      final validationError = PasswordService.validateUsername(newUsername);
      if (validationError != null) {
        _showError(validationError);
        setState(() => _isLoadingUsername = false);
        return;
      }

      // Change username
      final success = await AuthService.changeUsername(
        userId: userId,
        newUsername: newUsername,
      );

      if (!success) {
        _showError('အသုံးပြုသူအမည် ပြောင်းလဲမှု ပျက်ကွက်ခဲ့ပါတယ်');
        setState(() => _isLoadingUsername = false);
        return;
      }

      // Update session
      final updatedUser = LocalDb.getUserById(userId);
      if (updatedUser != null) {
        LocalDb.saveSession(updatedUser);
      }

      _showSuccess('အသုံးပြုသူအမည် အောင်မြင်စွာ ပြောင်းလဲပြီးပါပြီ');
      _newUsername.clear();
      setState(() => _isLoadingUsername = false);
    } catch (e) {
      _showError('အမှားအယွင်းတစ်ခု ကျေးဇူးပြု၍ ထပ်မံကြိုးစားပါ');
      setState(() => _isLoadingUsername = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_changePasswordFormKey.currentState!.validate()) return;

    setState(() => _isLoadingPassword = true);

    try {
      final user = LocalDb.currentUser();
      final userId = user['id'] as String;
      final currentPassword = _currentPassword.text.trim();
      final newPassword = _newPassword.text.trim();

      // Validate new password
      final validationError = PasswordService.validatePassword(newPassword);
      if (validationError != null) {
        _showError(validationError);
        setState(() => _isLoadingPassword = false);
        return;
      }

      // Change password
      final success = await AuthService.changePassword(
        userId: userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!success) {
        _showError('လက်ရှိ password မှားနေပါတယ် သို့မဟုတ် ပြောင်းလဲမှု ပျက်ကွက်ခဲ့ပါတယ်');
        setState(() => _isLoadingPassword = false);
        return;
      }

      _showSuccess('Password အောင်မြင်စွာ ပြောင်းလဲပြီးပါပြီ။ ထပ်မံ လုပ်ဆောင်ရန် ပြန်လည် login ပြုလုပ်ပါ');

      // Clear fields
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();

      // Logout and redirect to login after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        AuthService.logout();
        context.go('/login');
      }
    } catch (e) {
      _showError('အမှားအယွင်းတစ်ခု ကျေးဇူးပြု၍ ထပ်မံကြိုးစားပါ');
      setState(() => _isLoadingPassword = false);
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout အတည်ပြုရန်'),
        content: const Text('အကောင့်မှ ထွက်ခွာလိုပါသလား?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ပယ်ဖျက်ရန်'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoadingLogout = true);

    try {
      // Clear session
      AuthService.logout();

      if (mounted) {
        // Navigate to login
        context.go('/login');
      }
    } catch (e) {
      _showError('Logout ပျက်ကွက်ခဲ့ပါတယ်');
      setState(() => _isLoadingLogout = false);
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
    final username = user['username'] as String? ?? '';
    final name = user['name'] as String? ?? 'Admin';

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('အကောင့် ဆက်တင်'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryAccent.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'အကောင့် အချက်အလက်',
                    style: TextStyle(
                      color: AppTheme.primaryAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'အမည်: $name',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'အသုံးပြုသူအမည်: $username',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'အခန်းကဏ္ဍ: ${user['role'] ?? 'owner'}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Change Username Section
            Text(
              'အသုံးပြုသူအမည် ပြောင်းလဲရန်',
              style: const TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _changeUsernameFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _newUsername,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'နည်းလမ်း အသုံးပြုသူအမည်',
                      hintText: 'အနည်းဆုံး အက္ခရာ ၃ လုံး',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'အသုံးပြုသူအမည် ထည့်သွင်းပါ';
                      }
                      return PasswordService.validateUsername(v.trim());
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoadingUsername ? null : _changeUsername,
                      child: _isLoadingUsername
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : const Text(
                              'အသုံးပြုသူအမည် ပြောင်းလဲမည်',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Change Password Section
            Text(
              'Password ပြောင်းလဲရန်',
              style: const TextStyle(
                color: AppTheme.primaryAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _changePasswordFormKey,
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
                              !_obscureCurrentPassword,
                        ),
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
                          () => _obscureNewPassword = !_obscureNewPassword,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'နည်းလမ်း Password ထည့်သွင်းပါ';
                      }
                      return PasswordService.validatePassword(v.trim());
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
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
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

                  // Change Password Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: _isLoadingPassword ? null : _changePassword,
                      child: _isLoadingPassword
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : const Text(
                              'Password ပြောင်းလဲမည်',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Padauk',
                                fontSize: 16,
                                height: 1.2,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoadingLogout ? null : _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: _isLoadingLogout
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        ),
      ),
    );
  }
}
