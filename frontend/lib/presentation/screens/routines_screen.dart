import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/habit_provider.dart';
import '../../data/models/habit.dart';
import 'habit_details_screen.dart';
import 'settings_screen.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitProvider);
    final colors = Theme.of(context).colorScheme;

    // Define the full suite of routines from the mega-prompt
    final Map<String, String> routineSections = {
      'morning': 'Morning Routine 🌅',
      'afternoon': 'Afternoon Routine ☀️',
      'evening': 'Evening Routine 🌙',
      'night': 'Night Routine 😴',
      'study': 'Study Routine 📚',
      'gym': 'Gym Routine 💪',
      'travel': 'Travel Routine ✈️',
      'weekend': 'Weekend Routine 🎉',
      'anytime': 'Anytime Habits ✨',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          ...routineSections.entries.map((entry) {
            final routineHabits = habits.where((h) => h.routine == entry.key).toList();
            if (routineHabits.isEmpty) return const SizedBox.shrink();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoutineSection(entry.value, routineHabits, colors, context, ref),
                const SizedBox(height: 32),
              ],
            );
          }),
          
          if (habits.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.list_alt, size: 64, color: colors.secondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No routines set up yet!\nCreate a habit to start building your routines.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.5),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildRoutineSection(String title, List<Habit> habits, ColorScheme colors, BuildContext context, WidgetRef ref) {
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...habits.map((habit) {
          final isCompleted = habit.completedDates.any((d) => 
            d.year == today.year && d.month == today.month && d.day == today.day
          );
          final cardColor = Color(habit.color);

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => HabitDetailsScreen(habit: habit)),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(habit.icon ?? '✨', style: const TextStyle(fontSize: 24)),
                ),
                title: Text(
                  habit.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: colors.onSurface,
                  ),
                ),
                trailing: GestureDetector(
                  onTap: () {
                    ref.read(habitProvider.notifier).toggleHabitCompletion(habit, today);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCompleted ? colors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted ? colors.primary : colors.onSurface.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 20,
                      color: isCompleted ? colors.onPrimary : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
