import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../application/providers/calendar_provider.dart';
import '../../data/models/calendar_models.dart';
import '../../presentation/widgets/primary_button.dart';

class CreateSpecialDayScreen extends ConsumerStatefulWidget {
  const CreateSpecialDayScreen({super.key});

  @override
  ConsumerState<CreateSpecialDayScreen> createState() => _CreateSpecialDayScreenState();
}

class _CreateSpecialDayScreenState extends ConsumerState<CreateSpecialDayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  DateTime _date = DateTime.now();
  String _emoji = '🎉';
  final List<String> _emojis = ['🎉', '🎂', '💑', '✈️', '🎓', '🏥', '🏠', '✨'];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final specialDay = SpecialDay(
      id: now.millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      date: _date,
      emoji: _emoji,
      createdAt: now,
    );
    ref.read(calendarProvider.notifier).addSpecialDay(specialDay);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Add Special Day',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter event title' : null,
                decoration: InputDecoration(
                  hintText: 'Title (e.g. Birthday, Anniversary)',
                  filled: true,
                  fillColor: scheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today, color: scheme.primary),
                title: Text(DateFormat('MMM d, yyyy').format(_date)),
                onTap: _pickDate,
              ),
              const SizedBox(height: 20),
              Text(
                'Emoji',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _emojis.map((e) {
                  final isSelected = _emoji == e;
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? scheme.primary.withValues(alpha: 0.2) : scheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? scheme.primary : Colors.transparent,
                        ),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: 'Save Special Day',
                icon: Icons.check,
                expanded: true,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
