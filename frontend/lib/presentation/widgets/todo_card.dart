import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/habit_provider.dart';
import '../../data/models/habit.dart';
import '../../presentation/screens/habit_details_screen.dart';

class TodoCard extends ConsumerWidget {
  final Habit habit;
  final DateTime? date;
  final bool showProgress; // True on Home Dashboard, False on Todo list
  final String? subtitleOverride;

  const TodoCard({
    super.key,
    required this.habit,
    this.date,
    this.showProgress = false,
    this.subtitleOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveDate = date ?? DateTime.now();
    final isDone = _isCompleted(habit, effectiveDate);

    if (showProgress) {
      // HOME DASHBOARD LAYOUT
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: showProgress ? Colors.white : (isDone ? const Color(0xFFDDE8D9) : Colors.transparent),
          borderRadius: BorderRadius.circular(16),
          border: showProgress ? null : Border.all(color: showProgress ? Colors.transparent : (isDone ? Colors.transparent : Theme.of(context).dividerColor)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Checkbox
            GestureDetector(
              onTap: () => ref
                  .read(habitProvider.notifier)
                  .toggleHabitCompletion(habit, effectiveDate),
              child: Container(
                width: 24,
                height: 24,
                margin: EdgeInsets.only(top: showProgress ? 2 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isDone ? const Color(0xFF8DA989) : Colors.transparent,
                  border: Border.all(
                    color: const Color(0xFF8DA989), // Sage green border
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            // Middle: Title and Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E2420),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressElements(habit),
                ],
              ),
            ),
            // Right: Options
            const Icon(Icons.more_horiz, color: Color(0xFF6B8E6B)),
          ],
        ),
      );
    } else {
      // TODO SCREEN LAYOUT (from previous requirement)
      final subtitle = subtitleOverride ??
          (habit.reminderTime?.format(context));

      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HabitDetailsScreen(habit: habit)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFFDDE8D9) : scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDone ? Colors.transparent : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            children: [
              Text(habit.icon ?? '🌱', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        decorationColor: scheme.onSurface.withValues(alpha: 0.4),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => ref
                    .read(habitProvider.notifier)
                    .toggleHabitCompletion(habit, effectiveDate),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: isDone ? const Color(0xFF8DA989) : Colors.transparent,
                    border: Border.all(
                      color: isDone ? const Color(0xFF8DA989) : scheme.onSurface.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: isDone
                      ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
                      : null,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildProgressElements(Habit habit) {
    // If the habit is Drink Water or something similar, render the drops, else render SMTWTFS dots.
    if (habit.name.toLowerCase().contains('water') || habit.icon == '💧' || habit.icon == '🚰') {
      // 14 drop icons (representing last 14 days)
      final today = DateTime.now();
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(14, (i) {
          final dayToCheck = today.subtract(Duration(days: 13 - i));
          final isFilled = habit.completedDates.any((d) => d.year == dayToCheck.year && d.month == dayToCheck.month && d.day == dayToCheck.day);
          return Icon(
            Icons.water_drop,
            size: 22,
            color: isFilled ? const Color(0xFF8DA989) : const Color(0xFFE4EBDC),
            shadows: isFilled
                ? [
                    Shadow(
                      color: const Color(0xFF8DA989).withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          );
        }),
      );
    } else {
      // Render S M T W T F S dots for the current week
      final labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
      final today = DateTime.now();
      // Find the most recent Sunday (0 to 6 days ago)
      final sunday = today.subtract(Duration(days: today.weekday == 7 ? 0 : today.weekday));

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final dayToCheck = sunday.add(Duration(days: i));
          final isFilled = habit.completedDates.any((d) => d.year == dayToCheck.year && d.month == dayToCheck.month && d.day == dayToCheck.day);
          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? const Color(0xFF8DA989) : const Color(0xFFF9F7F2),
            ),
            alignment: Alignment.center,
            child: Text(
              labels[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isFilled ? Colors.white : const Color(0xFF1E2420),
              ),
            ),
          );
        }),
      );
    }
  }

  static bool _isCompleted(Habit habit, DateTime day) =>
      habit.completedDates.any((d) =>
          d.year == day.year && d.month == day.month && d.day == day.day);
}
