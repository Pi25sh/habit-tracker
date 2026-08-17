import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/calendar_models.dart';
import '../../application/providers/calendar_provider.dart';

class CalendarEventDetailScreen extends ConsumerWidget {
  final dynamic event; // Can be CalendarEvent or SpecialDay

  const CalendarEventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String title = '';
    DateTime date = DateTime.now();
    String? notes;
    String categoryLabel = 'Event';
    Color categoryColor = const Color(0xFFF8E1E7); // Pinkish
    String timeStr = 'All Day';
    String repeatStr = 'Every Year'; // placeholder
    
    if (event is CalendarEvent) {
      final e = event as CalendarEvent;
      title = e.title;
      date = e.date;
      notes = e.notes;
      categoryLabel = 'Event';
      if (e.startTime != null) {
        timeStr = e.startTime!.format(context);
      }
    } else if (event is SpecialDay) {
      final s = event as SpecialDay;
      title = s.title;
      date = s.date;
      notes = s.notes;
      categoryLabel = 'Birthday';
    } else if (event is CalendarReminder) {
      final r = event as CalendarReminder;
      title = r.title;
      date = r.date;
      notes = r.notes;
      categoryLabel = 'Reminder';
      if (r.time != null) {
        timeStr = r.time!.format(context);
      }
      if (r.repeat != null) {
        repeatStr = r.repeat!;
      } else {
        repeatStr = 'None';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2), // Warm Off-White
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Event Detail',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center placeholder illustration
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '🎁', // Placeholder for gift box illustration
                    style: TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Category Pill
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  categoryLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Details List
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              text: DateFormat('d MMM yyyy').format(date),
            ),
            const SizedBox(height: 24),
            _DetailRow(
              icon: Icons.access_time,
              text: timeStr,
            ),
            const SizedBox(height: 24),
            _DetailRow(
              icon: Icons.repeat,
              text: repeatStr,
            ),
            
            const SizedBox(height: 40),
            
            // Notes
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notes?.isNotEmpty == true ? notes! : "No notes.",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 80), // spacer for bottom buttons
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                   final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete?'),
                      content: const Text('Are you sure you want to delete this event?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    if (event is CalendarEvent) {
                      ref.read(calendarProvider.notifier).deleteEvent(event.id);
                    } else if (event is SpecialDay) {
                      ref.read(calendarProvider.notifier).deleteSpecialDay(event.id);
                    } else if (event is CalendarReminder) {
                      ref.read(calendarProvider.notifier).deleteReminder(event.id);
                    }
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD32F2F), // Red
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.black87),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
