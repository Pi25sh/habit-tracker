import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateCalendarEventScreen extends ConsumerStatefulWidget {
  const CreateCalendarEventScreen({super.key});

  static Future<void> showAsModal(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: Colors.transparent,
            child: CreateCalendarEventScreen(),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<CreateCalendarEventScreen> createState() => _CreateCalendarEventScreenState();
}

class _CreateCalendarEventScreenState extends ConsumerState<CreateCalendarEventScreen> {
  bool _isAllDay = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_available_outlined, color: Color(0xFF2C4A3B), size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Add Event',
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2C4A3B),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Color(0xFF2C4A3B), size: 24),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Event Name
            _buildLabel('Event Name', isRequired: true),
            _buildInputBox(icon: Icons.calendar_today_outlined, hint: 'e.g., Team Meeting'),
            const SizedBox(height: 16),

            // All-day Event
            Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF5A7851), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All-day Event',
                    style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E2420)),
                  ),
                ),
                Switch(
                  value: _isAllDay,
                  onChanged: (val) => setState(() => _isAllDay = val),
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF5A7851),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFD4D4D4),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date
            _buildLabel('Date', isRequired: true),
            _buildInputBox(icon: Icons.calendar_today_outlined, text: '20 May 2026 (Wednesday)', hasDropdown: true),
            const SizedBox(height: 16),

            // Start Time & End Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Start Time', isRequired: true),
                      _buildInputBox(icon: Icons.access_time, text: '10:00 AM', hasDropdown: true),
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
                      _buildLabel('End Time', isRequired: true),
                      _buildInputBox(icon: Icons.access_time, text: '11:00 AM', hasDropdown: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location
            _buildLabel('Location'),
            _buildInputBox(icon: Icons.location_on_outlined, hint: 'Add location (optional)'),
            const SizedBox(height: 16),

            // Description
            _buildLabel('Description'),
            _buildInputBox(icon: Icons.receipt_long_outlined, hint: 'Add description (optional)'),
            const SizedBox(height: 16),

            // Category & Color
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Category'),
                      _buildInputBox(icon: Icons.local_offer_outlined, text: 'Personal', hasDropdown: true),
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
                      _buildLabel('Color'),
                      _buildInputBox(dotColor: const Color(0xFF9C27B0), text: 'Purple', hasDropdown: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reminder
            _buildLabel('Reminder'),
            _buildInputBox(icon: Icons.notifications_none_outlined, text: '30 minutes before', hasDropdown: true),
            const SizedBox(height: 16),

            // Repeat
            _buildLabel('Repeat'),
            _buildInputBox(icon: Icons.repeat, text: 'Does not repeat', hasDropdown: true),
            const SizedBox(height: 32),

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
                        style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF5A7851)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF385E3A), // Darker green
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add Event',
                            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
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

  Widget _buildInputBox({IconData? icon, Color? dotColor, String? hint, String? text, bool hasDropdown = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF5A7851), size: 20),
            const SizedBox(width: 12),
          ],
          if (dotColor != null) ...[
            Container(width: 16, height: 16, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: text != null
                ? Text(text, style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF1E2420), fontWeight: FontWeight.w600))
                : Text(hint ?? '', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF9E9E9E))),
          ),
          if (hasDropdown)
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1E2420), size: 20),
        ],
      ),
    );
  }
}
