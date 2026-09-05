import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/providers/habit_provider.dart';

class CalendarAnalyticsScreen extends ConsumerStatefulWidget {
  const CalendarAnalyticsScreen({super.key});

  @override
  ConsumerState<CalendarAnalyticsScreen> createState() => _CalendarAnalyticsScreenState();
}

class _CalendarAnalyticsScreenState extends ConsumerState<CalendarAnalyticsScreen> {
  final List<String> _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  
  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitProvider);
    
    // Calculate calendar grid
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOffset = _currentMonth.weekday - 1; // 0 for Monday, 6 for Sunday
    final totalCells = ((daysInMonth + firstDayOffset) / 7).ceil() * 7;
    
    // Analytics calculations for current month
    int totalHabitsCompleted = 0;
    int perfectDays = 0;
    int bestStreak = 0; // we can use the max longestStreak from habits, or calculate monthly
    int totalPossibleHabits = habits.length * daysInMonth;
    
    // Calculate completions per day
    Map<int, int> completionsPerDay = {};
    for (int day = 1; day <= daysInMonth; day++) {
      int count = 0;
      for (var habit in habits) {
        if (habit.completedDates.any((d) => d.year == _currentMonth.year && d.month == _currentMonth.month && d.day == day)) {
          count++;
          totalHabitsCompleted++;
        }
      }
      completionsPerDay[day] = count;
      if (habits.isNotEmpty && count == habits.length) {
        perfectDays++;
      }
    }
    
    for (var habit in habits) {
      if (habit.longestStreak > bestStreak) {
        bestStreak = habit.longestStreak;
      }
    }
    
    final completionRate = totalPossibleHabits > 0 ? (totalHabitsCompleted / totalPossibleHabits * 100).toInt() : 0;
    final maxDailyCompletions = habits.isNotEmpty ? habits.length : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: const Text('Calendar Analytics', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MMMM yyyy').format(_currentMonth), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left, color: Colors.black54), onPressed: _prevMonth),
                    IconButton(icon: const Icon(Icons.chevron_right, color: Colors.black54), onPressed: _nextMonth),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Custom Calendar Grid
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  // Weekdays
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _weekdays.map((w) => Text(w, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Calendar Days Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: totalCells,
                    itemBuilder: (context, index) {
                      final day = index - firstDayOffset + 1; 
                      final isCurrentMonth = day > 0 && day <= daysInMonth;
                      if (!isCurrentMonth) {
                        return const SizedBox();
                      }
                      
                      final completedCount = completionsPerDay[day] ?? 0;
                      final activityLevel = habits.isNotEmpty ? completedCount / maxDailyCompletions : 0.0;
                      final hasPerfectDay = habits.isNotEmpty && completedCount == maxDailyCompletions;
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: hasPerfectDay 
                              ? Colors.amber 
                              : const Color(0xFF673AB7).withValues(alpha: activityLevel > 0 ? (0.2 + activityLevel * 0.8) : 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              color: activityLevel > 0.5 || hasPerfectDay ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Month Highlights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 16),
            
            Row(
              children: [
                _buildHighlightCard('Perfect Days', '$perfectDays', Icons.star, Colors.amber),
                const SizedBox(width: 16),
                _buildHighlightCard('Total Habits', '$totalHabitsCompleted', Icons.check_circle, Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildHighlightCard('Best Streak', '$bestStreak Days', Icons.local_fire_department, Colors.orange),
                const SizedBox(width: 16),
                _buildHighlightCard('Completion', '$completionRate%', Icons.pie_chart, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
