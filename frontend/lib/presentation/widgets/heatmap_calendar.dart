import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HeatmapCalendar extends StatelessWidget {
  final List<DateTime> completedDates;
  final DateTime startDate;
  final DateTime endDate;
  final Color baseColor;

  const HeatmapCalendar({
    super.key,
    required this.completedDates,
    required this.startDate,
    required this.endDate,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    // Generate all dates between start and end
    final int totalDays = endDate.difference(startDate).inDays + 1;
    final List<DateTime> days = List.generate(
      totalDays,
      (index) => startDate.add(Duration(days: index)),
    );

    // Group by weeks for the grid
    final List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = List.filled(7, null);

    for (var day in days) {
      final int weekdayIndex = day.weekday % 7; // Sunday=0, Monday=1, etc. (Adjust based on preference)
      
      if (weekdayIndex == 0 && currentWeek.any((d) => d != null)) {
        weeks.add(currentWeek);
        currentWeek = List.filled(7, null);
      }
      currentWeek[weekdayIndex] = day;
    }
    if (currentWeek.any((d) => d != null)) {
      weeks.add(currentWeek);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: weeks.map((week) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: week.map((day) {
              if (day == null) {
                return const SizedBox(width: 14, height: 14);
              }
              final bool isCompleted = completedDates.any(
                (d) => d.year == day.year && d.month == day.month && d.day == day.day,
              );
              
              // Optionally change intensity based on multiple completions (if applicable)
              final color = isCompleted ? baseColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05);

              return Tooltip(
                message: DateFormat('MMM d, yyyy').format(day),
                child: Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
