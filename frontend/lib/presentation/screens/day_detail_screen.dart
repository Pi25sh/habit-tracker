import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../application/providers/habit_provider.dart';
import '../../application/providers/task_provider.dart';
import '../../application/providers/calendar_provider.dart';
import '../../data/models/habit.dart';
import '../../data/models/task.dart';
import '../../data/models/calendar_models.dart';
import '../../presentation/widgets/app_card.dart';
import 'habit_details_screen.dart';
import 'task_details_screen.dart';
import 'calendar_event_detail_screen.dart';

/// Day Detail — a single calendar day showing all scheduled items.
class DayDetailScreen extends ConsumerWidget {
  final DateTime date;

  const DayDetailScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    final allHabits = ref.watch(habitProvider).where((h) => !h.isPaused).toList();
    final allTasks = ref.watch(taskProvider);
    final calState = ref.watch(calendarProvider);

    final dayHabits = allHabits.where((h) => h.repeatDays.contains(date.weekday)).toList();
    final dayTasks = allTasks.where((t) => t.dueDate != null && isSameDay(t.dueDate!, date)).toList();
    final dayEvents = calState.events.where((e) => isSameDay(e.date, date)).toList();
    final dayReminders = calState.reminders.where((r) => isSameDay(r.date, date)).toList();
    final daySpecial = calState.specialDays.where((s) => s.date.month == date.month && s.date.day == date.day).toList();

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: scheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              DateFormat('d MMMM yyyy').format(date),
              style: GoogleFonts.playfairDisplay(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            Text(
              DateFormat('EEEE').format(date),
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          if (daySpecial.isNotEmpty) ...[
            _SectionHeader('Special Days', '🎉'),
            ...daySpecial.map((s) => _SpecialDayTile(specialDay: s)),
            const SizedBox(height: 28),
          ],

          if (dayEvents.isNotEmpty) ...[
            _SectionHeader('Events', '📅'),
            ...dayEvents.map((e) => _EventTile(event: e)),
            const SizedBox(height: 28),
          ],

          if (dayHabits.isNotEmpty) ...[
            _SectionHeader('Habits & Routines', '🌿'),
            ...dayHabits.map((h) => _HabitTile(habit: h, date: date)),
            const SizedBox(height: 28),
          ],

          if (dayTasks.isNotEmpty) ...[
            _SectionHeader('Tasks', '📋'),
            ...dayTasks.map((t) => _TaskTile(task: t)),
            const SizedBox(height: 28),
          ],

          if (dayReminders.isNotEmpty) ...[
            _SectionHeader('Reminders', '🔔'),
            ...dayReminders.map((r) => _ReminderTile(reminder: r)),
            const SizedBox(height: 28),
          ],

          if (daySpecial.isEmpty && dayEvents.isEmpty && dayHabits.isEmpty && dayTasks.isEmpty && dayReminders.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Text('🌿', style: TextStyle(fontSize: 44, color: scheme.primary)),
                  const SizedBox(height: 16),
                  Text(
                    'A quiet day.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nothing scheduled — enjoy the pause.',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String emoji;

  const _SectionHeader(this.title, this.emoji);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  final Habit habit;
  final DateTime date;

  const _HabitTile({required this.habit, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDone = habit.completedDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HabitDetailsScreen(habit: habit)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () =>
                  ref.read(habitProvider.notifier).toggleHabitCompletion(habit, date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isDone ? scheme.primary : Theme.of(context).dividerColor,
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Text(habit.icon ?? '🌱', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                habit.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: scheme.onSurface.withValues(alpha: 0.4),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (habit.reminderTime != null)
              Text(
                habit.reminderTime!.format(context),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final Task task;

  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDone = task.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () =>
                  ref.read(taskProvider.notifier).toggleTaskCompletion(task),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isDone ? scheme.primary : Theme.of(context).dividerColor,
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Text(task.icon ?? '📋', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: scheme.onSurface.withValues(alpha: 0.4),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (task.dueTime != null)
              Text(
                task.dueTime!.format(context),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final CalendarEvent event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CalendarEventDetailScreen(event: event),
            ),
          );
        },
        child: Row(
          children: [
            const Text('📅', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              event.startTime?.format(context) ?? 'All Day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final CalendarReminder reminder;

  const _ReminderTile({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CalendarEventDetailScreen(event: reminder),
            ),
          );
        },
        child: Row(
          children: [
            const Text('🔔', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reminder.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              reminder.time?.format(context) ?? 'No time',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialDayTile extends StatelessWidget {
  final SpecialDay specialDay;

  const _SpecialDayTile({required this.specialDay});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CalendarEventDetailScreen(event: specialDay),
            ),
          );
        },
        child: Row(
          children: [
            Text(specialDay.emoji ?? '🎉', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                specialDay.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
