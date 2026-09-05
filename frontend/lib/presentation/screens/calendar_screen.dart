import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../application/providers/background_provider.dart';
import '../../application/providers/calendar_provider.dart';
import '../../data/models/calendar_models.dart';
import '../widgets/add_bg_dialog.dart';
import 'create_calendar_event_screen.dart';

/// Real Calendar tab: a current-month grid fed by [calendarProvider].
///
/// Previously this screen rendered a hardcoded May 2026 mock. It now reads the
/// offline-first calendar store (events, special days, reminders) and renders
/// the actual current month, with prev/next/Today navigation and a per-day
/// event panel. The FAB opens the functional event form.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _visibleMonth; // first day of the shown month
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _moveMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _visibleMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  String _timeLabel(TimeOfDay? t) {
    if (t == null) return 'All day';
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  void _openAddEvent() {
    CreateCalendarEventScreen.showAsModal(context, initialDate: _selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final bgUrl = ref.watch(backgroundProvider);
    final calendar = ref.watch(calendarProvider);
    final hasBg = bgUrl.isNotEmpty;

    final firstDay = _visibleMonth;
    final gridStart = firstDay.subtract(Duration(days: firstDay.weekday % 7));
    final days = List<DateTime>.generate(
      42,
      (i) => DateTime(gridStart.year, gridStart.month, gridStart.day + i),
    );

    final dayEvents = calendar.events
        .where((e) => _isSameDay(e.date, _selectedDate))
        .toList()
      ..sort((a, b) => (a.startTime?.hour ?? 0).compareTo(b.startTime?.hour ?? 0));
    final daySpecial =
        calendar.specialDays.where((d) => _isSameDay(d.date, _selectedDate)).toList();

    return Scaffold(
      backgroundColor: hasBg ? Colors.transparent : const Color(0xFFFDFCFB),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 8),
        child: FloatingActionButton(
          heroTag: 'calendarFab',
          onPressed: _openAddEvent,
          backgroundColor: const Color(0xFF2C4A3B),
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(hasBg),
            _buildMonthNavigator(),
            _buildWeekdayHeader(),
            Container(
              decoration: BoxDecoration(
                color: hasBg ? Colors.white.withValues(alpha: 0.6) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var row = 0; row < 6; row++)
                    Row(
                      children: [
                        for (var col = 0; col < 7; col++)
                          _buildDayCell(days[row * 7 + col], calendar.events, calendar.specialDays, hasBg),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                children: [
                  _buildDaySummary(daySpecial, dayEvents),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool hasBg) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Calendar',
                        style: GoogleFonts.kalam(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2C4A3B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.energy_savings_leaf_outlined,
                        color: Color(0xFF2C4A3B), size: 24),
                  ],
                ),
                Text(
                  'Plan your days. Make them meaningful.',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: const Color(0xFF7A7A7A),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => showAddBgDialog(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hasBg ? Colors.white.withValues(alpha: 0.6) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEFEFEF)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_outlined, size: 18, color: Color(0xFF2C4A3B)),
                  const SizedBox(width: 6),
                  Text(
                    'Add BG',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: const Color(0xFF2C4A3B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator() {
    final monthLabel = DateFormat('MMMM yyyy').format(_visibleMonth);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _moveMonth(-1),
            icon: const Icon(Icons.chevron_left, color: Color(0xFF2C4A3B)),
          ),
          Expanded(
            child: Text(
              monthLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2C4A3B),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _moveMonth(1),
            icon: const Icon(Icons.chevron_right, color: Color(0xFF2C4A3B)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _goToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEFEFEF)),
              ),
              child: Text(
                'Today',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: const Color(0xFF2C4A3B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: i == 0 || i == 6 ? const Color(0xFFC0392B) : const Color(0xFF1E2420),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day,
    List<CalendarEvent> events,
    List<SpecialDay> specials,
    bool hasBg,
  ) {
    final inMonth = day.month == _visibleMonth.month;
    final isToday = _isSameDay(day, DateTime.now());
    final isSelected = _isSameDay(day, _selectedDate);

    final dayEvents = events.where((e) => _isSameDay(e.date, day)).toList();
    final daySpecial = specials.where((s) => _isSameDay(s.date, day)).toList();
    final dots = <Color>[
      if (daySpecial.isNotEmpty) const Color(0xFFD81B60),
      for (final e in dayEvents.take(2)) Color(e.color ?? 0xFF5A7851),
    ].toList();

    Color numberColor = inMonth ? const Color(0xFF1E2420) : const Color(0xFFBDBDBD);
    if (isSelected) numberColor = Colors.white;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _selectedDate = DateTime(day.year, day.month, day.day);
          if (!inMonth) _visibleMonth = DateTime(day.year, day.month);
        }),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF2C4A3B) : Colors.transparent,
                  border: isToday && !isSelected
                      ? Border.all(color: const Color(0xFF2C4A3B), width: 1.5)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                    color: numberColor,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final c in dots.take(3))
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
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

  Widget _buildDaySummary(
    List<SpecialDay> specials,
    List<CalendarEvent> events,
  ) {
    final dateLabel = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2C4A3B),
          ),
        ),
        const SizedBox(height: 4),
        if (specials.isEmpty && events.isEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFEFEF)),
            ),
            child: Column(
              children: [
                const Icon(Icons.event_busy, color: Color(0xFF9E9E9E), size: 32),
                const SizedBox(height: 8),
                Text(
                  'Nothing planned on this day',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7A7A7A),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _openAddEvent,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2C4A3B),
                    side: const BorderSide(color: Color(0xFF2C4A3B)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Add Event'),
                ),
              ],
            ),
          ),
        ] else ...[
          for (final s in specials)
            _specialDayTile(s),
          for (final e in events)
            _eventTile(e),
        ],
      ],
    );
  }

  Widget _specialDayTile(SpecialDay day) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFADBE0)),
      ),
      child: Row(
        children: [
          Text(day.emoji ?? '🎉', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              day.title,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E2420),
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(calendarProvider.notifier).deleteSpecialDay(day.id),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF9E9E9E)),
            tooltip: 'Delete special day',
          ),
        ],
      ),
    );
  }

  Widget _eventTile(CalendarEvent event) {
    final accent = Color(event.color ?? 0xFF5A7851);
    final time =
        '${_timeLabel(event.startTime)}${event.endTime != null ? ' – ${_timeLabel(event.endTime)}' : ''}';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 36, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2420),
                  ),
                ),
                if (event.location != null || event.startTime != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (event.startTime != null) time,
                      if (event.location != null) event.location!,
                    ].join(' • '),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: const Color(0xFF7A7A7A),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.read(calendarProvider.notifier).deleteEvent(event.id),
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9E9E9E)),
            tooltip: 'Delete event',
          ),
        ],
      ),
    );
  }
}