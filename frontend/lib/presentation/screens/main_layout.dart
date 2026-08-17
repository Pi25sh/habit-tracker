import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/navigation_provider.dart';
import '../../application/providers/background_provider.dart';
import 'calendar_screen.dart';
import 'journal_screen.dart';
import 'settings_screen.dart';
import 'shivani_dashboard_screen.dart';
import 'thoughts_screen.dart';
import 'todo_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  final List<Widget> _screens = const [
    ShivaniDashboardScreen(),
    JournalScreen(),
    TodoScreen(),
    ThoughtsScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final bgMap = ref.watch(backgroundProvider);
    final bgUrl = bgMap[currentIndex] ?? '';

    Widget body = IndexedStack(
      index: currentIndex,
      children: _screens,
    );

    if (bgUrl.isNotEmpty) {
      ImageProvider imageProvider;
      if (bgUrl.startsWith('base64,')) {
        final base64String = bgUrl.substring(7);
        imageProvider = MemoryImage(base64Decode(base64String));
      } else {
        imageProvider = NetworkImage(bgUrl);
      }

      body = Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
            // Removed colorFilter to let the background be fully visible
          ),
        ),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: bgUrl.isNotEmpty ? Colors.transparent : const Color(0xFFFBF9F7), // Soft warm background
      body: body,
      extendBody: true, // Needed for transparent bottom nav
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: bgUrl.isNotEmpty ? Colors.white.withValues(alpha: 0.7) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                selected: currentIndex == 0,
                activeColor: const Color(0xFFE9D57D), // Yellow
                onTap: () => ref.read(navigationIndexProvider.notifier).state = 0,
              ),
              _NavItem(
                icon: Icons.book_outlined,
                activeIcon: Icons.book_rounded,
                selected: currentIndex == 1,
                activeColor: const Color(0xFF5A7851), // Deep green
                onTap: () => ref.read(navigationIndexProvider.notifier).state = 1,
              ),
              _NavItem(
                icon: Icons.event_note_outlined,
                activeIcon: Icons.event_note_rounded,
                selected: currentIndex == 2,
                activeColor: const Color(0xFF5A7851), // Deep green (Bucket list)
                onTap: () => ref.read(navigationIndexProvider.notifier).state = 2,
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                selected: currentIndex == 3,
                activeColor: const Color(0xFF6B92CB), // Soft Blue (Thoughts)
                onTap: () => ref.read(navigationIndexProvider.notifier).state = 3,
              ),
              _NavItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today_rounded,
                selected: currentIndex == 4,
                activeColor: const Color(0xFF284F8F), // Navy blue
                onTap: () => ref.read(navigationIndexProvider.notifier).state = 4,
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                selected: currentIndex == 5,
                activeColor: const Color(0xFF2E2540), // Dark Navy
                onTap: () => ref.read(navigationIndexProvider.notifier).state = 5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = const Color(0xFF433E47).withValues(alpha: 0.5);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Icon(
          selected ? activeIcon : icon,
          size: 28,
          color: selected ? activeColor : inactiveColor,
        ),
      ),
    );
  }
}
