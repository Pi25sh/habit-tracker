import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/providers/habit_provider.dart';
import '../widgets/glassmorphism_container.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitProvider);
    
    // Create a mock timeline of events based on completed dates
    final List<Map<String, dynamic>> timelineEvents = [];
    
    for (var habit in habits) {
      for (var date in habit.completedDates) {
        timelineEvents.add({
          'date': date,
          'habitName': habit.name,
          'color': Color(habit.color),
          'icon': habit.icon ?? '✨',
          'type': 'completion',
        });
      }
    }
    
    // Sort events by date descending
    timelineEvents.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Your Journey', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: timelineEvents.isEmpty
          ? const Center(child: Text('Your journey begins here. Complete a habit to see it on the timeline!'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: timelineEvents.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final event = timelineEvents[index];
                final date = event['date'] as DateTime;
                final color = event['color'] as Color;
                
                // Show date header if it's the first item or a new day
                bool showHeader = false;
                if (index == 0) {
                  showHeader = true;
                } else {
                  final prevDate = timelineEvents[index - 1]['date'] as DateTime;
                  if (date.year != prevDate.year || date.month != prevDate.month || date.day != prevDate.day) {
                    showHeader = true;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader) ...[
                      const SizedBox(height: 10),
                      Text(
                        DateFormat('MMMM d, yyyy').format(date),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 15),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline Line & Dot
                        Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(event['icon'], style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                            if (index != timelineEvents.length - 1)
                              Container(
                                width: 2,
                                height: 60, // approximate height of card
                                color: color.withValues(alpha: 0.3),
                              ),
                          ],
                        ),
                        const SizedBox(width: 15),
                        
                        // Event Card
                        Expanded(
                          child: GlassmorphismContainer(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 20),
                            color: color.withValues(alpha: 0.1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      event['habitName'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: color.withBlue(100).withRed(100),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('h:mm a').format(date),
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text('Completed successfully! ✨'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }
}
