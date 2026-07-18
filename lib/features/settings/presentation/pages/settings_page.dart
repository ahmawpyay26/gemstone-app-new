import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../pages/rca_debug_logs_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentPassword;
  late final TextEditingController _newPassword;
  late final TextEditingController _confirmPassword;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentPassword = TextEditingController();
    _newPassword = TextEditingController();
    _confirmPassword = TextEditingController();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _tabController.dispose();
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

  String _formatDate(int timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'DELETE_SALE':
        return 'ရောင်းချမှု ဖျက်ခြင်း';
      case 'ADD_SALE':
        return 'ရောင်းချမှု ထည့်သွင်းခြင်း';
      case 'EDIT_SALE':
        return 'ရောင်းချမှု ပြင်ဆင်ခြင်း';
      case 'ADD_PURCHASE':
        return 'ဝယ်ယူခြင်း ထည့်သွင်းခြင်း';
      case 'EDIT_PURCHASE':
        return 'ဝယ်ယူခြင်း ပြင်ဆင်ခြင်း';
      case 'DELETE_PURCHASE':
        return 'ဝယ်ယူခြင်း ဖျက်ခြင်း';
      default:
        return action;
    }
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
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/dashboard')),
        backgroundColor: AppTheme.primaryDark,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.red,
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'RCA BUILD a11d19c',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'အကောင့် အချက်အလက်'),
                  Tab(text: 'အကျင့်စာရင်း'),
                  Tab(text: 'ဖျက်ထားသော အရောင်း'),
                  Tab(text: 'RCA Debug Logs'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Account Settings
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // RCA Debug Logs Direct Access Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RCADebugLogsPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Open RCA Debug Logs',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),

                // Business Profile Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/business-profile'),
                    icon: const Icon(Icons.store, color: AppTheme.primaryDark),
                    label: const Text(
                      'ဆိုင်အချက်အလက် ပြင်ဆင်မည်',
                      style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAccent,
                            disabledBackgroundColor: Colors.grey,
                          ),
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

          // Tab 2: Audit Log
          ValueListenableBuilder(
            valueListenable: LocalDb.auditLogs().listenable(),
            builder: (context, Box<AuditLog> box, _) {
              final logs = LocalDb.getAllAuditLogs();
              
              if (logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'အကျင့်စာရင်း မရှိသေးပါ',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryAccent.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Action
                        Row(
                          children: [
                            Icon(
                              log.action.contains('DELETE')
                                  ? Icons.delete
                                  : log.action.contains('ADD')
                                      ? Icons.add_circle
                                      : Icons.edit,
                              color: log.action.contains('DELETE')
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getActionLabel(log.action),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Gemstone Name
                        if (log.gemstoneName != null && log.gemstoneName!.isNotEmpty)
                          Text(
                            'ကျောက်: ${log.gemstoneName}',
                            style: TextStyle(color: Colors.grey[300]),
                          ),

                        // Quantity and Amount
                        if (log.quantity != null || log.amount != null)
                          Row(
                            children: [
                              if (log.quantity != null)
                                Expanded(
                                  child: Text(
                                    'အလုံးရေ: ${log.quantity}',
                                    style: TextStyle(color: Colors.grey[300]),
                                  ),
                                ),
                              if (log.amount != null)
                                Expanded(
                                  child: Text(
                                    'အငွေ: ${log.amount}',
                                    style: TextStyle(color: Colors.grey[300]),
                                  ),
                                ),
                            ],
                          ),

                        const SizedBox(height: 8),

                        // User and Timestamp
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'အသုံးပြုသူ: ${log.userName}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDate(log.timestamp),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        // Details
                        if (log.details.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              log.details,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          
          // Tab 3: Deleted Sales
          ValueListenableBuilder(
            valueListenable: LocalDb.sales().listenable(),
            builder: (context, Box<Sale> box, _) {
              final deletedSales = LocalDb.getDeletedSales();
              final sortedSales = deletedSales.toList()..sort((a, b) => (b.deletedAt ?? 0).compareTo(a.deletedAt ?? 0));
              
              if (sortedSales.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text('ဖျက်ထားသော အရောင်း မရှိသေးပါ',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: sortedSales.length,
                itemBuilder: (context, index) {
                  final sale = sortedSales[index];
                  final isAdmin = LocalDb.currentUser()['role'] == 'admin' || LocalDb.currentUser()['role'] == 'owner';
                  
                  return Card(
                    color: AppTheme.surfaceDark,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with gemstone name and delete date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sale.gemstoneName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ဖျက်သည့်နေ့: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(sale.deletedAt ?? 0))}',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (isAdmin)
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        backgroundColor: AppTheme.surfaceDark,
                                        title: const Text('အရောင်းမှတ်တမ်း ပြန်လည်ရယူမည်'),
                                        content: const Text('ဤအရောင်းမှတ်တမ်းကို ပြန်လည်ရယူမှာ သေချာပါသလား?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(c, false),
                                            child: const Text('မလုပ်တော့ပါ'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(c, true),
                                            child: const Text('ပြန်လည်ရယူမည်',
                                              style: TextStyle(color: AppTheme.successColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ) ?? false;
                                    
                                    if (ok) {
                                      try {
                                        final key = box.keys.firstWhere((k) => box.get(k)?.id == sale.id);
                                        await LocalDb.restoreSale(key);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('အရောင်းမှတ်တမ်း ပြန်လည်ရယူပြီးပါပြီ')),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('အမှားအယွင်း: $e')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successColor,
                                    foregroundColor: Colors.black,
                                  ),
                                  icon: const Icon(Icons.restore, size: 16),
                                  label: const Text('ပြန်လည်ရယူ', style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Details
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('အလုံးရေ: ${sale.quantity}', style: TextStyle(color: Colors.grey[300])),
                              Text('အငွေ: ${NumberFormat('#,##0', 'en_US').format(sale.amount)} ကျပ်', style: TextStyle(color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Deleted by and reason
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ဖျက်သူ: ${sale.deletedBy ?? 'Unknown'}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              if (sale.deleteReason != null && sale.deleteReason!.isNotEmpty)
                                Text('ကြောင့်: ${sale.deleteReason}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          
          // Tab 4: RCA Debug Logs
          const RCADebugLogsPage(),
        ],
      ),
    );
  }
}
