import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/providers/background_provider.dart';
import '../widgets/add_bg_dialog.dart';
import 'create_calendar_event_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  int _selectedDate = 20;

  @override
  Widget build(BuildContext context) {
    final bgUrl = ref.watch(backgroundProvider);

    return Scaffold(
      backgroundColor: bgUrl.isNotEmpty ? Colors.transparent : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Calendar',
                            style: GoogleFonts.kalam(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2C4A3B), // Dark green
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.energy_savings_leaf_outlined, color: const Color(0xFF2C4A3B), size: 28),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Plan your days. Make them meaningful.',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: const Color(0xFF7A7A7A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.favorite_border, color: Color(0xFF7A7A7A), size: 14),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => showAddBgDialog(context, ref),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: bgUrl.isNotEmpty ? dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: bgUrl.isNotEmpty ? Colors.white.withValues(alpha: 0.5) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: bgUrl.isNotEmpty ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFEFEFEF)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.image_outlined, size: 18, color: Color(0xFF2C4A3B)),
                              const SizedBox(width: 6),
                              Text('Add BG', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF2C4A3B), fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Top Cards (Birthdays, Anniversaries, Add)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _topCard(
                      'Birthdays',
                      Icons.cake_outlined,
                      const Color(0xFFFFF3F5),
                      const Color(0xFFD81B60),
                      '2 Upcoming',
                      ['15 May', 'Mom', '22 May', 'Aarav'],
                      bgUrl.isNotEmpty,
                    ),
                    const SizedBox(width: 12),
                    _topCard(
                      'Anniversaries',
                      Icons.favorite,
                      const Color(0xFFF8F4FF),
                      const Color(0xFF5E35B1),
                      '1 Upcoming',
                      ['20 May', 'Our Anniversary'],
                      bgUrl.isNotEmpty,
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => CreateCalendarEventScreen.showAsModal(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: bgUrl.isNotEmpty ? dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgUrl.isNotEmpty ? const Color(0xFFFDFCFB).withValues(alpha: 0.7) : const Color(0xFFFDFCFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: bgUrl.isNotEmpty ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFA5D6A7), width: 1.5, style: BorderStyle.solid), // Mocking dashed border with solid light green
                            ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF4CAF50)),
                              ),
                              child: const Icon(Icons.add, color: Color(0xFF4CAF50), size: 24),
                            ),
                            const SizedBox(height: 8),
                            Text('Add', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF2C4A3B), fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
                ),
              ),
              const SizedBox(height: 24),

              // Calendar Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chevron_left, color: Color(0xFF2C4A3B)),
                        const SizedBox(width: 24),
                        Text('May 2026', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF2C4A3B))),
                        const SizedBox(width: 24),
                        const Icon(Icons.chevron_right, color: Color(0xFF2C4A3B)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEFEFEF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF2C4A3B)),
                            const SizedBox(width: 6),
                            Text('Today', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF2C4A3B), fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEFEFEF)),
                        ),
                        child: const Icon(Icons.filter_alt_outlined, size: 18, color: Color(0xFF2C4A3B)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Calendar Grid Table
              _buildCalendarTable(bgUrl.isNotEmpty),
              const SizedBox(height: 24),

              // Selected Date Details
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C4A3B), // Dark green
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('20', style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Wednesday, 20 May 2026', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF2C4A3B))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.wb_sunny_outlined, color: Color(0xFFFBC02D), size: 18),
                            const SizedBox(width: 6),
                            Text('28°C • Sunny', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF7A7A7A))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: bgUrl.isNotEmpty ? dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: bgUrl.isNotEmpty ? Colors.white.withValues(alpha: 0.6) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: bgUrl.isNotEmpty ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFEFEFEF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2C4A3B)),
                            const SizedBox(width: 6),
                            Text('Add Remark', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF2C4A3B), fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Remarks / Notes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Remarks / Notes', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF2C4A3B))),
                  Row(
                    children: [
                      Text('Edit', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF2C4A3B), fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      const Icon(Icons.more_vert, color: Color(0xFF2C4A3B), size: 20),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: bgUrl.isNotEmpty ? dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgUrl.isNotEmpty ? const Color(0xFFFBF9F6).withValues(alpha: 0.7) : const Color(0xFFFBF9F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: bgUrl.isNotEmpty ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFEFEFEF)),
                    ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEBF6EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.energy_savings_leaf_outlined, color: Color(0xFF4CAF50), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF5A5A5A), height: 1.5),
                          children: const [
                            TextSpan(text: 'Had a '),
                            TextSpan(text: 'productive', style: TextStyle(color: Color(0xFFD67B3B), fontWeight: FontWeight.bold)),
                            TextSpan(text: ' day. Completed the design work.\nGrateful for the little things.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
              const SizedBox(height: 24),

              // Events on this day
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Events on this day', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF2C4A3B))),
                  GestureDetector(
                    onTap: () => CreateCalendarEventScreen.showAsModal(context),
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: Color(0xFF2C4A3B), size: 16),
                        const SizedBox(width: 4),
                        Text('Add Event', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF2C4A3B), fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _eventItem('Morning Meditation', '6:30 AM - 7:00 AM', const Color(0xFFF3E8FB), const Color(0xFF4CAF50), icon: Icons.check_circle_outline, iconColor: const Color(0xFF4CAF50), hasBg: bgUrl.isNotEmpty),
              _eventItem('Project Work', '10:00 AM - 1:00 PM', const Color(0xFFF4F8FE), const Color(0xFF4A90E2), icon: Icons.circle_outlined, iconColor: const Color(0xFF4A90E2), hasBg: bgUrl.isNotEmpty),
              _eventItem('Team Meeting', '3:00 PM - 4:00 PM', const Color(0xFFFAF5FA), const Color(0xFF9C27B0), icon: Icons.circle_outlined, iconColor: const Color(0xFF9C27B0), hasBg: bgUrl.isNotEmpty),
              _eventItem('Gym', '6:00 PM - 7:00 PM', const Color(0xFFFFF9F2), const Color(0xFFFF9800), icon: Icons.circle_outlined, iconColor: const Color(0xFFFF9800), hasBg: bgUrl.isNotEmpty),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topCard(String title, IconData icon, Color bgColor, Color themeColor, String badgeText, List<String> items, bool hasBg) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: hasBg ? dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasBg ? bgColor.withValues(alpha: 0.7) : bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: hasBg ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFEFEFEF)),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(icon, color: themeColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: themeColor)),
                ],
              ),
              const Icon(Icons.more_vert, color: Color(0xFF7A7A7A), size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(badgeText, style: GoogleFonts.nunito(fontSize: 12, color: themeColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          // Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(items[0], style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF1E2420))),
              Text(items[1], style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF1E2420))),
              Icon(icon, color: themeColor, size: 14),
            ],
          ),
          const SizedBox(height: 6),
          if (items.length > 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(items[2], style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF1E2420))),
                Text(items[3], style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF1E2420))),
                Icon(icon, color: themeColor, size: 14),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('View All', style: GoogleFonts.nunito(fontSize: 12, color: themeColor, fontWeight: FontWeight.w700)),
              Icon(Icons.chevron_right, color: themeColor, size: 16),
            ],
          ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildCalendarTable(bool hasBg) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: hasBg ? dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          decoration: BoxDecoration(
            color: hasBg ? Colors.white.withValues(alpha: 0.6) : Colors.transparent,
            border: Border.all(color: hasBg ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFEFEFEF)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
          // Header Row
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEFEFEF))),
            ),
            child: Row(
              children: [
                _calHeaderCell('Sun', const Color(0xFFD32F2F)),
                _calHeaderCell('Mon', const Color(0xFF1E2420)),
                _calHeaderCell('Tue', const Color(0xFF1E2420)),
                _calHeaderCell('Wed', const Color(0xFF1E2420)),
                _calHeaderCell('Thu', const Color(0xFF1E2420)),
                _calHeaderCell('Fri', const Color(0xFF1E2420)),
                _calHeaderCell('Sat', const Color(0xFF1976D2)),
              ],
            ),
          ),
          // Week 1
          Row(
            children: [
              _calDateCell('26', isMuted: true, dots: [const Color(0xFF7E57C2)]),
              _calDateCell('27', isMuted: true),
              _calDateCell('28', isMuted: true, pillLabel: 'Meditation', pillColor: const Color(0xFFE8F5E9), pillTextColor: const Color(0xFF2E7D32)),
              _calDateCell('29', isMuted: true, pillLabel: 'Project Work', pillColor: const Color(0xFFE3F2FD), pillTextColor: const Color(0xFF1565C0)),
              _calDateCell('30', isMuted: true),
              _calDateCell('1', pillLabel: 'Meeting', pillColor: const Color(0xFFF3E5F5), pillTextColor: const Color(0xFF7B1FA2)),
              _calDateCell('2', isBlue: true, pillLabel: 'Gym', pillColor: const Color(0xFFFFF3E0), pillTextColor: const Color(0xFFE65100)),
            ],
          ),
          _calDivider(),
          // Week 2
          Row(
            children: [
              _calDateCell('3', isRed: true, dots: [const Color(0xFF7E57C2)]),
              _calDateCell('4', dots: [const Color(0xFF4CAF50)]),
              _calDateCell('5', dots: [const Color(0xFF4CAF50), const Color(0xFF7E57C2)]),
              _calDateCell('6', dots: [const Color(0xFF7E57C2)]),
              _calDateCell('7', dots: [const Color(0xFF4CAF50), const Color(0xFF1976D2)]),
              _calDateCell('8', dots: [const Color(0xFF4CAF50)]),
              _calDateCell('9', isBlue: true, dots: [const Color(0xFFFF9800)]),
            ],
          ),
          _calDivider(),
          // Week 3
          Row(
            children: [
              _calDateCell('10', isRed: true, pillLabel: "Mother's Day", pillColor: const Color(0xFFFFEBEE), pillTextColor: const Color(0xFFC62828), dots: [const Color(0xFF4CAF50)]),
              _calDateCell('11'),
              _calDateCell('12', dots: [const Color(0xFFFF9800)]),
              _calDateCell('13', dots: [const Color(0xFF4CAF50)]),
              _calDateCell('14', pillLabel: 'Doctor Appt', pillColor: const Color(0xFFF3E5F5), pillTextColor: const Color(0xFF7B1FA2), dots: [const Color(0xFF4CAF50)]),
              _calDateCell('15'),
              _calDateCell('16', isBlue: true),
            ],
          ),
          _calDivider(),
          // Week 4
          Row(
            children: [
              _calDateCell('17', isRed: true),
              _calDateCell('18', pillLabel: 'Report Submit', pillColor: const Color(0xFFE8F5E9), pillTextColor: const Color(0xFF2E7D32), dots: [const Color(0xFF1976D2)]),
              _calDateCell('19'),
              _calDateCell('20', isSelected: true, pillLabel: 'Important  ⭐', pillColor: const Color(0xFFFFF8E1), pillTextColor: const Color(0xFF424242), dots: [const Color(0xFF4CAF50), const Color(0xFFFF9800)]),
              _calDateCell('21', dots: [const Color(0xFF4CAF50)]),
              _calDateCell('22', dots: [const Color(0xFF7E57C2)]),
              _calDateCell('23', isBlue: true),
            ],
          ),
          _calDivider(),
          // Week 5
          Row(
            children: [
              _calDateCell('24', isRed: true),
              _calDateCell('25', pillLabel: 'Shopping', pillColor: const Color(0xFFFFF3E0), pillTextColor: const Color(0xFFE65100)),
              _calDateCell('26', dots: [const Color(0xFF4CAF50)]),
              _calDateCell('27', dots: [const Color(0xFF1976D2), const Color(0xFF7E57C2)]),
              _calDateCell('28', pillLabel: 'Travel Plan', pillColor: const Color(0xFFE8F5E9), pillTextColor: const Color(0xFF2E7D32)),
              _calDateCell('29', dots: [const Color(0xFF4CAF50)]),
              _calDateCell('30', isBlue: true),
            ],
          ),
          _calDivider(),
          // Week 6
          Row(
            children: [
              _calDateCell('31', isRed: true),
              _calDateCell('1', isMuted: true),
              _calDateCell('2', isMuted: true),
              _calDateCell('3', isMuted: true),
              _calDateCell('4', isMuted: true),
              _calDateCell('5', isMuted: true),
              _calDateCell('6', isMuted: true),
            ],
          ),
        ],
      ),
      ),
    ),
  );
}

  Widget _calDivider() => Container(height: 1, color: const Color(0xFFEFEFEF));

  Widget _calHeaderCell(String text, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Color(0xFFEFEFEF))),
        ),
        alignment: Alignment.center,
        child: Text(text, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ),
    );
  }

  Widget _calDateCell(String day, {
    bool isMuted = false, 
    bool isRed = false, 
    bool isBlue = false, 
    bool isSelected = false,
    String? pillLabel,
    Color? pillColor,
    Color? pillTextColor,
    List<Color>? dots,
  }) {
    Color textColor = const Color(0xFF1E2420);
    if (isMuted) textColor = const Color(0xFFBDBDBD);
    if (isRed && !isMuted) textColor = const Color(0xFFD32F2F);
    if (isBlue && !isMuted) textColor = const Color(0xFF1976D2);
    if (isSelected) textColor = Colors.white;

    return Expanded(
      child: Container(
        height: 80,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Color(0xFFEFEFEF))),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2C4A3B) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(day, style: GoogleFonts.nunito(fontSize: 14, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: textColor)),
            ),
            const SizedBox(height: 4),
            if (pillLabel != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pillLabel,
                  style: GoogleFonts.nunito(fontSize: 8, fontWeight: FontWeight.w700, color: pillTextColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (pillLabel == null) const SizedBox(height: 14), // Spacer to align dots
            const Spacer(),
            if (dots != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: dots.map((c) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _eventItem(String title, String time, Color bgColor, Color accentColor, {required IconData icon, required Color iconColor, bool hasBg = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: hasBg ? dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: hasBg ? bgColor.withValues(alpha: 0.7) : bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E2420))),
                  const SizedBox(height: 4),
                  Text(time, style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF7A7A7A))),
                ],
              ),
            ],
          ),
        ],
      ),
      ),
    ),
  );
}
}
