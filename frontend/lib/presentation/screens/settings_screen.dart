import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/passcode_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'passcode_screen.dart';
import '../../application/providers/habit_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(loginProvider.notifier).logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PasscodeScreen()),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Aesthetic',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: AppThemeType.values.map((themeType) {
                  final isSelected = currentTheme == themeType;
                  return GestureDetector(
                    onTap: () {
                      ref.read(themeProvider.notifier).setTheme(themeType);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        themeType.name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: colors.secondary.withOpacity(0.2),
              child: const Text('🌸', style: TextStyle(fontSize: 50)),
            ),
            const SizedBox(height: 16),
            Text(
              'Shivani\'s Space',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 48),
            
            _buildSettingsTile(
              context,
              icon: Icons.person_outline,
              title: 'Account Info',
              subtitle: 'Logged in as shivani',
              color: colors.primary,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showThemePicker(context, ref),
              child: _buildSettingsTile(
                context,
                icon: Icons.color_lens_outlined,
                title: 'Aesthetic',
                subtitle: 'Tap to change theme',
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              context,
              icon: Icons.notifications_active_outlined,
              title: 'Notifications',
              subtitle: 'Daily reminders',
              color: Colors.orangeAccent,
            ),
            
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Integrations & Backup',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                final habits = ref.read(habitProvider);
                final jsonStr = jsonEncode(habits.map((h) => h.toJson()).toList());
                Clipboard.setData(ClipboardData(text: jsonStr));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Backup JSON copied to clipboard!')),
                );
              },
              child: _buildSettingsTile(
                context,
                icon: Icons.cloud_download_outlined,
                title: 'Cloud Backup / Restore',
                subtitle: 'Export data to JSON',
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              context,
              icon: Icons.calendar_month_outlined,
              title: 'Calendar Integration',
              subtitle: 'Sync to Google/Apple Calendar',
              color: Colors.green,
              isToggle: true,
              toggleValue: true, // Mocked as active
            ),
            
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enterprise & Privacy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              context,
              icon: Icons.location_on_outlined,
              title: 'Find My Device',
              subtitle: 'Consent-gated location sharing',
              color: Colors.redAccent,
              isToggle: true,
              toggleValue: false,
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              context,
              icon: Icons.camera_alt_outlined,
              title: 'Remote Camera Requests',
              subtitle: 'Require approval for camera access',
              color: Colors.purple,
              isToggle: true,
              toggleValue: true,
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              context,
              icon: Icons.api_outlined,
              title: 'API & Webhooks',
              subtitle: 'Zapier, n8n, IFTTT access',
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            _buildSettingsTile(
              context,
              icon: Icons.admin_panel_settings_outlined,
              title: 'Admin Dashboard',
              subtitle: 'Manage family devices',
              color: Colors.blueGrey,
            ),
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context, ref),
                icon: const Icon(Icons.lock_outline, color: Colors.redAccent),
                label: const Text('Lock App', style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isToggle = false,
    bool toggleValue = false,
  }) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          if (isToggle) 
            Switch(
              value: toggleValue,
              onChanged: (val) {
                // Mock toggle change
              },
              activeColor: color,
            )
          else
            Icon(Icons.chevron_right, color: textColor.withOpacity(0.3)),
        ],
      ),
    );
  }
}
