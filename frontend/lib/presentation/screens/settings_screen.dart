import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../application/providers/background_provider.dart';
import '../../presentation/widgets/profile_card.dart';
import '../../presentation/widgets/settings_row.dart';
import 'notification_scheduling_screen.dart';
import 'profile_screen.dart';

/// Settings — Profile card, Preferences, Data & Privacy and Support,
/// with the Warm / Sage / Lavender / Dark theme picker.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgUrl = ref.watch(backgroundProvider);

    return Scaffold(
      backgroundColor: bgUrl.isNotEmpty ? Colors.transparent : const Color(0xFFF4F0F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2E2540),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
        children: [
          // Profile
          ProfileCard(
            name: 'Shivani',
            subtitle: 'shivani@example.com',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),

          const SizedBox(height: 28),

          _SectionLabel('Account'),
          const SizedBox(height: 12),
          _SettingsGroup(
            children: [
              SettingsRow(
                title: 'Theme',
                icon: Icons.palette_outlined,
                onTap: () => _showThemePicker(context, ref),
              ),
              SettingsRow(
                title: 'Notification',
                icon: Icons.notifications_none,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSchedulingScreen(),
                  ),
                ),
              ),
              SettingsRow(
                title: 'Lock',
                icon: Icons.lock_outline,
                onTap: () => _comingSoon(context),
              ),
            ],
            hasBg: bgUrl.isNotEmpty,
          ),

          const SizedBox(height: 32),

          _SectionLabel('Other'),
          const SizedBox(height: 12),
          _SettingsGroup(
            children: [
              SettingsRow(
                title: 'App Help',
                icon: Icons.help_outline,
                onTap: () => _aboutDialog(context),
              ),
              SettingsRow(
                title: 'Sign Out',
                icon: Icons.logout,
                onTap: () => _comingSoon(context),
              ),
            ],
            hasBg: bgUrl.isNotEmpty,
          ),
        ],
      ),
    );
  }

  static String _themeLabel(AppThemeType type) {
    switch (type) {
      case AppThemeType.warm:
        return 'Warm Cream';
      case AppThemeType.sage:
        return 'Mint Green';
      case AppThemeType.lavender:
        return 'Lavender';
      case AppThemeType.dark:
        return 'Dark';
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose Theme',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              for (final type in AppThemeType.values)
                ListTile(
                  leading: _ThemeSwatch(type: type, size: 34),
                  title: Text(_themeLabel(type)),
                  trailing: ref.watch(themeProvider) == type
                      ? const Icon(Icons.check_circle, color: Color(0xFF65508A))
                      : null,
                  onTap: () {
                    ref.read(themeProvider.notifier).setTheme(type);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This is coming soon 🌿'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _aboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About Habii'),
        content: const Text(
          'A private habit tracker and journal, made with care for Shivani. '
          'Warm paper, sage greens and a little doodle soul. 🌿',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Color(0xFF1E2420),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final bool hasBg;

  const _SettingsGroup({required this.children, this.hasBg = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: hasBg ? dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          decoration: BoxDecoration(
            color: hasBg ? Colors.white.withValues(alpha: 0.75) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: hasBg ? Colors.white.withValues(alpha: 0.2) : Colors.transparent),
            boxShadow: [
              if (!hasBg)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final AppThemeType type;
  final double size;

  const _ThemeSwatch({required this.type, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.themes[type]!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: colors.background, width: 3),
      ),
    );
  }
}
