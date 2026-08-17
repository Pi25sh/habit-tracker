import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/providers/habit_provider.dart';
import '../../application/providers/background_provider.dart';
import '../../data/models/habit.dart';
import 'package:intl/intl.dart';
import 'create_habit_screen.dart';
import '../widgets/add_bg_dialog.dart';

class ShivaniDashboardScreen extends ConsumerWidget {
  const ShivaniDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitProvider).where((h) => !h.isPaused).toList();
    final bgUrl = ref.watch(backgroundProvider);

    return Scaffold(
      backgroundColor: bgUrl.isNotEmpty ? Colors.transparent : const Color(0xFFFDFCFB), // Very clean off-white
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Ciao, Shivani',
                        style: GoogleFonts.kalam(
                          fontSize: 42,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C3A5A), // Dark navy
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildWeatherIcon(),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Feature Grid
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 2.5,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _FeatureTile(icon: Icons.calendar_month_outlined, title: DateFormat('dd MMM, EEEE').format(DateTime.now()), color: const Color(0xFFFCF4E0), iconBgColor: const Color(0xFFFFB300), textColor: const Color(0xFF1C3A5A), hasBg: bgUrl.isNotEmpty),
                    _FeatureTile(icon: Icons.format_quote_rounded, title: 'Thoughts', color: const Color(0xFFF3F4E6), iconBgColor: const Color(0xFF81B053), textColor: const Color(0xFF1C3A5A), hasBg: bgUrl.isNotEmpty),
                    _FeatureTile(icon: Icons.favorite_border_rounded, title: 'Affirmations', color: const Color(0xFFEBF1F6), iconBgColor: const Color(0xFF6B92CB), textColor: const Color(0xFF1C3A5A), hasBg: bgUrl.isNotEmpty),
                    _FeatureTile(icon: Icons.notifications_none_rounded, title: 'Reminders', color: const Color(0xFFF4F6EC), iconBgColor: const Color(0xFF5A7851), textColor: const Color(0xFF1C3A5A), hasBg: bgUrl.isNotEmpty),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                      icon: Icons.image_outlined,
                      label: 'Add BG',
                      hasBg: bgUrl.isNotEmpty,
                      onTap: () => showAddBgDialog(context, ref),
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Add Habit',
                      hasBg: bgUrl.isNotEmpty,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => BackdropFilter(
                          filter: dart_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: const CreateHabitScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Habits List
                if (habits.isEmpty)
                  Column(
                    children: _placeholderHabits(),
                  )
                else
                  ...habits.map((habit) => _HabitRow(habit: habit, colorTheme: const Color(0xFF67793D))),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherIcon() {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Icon(Icons.wb_sunny, color: const Color(0xFFFFC107), size: 36),
          ),
          Positioned(
            bottom: 2,
            left: 0,
            child: Icon(Icons.cloud_outlined, color: const Color(0xFF1C3A5A), size: 36),
          ),
          Positioned(
            bottom: 4,
            left: 2,
            child: Icon(Icons.cloud, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  List<Widget> _placeholderHabits() {
    return [
      _HabitRow(habit: Habit(id: '1', name: 'Habit', icon: '', routine: 'Anytime', color: 0xFF5A7851), colorTheme: const Color(0xFF5A7851), bgColor: const Color(0xFFFCF4E0)), // Cream
      _HabitRow(habit: Habit(id: '2', name: 'Habit', icon: '', routine: 'Anytime', color: 0xFF5A7851), colorTheme: const Color(0xFF5A7851), bgColor: const Color(0xFFF3F4E6)), // Light green
      _HabitRow(habit: Habit(id: '3', name: 'Habit', icon: '', routine: 'Anytime', color: 0xFF4A5D33), colorTheme: const Color(0xFF4A5D33), bgColor: const Color(0xFFF4F6EC)), // Beige/olive
      _HabitRow(habit: Habit(id: '4', name: 'Habit', icon: '', routine: 'Anytime', color: 0xFF6B92CB), colorTheme: const Color(0xFF6B92CB), bgColor: const Color(0xFFEBF1F6)), // Light blue
      _HabitRow(habit: Habit(id: '5', name: 'Habit', icon: '', routine: 'Anytime', color: 0xFF1C3A5A), colorTheme: const Color(0xFF1C3A5A), bgColor: const Color(0xFFEBF1F6)), // Light blue
    ];
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color iconBgColor;
  final Color textColor;
  final bool hasBg;

  const _FeatureTile({required this.icon, required this.title, required this.color, required this.iconBgColor, required this.textColor, this.hasBg = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: hasBg ? color.withValues(alpha: 0.75) : color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.kalam(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool hasBg;

  const _ActionButton({required this.icon, required this.label, required this.onTap, this.hasBg = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: hasBg ? const Color(0xFFFFE182).withValues(alpha: 0.75) : const Color(0xFFFFE182), // Exact yellow from screenshot
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF1C3A5A), size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.kalam(
                fontSize: 20,
                color: const Color(0xFF1C3A5A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitRow extends ConsumerWidget {
  final Habit habit;
  final Color colorTheme;
  final Color? bgColor;

  const _HabitRow({required this.habit, required this.colorTheme, this.bgColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if completed today
    final today = DateTime.now();
    final isCompletedToday = habit.completedDates.any((d) => 
      d.year == today.year && d.month == today.month && d.day == today.day
    );
    final bgMap = ref.watch(backgroundProvider);
    final hasBg = bgMap.isNotEmpty; // For simplicity in dashboard, if any bg is active (or check index 0)
    final baseColor = bgColor ?? const Color(0xFFF9FAF7);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: hasBg ? dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: hasBg ? baseColor.withValues(alpha: 0.75) : baseColor,
            borderRadius: BorderRadius.circular(16),
          ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              ref.read(habitProvider.notifier).toggleHabitCompletion(habit, DateTime.now());
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompletedToday ? colorTheme : Colors.transparent,
                border: Border.all(color: colorTheme, width: 2.0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isCompletedToday 
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              habit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.kalam(
                fontSize: 20,
                color: const Color(0xFF1C3A5A),
                fontWeight: FontWeight.w500,
                decoration: isCompletedToday ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 11 * 18.0, // Approximate width for the 11 boxes
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                11,
                (index) {
                  // Calculate date for this box (index 10 is today, index 0 is 10 days ago)
                  final dateForBox = today.subtract(Duration(days: 10 - index));
                  final isCompletedOnDate = habit.completedDates.any((d) => 
                    d.year == dateForBox.year && d.month == dateForBox.month && d.day == dateForBox.day
                  );
                  
                  return Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isCompletedOnDate ? colorTheme : Colors.transparent,
                      border: Border.all(color: colorTheme.withValues(alpha: 0.6), width: 1.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}
