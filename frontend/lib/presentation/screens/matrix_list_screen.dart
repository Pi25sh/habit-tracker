import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/providers/habit_provider.dart';

class MatrixListScreen extends ConsumerWidget {
  const MatrixListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitProvider).where((h) => !h.isPaused).toList();
    final today = DateTime.now();
    
    // Last 14 days
    final dates = List.generate(14, (i) => today.subtract(Duration(days: 13 - i)));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Efficient List View'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: habits.isEmpty
            ? const Center(child: Text('No active habits.'))
            : Row(
                children: [
                  // Sticky Habits Column
                  Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          offset: const Offset(2, 0),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 60), // Header spacing
                        ...habits.map((habit) => Container(
                              height: 50,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Color(habit.color).withValues(alpha: 0.2),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                              ),
                              child: Text(
                                habit.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                    ),
                  ),
                  
                  // Scrollable Matrix Grid
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      reverse: true, // Show today on the right
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dates Header
                            Row(
                              children: dates.map((date) => Container(
                                width: 40,
                                height: 60,
                                margin: const EdgeInsets.only(right: 10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      DateFormat('E').format(date).substring(0, 3),
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: date.day == today.day
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.transparent,
                                      ),
                                      child: Text(
                                        '${date.day}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: date.day == today.day ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ),
                            
                            // Matrix Rows
                            ...habits.map((habit) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: dates.map((date) {
                                  final isCompleted = habit.completedDates.any(
                                    (d) => d.year == date.year && d.month == date.month && d.day == date.day,
                                  );
                                  return GestureDetector(
                                    onTap: () {
                                      ref.read(habitProvider.notifier).toggleHabitCompletion(habit, date);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 40,
                                      height: 50,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        color: isCompleted ? Color(habit.color) : Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
