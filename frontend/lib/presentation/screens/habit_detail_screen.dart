import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/providers/habit_provider.dart';
import '../../data/models/habit.dart';
import '../../presentation/widgets/app_card.dart';
import '../../presentation/widgets/progress_dots.dart';
import 'create_habit_screen.dart';

/// Habit Detail — a quiet stats page for a single habit:
/// weekly circles, monthly progress bar, streak and an inspirational card.
class HabitDetailScreen extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  Habit get _current => ref.watch(habitProvider).firstWhere(
        (h) => h.id == widget.habit.id,
        orElse: () => widget.habit,
      );

  int _completedThisWeek(Habit h) {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    int count = 0;
    for (var i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final done = h.completedDates.any(
        (c) => c.year == d.year && c.month == d.month && c.day == d.day,
      );
      if (h.repeatDays.contains(d.weekday) && done) count++;
    }
    return count;
  }

  (int, int) _monthlyProgress(Habit h) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    int scheduled = 0;
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      if (h.repeatDays.contains(d.weekday)) scheduled++;
    }
    int completed = 0;
    for (final c in h.completedDates) {
      if (c.year == now.year && c.month == now.month) completed++;
    }
    return (completed, scheduled);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final h = _current;
    final (completedMonth, scheduledMonth) = _monthlyProgress(h);
    final monthPercent =
        scheduledMonth == 0 ? 0.0 : (completedMonth / scheduledMonth).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Habit Detail',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          // Header card
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(h.color).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(h.icon ?? '🌱', style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        h.routine,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateHabitScreen(editHabit: h),
                      ),
                    );
                  },
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // This week
          _Section('This Week'),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: ProgressDots(
              completed: _completedThisWeek(h),
              total: h.repeatDays.isEmpty ? 7 : h.repeatDays.length,
              dotSize: 24,
            ),
          ),

          const SizedBox(height: 24),

          // Monthly progress
          _Section('Monthly Progress'),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedMonth/$scheduledMonth days',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      '${(monthPercent * 100).round()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: monthPercent,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFDDE8D9),
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Streak
          _Section('Streak'),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${h.currentStreak} days',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      'Longest: ${h.longestStreak} days',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Inspirational card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFDDE8D9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '"Consistency is the key to progress."',
                    style: GoogleFonts.caveat(
                      fontSize: 22,
                      height: 1.3,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: scheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}
