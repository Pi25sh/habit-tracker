import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/providers/habit_provider.dart';
import '../../data/models/habit.dart';

class HabitDetailsScreen extends ConsumerWidget {
  final Habit habit;

  const HabitDetailsScreen({super.key, required this.habit});

  void _deleteHabit(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: Text('Are you sure you want to delete ${habit.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () {
              ref.read(habitProvider.notifier).deleteHabit(habit.id);
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close details screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color habitColor = Color(habit.color);
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _deleteHabit(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: habitColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: habitColor.withOpacity(0.3), width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    habit.icon ?? '✨',
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  if (habit.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      habit.description!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: habitColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          habit.routine,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: habit.isPaused ? Colors.orange.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: habit.isPaused ? Colors.orange : colors.onSurface.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Paused',
                              style: TextStyle(
                                color: habit.isPaused ? Colors.orange : colors.onSurface.withOpacity(0.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: habit.isPaused,
                              activeColor: Colors.orange,
                              onChanged: (val) {
                                habit.isPaused = val;
                                ref.read(habitProvider.notifier).updateHabit(habit);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Current Streak',
                    '${habit.currentStreak} 🔥',
                    colors.primary,
                    colors,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Longest Streak',
                    '${habit.longestStreak} 👑',
                    colors.secondary,
                    colors,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            _buildStatCard(
              'Total Completions',
              '${habit.completedDates.length} Days',
              colors.onSurface,
              colors,
              fullWidth: true,
            ),
            
            const SizedBox(height: 32),
            Text(
              'Activity Heatmap (Last 30 Days)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildHeatmap(habit.completedDates, habitColor, colors),
            
            const SizedBox(height: 32),
            Text(
              'Recent History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            ...habit.completedDates.reversed.take(5).map((date) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: habitColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: habitColor),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(date),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, ColorScheme colors, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(List<DateTime> completedDates, Color habitColor, ColorScheme colors) {
    final today = DateTime.now();
    final List<Widget> columns = [];
    
    // Generate 30 days of data
    final List<DateTime> last30Days = List.generate(30, (index) {
      return today.subtract(Duration(days: 29 - index));
    });

    final completedSet = completedDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: last30Days.map((date) {
          final isCompleted = completedSet.contains(DateTime(date.year, date.month, date.day));
          return Tooltip(
            message: DateFormat('MMM d, yyyy').format(date),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? habitColor : colors.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCompleted ? habitColor.withOpacity(0.5) : Colors.transparent,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
