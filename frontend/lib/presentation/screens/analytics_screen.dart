import 'package:flutter/material.dart';
import '../../data/models/habit.dart';

class AnalyticsScreen extends StatelessWidget {
  final Habit habit;

  const AnalyticsScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBEB),
      appBar: AppBar(
        title: Text('${habit.name} Analytics', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.bar_chart, size: 64, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Total Completions: ${habit.completedDates.length}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Best Streak: ${habit.longestStreak} days',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Past 7 Days Rhythm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final today = DateTime.now();
                        final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - index));
                        final isCompleted = habit.completedDates.any((d) => d.year == day.year && d.month == day.month && d.day == day.day);
                        
                        return Column(
                          children: [
                            Text(
                              ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1],
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 30,
                              height: 100,
                              alignment: Alignment.bottomCenter,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                height: isCompleted ? 100 : 0,
                                decoration: BoxDecoration(
                                  color: Color(habit.color),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
