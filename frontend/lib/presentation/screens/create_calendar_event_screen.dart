import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../application/providers/calendar_provider.dart';
import '../../data/models/calendar_models.dart';

/// Functional "Add Event" form. Every field is wired to real state: the name,
/// location and notes are [TextEditingController]s; date and times come from
/// the platform pickers; "Add Event" persists a [CalendarEvent] through
/// [calendarProvider]. Previously all fields were static text and both buttons
/// just popped.
class CreateCalendarEventScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const CreateCalendarEventScreen({super.key, this.initialDate});

  static Future<void> showAsModal(BuildContext context, {DateTime? initialDate}) {
    return showDialog(
      context: context,
      builder: (context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Material(
            color: Colors.transparent,
            child: CreateCalendarEventScreen(initialDate: initialDate),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<CreateCalendarEventScreen> createState() => _CreateCalendarEventScreenState();
}

class _CreateCalendarEventScreenState extends ConsumerState<CreateCalendarEventScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  static const _colorChoices = <int>[
    0xFF5A7851, // Green
    0xFF4A90E2, // Blue
    0xFF9C27B0, // Purple
    0xFFFF9800, // Orange
    0xFFD81B60, // Pink
    0xFF2C4A3B, // Deep green
  ];

  late DateTime _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = false;
  int _color = _colorChoices.first;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime({required bool isEnd}) async {
    final initial = isEnd ? (_endTime ?? _startTime ?? const TimeOfDay(hour: 9, minute: 0))
                          : (_startTime ?? const TimeOfDay(hour: 9, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    setState(() {
      if (isEnd) {
        _endTime = picked;
      } else {
        _startTime = picked;
      }
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event name')),
      );
      return;
    }

    final event = CalendarEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      date: DateTime(_date.year, _date.month, _date.day),
      startTime: _isAllDay ? null : _startTime,
      endTime: _isAllDay ? null : _endTime,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      color: _color,
      createdAt: DateTime.now(),
    );

    await ref.read(calendarProvider.notifier).addEvent(event);
    if (mounted) Navigator.pop(context);
  }

  String _dateLabel() => DateFormat('d MMM yyyy (EEE)').format(DateTime(_date.year, _date.month, _date.day));

  String _timeLabel(TimeOfDay? t) {
    if (t == null) return '—';
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    return '$hour:${t.minute.toString().padLeft(2, '0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.event_available_outlined, color: Color(0xFF2C4A3B), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add Event',
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C4A3B),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Color(0xFF2C4A3B), size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Event Name
          _label('Event Name', isRequired: true),
          TextField(
            controller: _titleController,
            decoration: _decoration('e.g., Team Meeting', Icons.calendar_today_outlined),
          ),
          const SizedBox(height: 16),

          // All-day switch
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFF5A7851), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All-day Event',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2420),
                  ),
                ),
              ),
              Switch(
                value: _isAllDay,
                onChanged: (val) => setState(() => _isAllDay = val),
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF5A7851),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFD4D4D4),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date
          _label('Date', isRequired: true),
          _tappableField(
            icon: Icons.calendar_today_outlined,
            text: _dateLabel(),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),

          // Start / End time
          if (!_isAllDay) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Start Time', isRequired: true),
                      _tappableField(
                        icon: Icons.access_time,
                        text: _timeLabel(_startTime),
                        onTap: () => _pickTime(isEnd: false),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('-', style: TextStyle(fontSize: 20, color: Color(0xFF7A7A7A))),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('End Time', isRequired: true),
                      _tappableField(
                        icon: Icons.access_time,
                        text: _timeLabel(_endTime),
                        onTap: () => _pickTime(isEnd: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Location
          _label('Location'),
          TextField(
            controller: _locationController,
            decoration: _decoration('Add location (optional)', Icons.location_on_outlined),
          ),
          const SizedBox(height: 16),

          // Notes
          _label('Description'),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: _decoration('Add description (optional)', Icons.receipt_long_outlined),
          ),
          const SizedBox(height: 16),

          // Color
          _label('Color'),
          Row(
            children: [
              for (final c in _colorChoices) ...[
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: _color == c
                          ? Border.all(color: const Color(0xFF1E2420), width: 2.5)
                          : null,
                    ),
                    child: _color == c
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEFEFEF), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5A7851),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF385E3A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Add Event',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF2C4A3B)),
          children: [
            TextSpan(text: text),
            if (isRequired)
              const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFD32F2F))),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF9E9E9E)),
      prefixIcon: Icon(icon, color: const Color(0xFF5A7851), size: 20),
      filled: true,
      fillColor: const Color(0xFFF9FAF7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEFEFEF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5A7851), width: 1.5),
      ),
    );
  }

  Widget _tappableField({required IconData icon, required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAF7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5A7851), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: const Color(0xFF1E2420),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1E2420), size: 20),
          ],
        ),
      ),
    );
  }
}