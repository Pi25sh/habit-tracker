import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/providers/habit_provider.dart';
import '../../data/models/habit.dart';
import '../../presentation/widgets/app_card.dart';
import 'create_habit_screen.dart';

/// Clean details view for a Habit, matching the "Habit Detail" screen in the reference.
class HabitDetailsScreen extends ConsumerWidget {
  final Habit habit;

  const HabitDetailsScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    // Get latest habit data from provider
    final currentHabit = ref.watch(habitProvider).firstWhere(
          (h) => h.id == habit.id,
          orElse: () => habit,
        );

    // Calculate this week's data
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (index) => monday.add(Duration(days: index)));
    
    // Calculate monthly data
    final startOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final scheduledDaysInMonth = _calculateScheduledDays(startOfMonth, daysInMonth, currentHabit.repeatDays);
    final completedInMonth = _calculateCompletedInPeriod(startOfMonth, DateTime(now.year, now.month, daysInMonth), currentHabit);
    final monthlyProgress = scheduledDaysInMonth == 0 ? 0.0 : (completedInMonth / scheduledDaysInMonth).clamp(0.0, 1.0);

    // Calculate streak
    final streak = _calculateCurrentStreak(currentHabit);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: scheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Habit Detail',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
        children: [
          // Header (Icon, Title, Edit)
          Row(
            children: [
              Text(currentHabit.icon ?? '💧', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  currentHabit.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateHabitScreen(editHabit: currentHabit),
                    ),
                  );
                },
                child: Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          // This Week section
          Text(
            'This Week',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final date = weekDays[index];
              final isScheduled = currentHabit.repeatDays.isEmpty || currentHabit.repeatDays.contains(date.weekday);
              final isCompleted = currentHabit.completedDates.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
              final dayLabel = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7];

              return Column(
                children: [
                  Icon(
                    Icons.water_drop,
                    color: isCompleted
                        ? scheme.primary
                        : (isScheduled ? scheme.onSurface.withValues(alpha: 0.2) : scheme.onSurface.withValues(alpha: 0.05)),
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              );
            }),
          ),
          
          const SizedBox(height: 36),

          // Monthly Progress section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                '$completedInMonth/$scheduledDaysInMonth days',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: monthlyProgress,
              minHeight: 10,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),

          const SizedBox(height: 36),

          // Streak Card
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Streak',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  '$streak days',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quote Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFDDE8D9), // Pastel botanical green
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Consistency is the\nkey to progress.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: const Color(0xFF342D28),
                    ),
                  ),
                ),
                // Stylized botanical element 🌿
                Icon(
                  Icons.spa_outlined,
                  size: 48,
                  color: scheme.primary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateScheduledDays(DateTime start, int daysInMonth, List<int> repeatDays) {
    if (repeatDays.isEmpty) return daysInMonth; // Every day
    int count = 0;
    for (int i = 0; i < daysInMonth; i++) {
      final d = start.add(Duration(days: i));
      if (repeatDays.contains(d.weekday)) count++;
    }
    return count;
  }

  int _calculateCompletedInPeriod(DateTime start, DateTime end, Habit habit) {
    return habit.completedDates.where((d) => 
      (d.isAfter(start.subtract(const Duration(days: 1))) && 
       d.isBefore(end.add(const Duration(days: 1))))
    ).length;
  }

  int _calculateCurrentStreak(Habit habit) {
    if (habit.completedDates.isEmpty) return 0;
    
    // Sort dates descending
    final sorted = List<DateTime>.from(habit.completedDates)
      ..sort((a, b) => b.compareTo(a));
      
    int streak = 1;
    DateTime current = sorted.first;
    
    // Check if the streak is broken (last completed is older than yesterday)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(current.year, current.month, current.day);
    if (today.difference(lastDate).inDays > 1) return 0;

    for (int i = 1; i < sorted.length; i++) {
      final prev = DateTime(sorted[i].year, sorted[i].month, sorted[i].day);
      final diff = current.difference(prev).inDays;
      if (diff == 1) {
        streak++;
        current = prev;
      } else if (diff == 0) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }
}
