import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/providers/habit_provider.dart';
import '../../data/models/habit.dart';
import '../widgets/add_bg_dialog.dart';

class CreateHabitScreen extends ConsumerStatefulWidget {
  final Habit? editHabit;

  const CreateHabitScreen({super.key, this.editHabit});

  @override
  ConsumerState<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends ConsumerState<CreateHabitScreen> {
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();

  String _emoji = '🧘';
  TimeOfDay? _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _reminderEnabled = true;

  bool get _isEdit => widget.editHabit != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final h = widget.editHabit!;
      _nameController.text = h.name;
      _emoji = h.icon ?? '🧘';
      if (h.reminderTime != null) {
        _reminderTime = h.reminderTime;
        _reminderEnabled = true;
      } else {
        _reminderEnabled = false;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;

    final now = DateTime.now();
    final habit = Habit(
      id: widget.editHabit?.id ?? now.millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: widget.editHabit?.description,
      icon: _emoji,
      color: 0xFF65508A, // Default color
      routine: widget.editHabit?.routine ?? 'Anytime',
      completedDates: widget.editHabit?.completedDates,
      currentStreak: widget.editHabit?.currentStreak ?? 0,
      longestStreak: widget.editHabit?.longestStreak ?? 0,
      createdAt: widget.editHabit?.createdAt ?? now,
      isPaused: widget.editHabit?.isPaused ?? false,
      reminderTime: _reminderEnabled ? _reminderTime : null,
      linkedHabitId: widget.editHabit?.linkedHabitId,
      note: widget.editHabit?.note,
      repeatDays: [1, 2, 3, 4, 5, 6, 7],
    );

    if (_isEdit) {
      ref.read(habitProvider.notifier).updateHabit(habit);
    } else {
      ref.read(habitProvider.notifier).addHabit(habit);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDFCFB), // Very clean off-white
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1C3A5A).withValues(alpha: 0.15), width: 1.5),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C3A5A), size: 20),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Add Habit',
                          style: GoogleFonts.kalam(fontSize: 38, color: const Color(0xFF284F8F), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showAddBgDialog(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE182), // Exact yellow
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image_outlined, size: 20, color: Color(0xFF1C3A5A)),
                            const SizedBox(width: 6),
                            Text('Add BG', style: GoogleFonts.kalam(fontSize: 18, color: const Color(0xFF1C3A5A), fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Name Field
                _InputField(
                  bgColor: const Color(0xFFFCF4E0),
                  iconBgColor: const Color(0xFFFFB300),
                  icon: Icons.receipt_long_outlined,
                  title: 'Name',
                  hint: 'e.g., Morning Meditation',
                  controller: _nameController,
                ),
                const SizedBox(height: 16),
                
                // Emoji Field
                _InputField(
                  bgColor: const Color(0xFFEBF1F6),
                  iconBgColor: const Color(0xFF6B92CB),
                  icon: Icons.phone_iphone_rounded,
                  title: 'iPhone emojis',
                  hint: 'e.g., 🧘🏼',
                ),
                const SizedBox(height: 16),
                
                // Duration Field
                _InputField(
                  bgColor: const Color(0xFFF3F4E6),
                  iconBgColor: const Color(0xFF81B053),
                  icon: Icons.calendar_today_rounded,
                  title: 'for how many day',
                  hint: 'e.g., 30',
                  controller: _durationController,
                ),
                const SizedBox(height: 16),
                
                // Frequency Field
                _DropdownField(
                  bgColor: const Color(0xFFF8EFFF),
                  iconBgColor: const Color(0xFFAFA0C9), // Muted purple
                  icon: Icons.access_time_rounded,
                  value: 'everyday',
                  arrowColor: const Color(0xFFAFA0C9),
                ),
                const SizedBox(height: 16),
                
                // Reminder Field
                _DropdownField(
                  bgColor: const Color(0xFFF4F6EC),
                  iconBgColor: const Color(0xFF8C9B71), // Muted olive
                  icon: Icons.notifications_none_rounded,
                  title: 'Reminder',
                  hint: 'e.g., 08:00 AM',
                  arrowColor: const Color(0xFF8C9B71),
                ),
                
                const SizedBox(height: 40),
                
                // Add Habit Button
                Center(
                  child: GestureDetector(
                    onTap: _save,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD3E0EA), // Exact pale blue from screenshot
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Add Habit', style: GoogleFonts.kalam(fontSize: 26, color: const Color(0xFF1C3A5A), fontWeight: FontWeight.w500)),
                          const SizedBox(width: 12),
                          const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF1C3A5A), size: 28),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final Color bgColor;
  final Color iconBgColor;
  final IconData icon;
  final String title;
  final String hint;
  final TextEditingController? controller;

  const _InputField({
    required this.bgColor,
    required this.iconBgColor,
    required this.icon,
    required this.title,
    required this.hint,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.kalam(fontSize: 20, color: const Color(0xFF1C3A5A), fontWeight: FontWeight.w600),
                ),
                controller != null 
                ? SizedBox(
                    height: 24,
                    child: TextField(
                      controller: controller,
                      style: GoogleFonts.kalam(fontSize: 16, color: const Color(0xFF7A7A7A)),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: GoogleFonts.kalam(fontSize: 16, color: const Color(0xFF9E9E9E)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  )
                : Text(
                    hint,
                    style: GoogleFonts.kalam(fontSize: 16, color: const Color(0xFF9E9E9E)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final Color bgColor;
  final Color iconBgColor;
  final IconData icon;
  final String? title;
  final String? value;
  final String? hint;
  final Color arrowColor;

  const _DropdownField({
    required this.bgColor,
    required this.iconBgColor,
    required this.icon,
    this.title,
    this.value,
    this.hint,
    required this.arrowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: GoogleFonts.kalam(fontSize: 20, color: const Color(0xFF1C3A5A), fontWeight: FontWeight.w600),
                  ),
                if (value != null)
                  Text(
                    value!,
                    style: GoogleFonts.kalam(fontSize: 20, color: const Color(0xFF1C3A5A), fontWeight: FontWeight.w500),
                  ),
                if (hint != null)
                  Text(
                    hint!,
                    style: GoogleFonts.kalam(fontSize: 16, color: const Color(0xFF9E9E9E)),
                  ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: arrowColor, size: 28),
        ],
      ),
    );
  }
}
