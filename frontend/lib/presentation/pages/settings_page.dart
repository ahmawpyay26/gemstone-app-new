import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: const Text('SETTINGS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: AppTheme.primaryAccent,
                    child: Icon(Icons.person, size: 40, color: AppTheme.primaryDark),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ဦးကျော်ကျော်',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const Text(
                          'Owner / Administrator',
                          style: TextStyle(color: AppTheme.primaryAccent, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'kyawkyaw@gemstone.com',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryAccent),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Categories
            _buildSettingSection('အကောင့်စီမံခန့်ခွဲမှု', [
              _buildSettingTile(Icons.security, 'Password ပြောင်းလဲရန်'),
              _buildSettingTile(Icons.people_outline, 'အသုံးပြုသူများ စီမံရန် (Multi-user)'),
              _buildSettingTile(Icons.notifications_none, 'အကြောင်းကြားချက်များ'),
            ]),
            const SizedBox(height: 16),
            _buildSettingSection('လုပ်ငန်းဆက်တင်များ', [
              _buildSettingTile(Icons.precision_manufacturing_outlined, 'စက်ပစ္စည်းများ စာရင်း'),
              _buildSettingTile(Icons.badge_outlined, 'လုပ်သားများ စာရင်း'),
              _buildSettingTile(Icons.handshake_outlined, 'ပွဲစားများ စာရင်း'),
              _buildSettingTile(Icons.currency_exchange, 'ငွေကြေးဆက်တင်များ (Currency)'),
            ]),
            const SizedBox(height: 16),
            _buildSettingSection('စနစ်ဆက်တင်များ', [
              _buildSettingTile(Icons.sync, 'Cloud Sync & Backup'),
              _buildSettingTile(Icons.language, 'ဘာသာစကား (Language)'),
              _buildSettingTile(Icons.info_outline, 'App အကြောင်း'),
            ]),
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                label: const Text('LOGOUT', style: TextStyle(color: AppTheme.errorColor)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Version 1.0.0 (Enterprise Edition)',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryAccent, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.surfaceLight, size: 20),
      onTap: () {},
    );
  }
}
