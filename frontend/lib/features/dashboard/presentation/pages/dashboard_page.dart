import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/di/injection_container.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late AuthService _authService;
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = getIt<AuthService>();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ထွက်ခွာခြင်း'),
        content: const Text('အကောင့်မှ ထွက်ခွာလိုသည်သည် သေချာပါသလား။'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ပယ်ဖျက်ခြင်း'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ထွက်ခွာခြင်း'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('အမြတ်သည့်ကျောင်း စုစုပေါင်း စီမံခန့်ခွဲမှု'),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('ထွက်ခွာခြင်း'),
                onTap: _handleLogout,
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ကြိုဆိုပါသည်',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentUser?['email'] ?? 'User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Module Grid
            Text(
              'အဓိကလုပ်ဆောင်ချက်များ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildModuleCard(
                  context,
                  icon: Icons.diamond,
                  title: 'ကျောင်းအုပ်စုများ',
                  subtitle: 'ကျောင်းအုပ်စုများ စီမံခန့်ခွဲခြင်း',
                  onTap: () => context.go('/inventory'),
                ),
                _buildModuleCard(
                  context,
                  icon: Icons.shopping_cart,
                  title: 'ရောင်းချမှု',
                  subtitle: 'ရောင်းချမှုများ မှတ်တမ်းတင်ခြင်း',
                  onTap: () => context.go('/sales'),
                ),
                _buildModuleCard(
                  context,
                  icon: Icons.money_off,
                  title: 'အသုံးစရိတ်များ',
                  subtitle: 'အသုံးစရိတ်များ ခွဲခြားခြင်း',
                  onTap: () => context.go('/expenses'),
                ),
                _buildModuleCard(
                  context,
                  icon: Icons.people,
                  title: 'အလုပ်သမားများ',
                  subtitle: 'အလုပ်သမားများ စီမံခန့်ခွဲခြင်း',
                  onTap: () => context.go('/workers'),
                ),
                _buildModuleCard(
                  context,
                  icon: Icons.store,
                  title: 'ခွဲခြင်းများ',
                  subtitle: 'ခွဲခြင်းများ စီမံခန့်ခွဲခြင်း',
                  onTap: () => context.go('/branches'),
                ),
                _buildModuleCard(
                  context,
                  icon: Icons.assessment,
                  title: 'အစီရင်ခံစာများ',
                  subtitle: 'အစီရင်ခံစာများ ကြည့်ရှုခြင်း',
                  onTap: () => context.go('/reports'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: AppTheme.primaryAccent,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
