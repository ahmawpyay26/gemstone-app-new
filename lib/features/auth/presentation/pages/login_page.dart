import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/password_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/audit_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Do not pre-fill credentials for security/privacy reasons
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      // Try AppUser (Super Admin) first
      final userBox = Hive.box<AppUser>(LocalDb.usersBox);
      AppUser? appUser;
      for (final user in userBox.values) {
        if (user.username == username) {
          appUser = user;
          break;
        }
      }

      if (appUser != null && PasswordService.verifyPassword(password, appUser.passwordHash)) {
        // Super Admin login successful
        await PermissionService.setCurrentUser(appUser, 'AppUser');
        await AuditService.log(action: AuditService.login);
        LocalDb.saveSession(appUser);

        if (mounted) {
          context.go('/dashboard');
        }
        return;
      }

      // Try StaffUser
      final staffBox = Hive.box<StaffUser>(LocalDb.staffUsersBox);
      StaffUser? staff;
      for (final s in staffBox.values) {
        if (s.username == username) {
          staff = s;
          break;
        }
      }

      if (staff != null) {
        if (!staff.isActive) {
          setState(() {
            _errorMessage = 'ဤအကောင့် ပိတ်ထားသည်';
            _isLoading = false;
          });
          return;
        }

        if (PasswordService.verifyPassword(password, staff.passwordHash)) {
          // Staff login successful
          await PermissionService.setCurrentUser(staff, 'StaffUser');
          await AuditService.log(action: AuditService.login);

          // Update last login time
          final index = staffBox.values.toList().indexOf(staff);
          final updated = StaffUser(
            id: staff.id,
            fullName: staff.fullName,
            username: staff.username,
            passwordHash: staff.passwordHash,
            phoneNumber: staff.phoneNumber,
            position: staff.position,
            roleId: staff.roleId,
            permissionIds: staff.permissionIds,
            isActive: staff.isActive,
            createdAt: staff.createdAt,
            updatedAt: staff.updatedAt,
            createdBy: staff.createdBy,
            lastLoginAt: DateTime.now().millisecondsSinceEpoch,
          );
          await staffBox.putAt(index, updated);
          LocalDb.saveStaffSession(updated);

          if (mounted) {
            context.go('/dashboard');
          }
          return;
        }
      }

      // Login failed
      setState(() {
        _errorMessage = 'အသုံးပြုသူအမည် သို့မဟုတ် စကားဝှက် မှားယွင်းနေပါသည်';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Login error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // Logo / Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryAccent, width: 2),
                ),
                child: const Icon(Icons.diamond,
                    color: AppTheme.primaryAccent, size: 48),
              ),
              const SizedBox(height: 24),

              Text(
                'ကျောက်မျက် စီမံခန့်ခွဲမှု',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'အကောင့်ဝင်ရန် အချက်အလက်ဖြည့်ပါ',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[400],
                    ),
              ),
              const SizedBox(height: 40),

              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    border: Border.all(color: Colors.red, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      enabled: !_isLoading,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'အသုံးပြုသူအမည်',
                        hintText: 'admin',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'အသုံးပြုသူအမည်ထည့်ပါ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      enabled: !_isLoading,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'စကားဝှက်',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'စကားဝှက်ထည့်ပါ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryAccent,
                          disabledBackgroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'ဝင်ရောက်မည်',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
