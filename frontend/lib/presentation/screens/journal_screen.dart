import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/providers/note_provider.dart';
import '../../data/models/note_record.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _journalController = TextEditingController();
  final _gratitudeController = TextEditingController();
  String? _selectedMood;
  DateTime _selectedDate = DateTime.now();
  
  final List<Map<String, String>> _moods = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😌', 'label': 'Calm'},
    {'emoji': '⚡', 'label': 'Energetic'},
    {'emoji': '😔', 'label': 'Sad'},
    {'emoji': '😫', 'label': 'Stressed'},
  ];

  @override
  void initState() {
    super.initState();
    _loadNoteForDate(_selectedDate);
  }

  void _loadNoteForDate(DateTime date) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final note = ref.read(noteProvider.notifier).getNoteForDate(date);
      setState(() {
        if (note != null) {
          _selectedMood = note.mood;
          _journalController.text = note.journalEntry ?? '';
          _gratitudeController.text = note.gratitude ?? '';
        } else {
          _selectedMood = null;
          _journalController.clear();
          _gratitudeController.clear();
        }
      });
    });
  }

  void _saveNote() {
    final note = NoteRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      mood: _selectedMood,
      journalEntry: _journalController.text.trim(),
      gratitude: _gratitudeController.text.trim(),
    );
    
    ref.read(noteProvider.notifier).addOrUpdateNote(note);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Journal saved! 🌸'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Journal & Mood')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Strip
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 14,
                itemBuilder: (context, index) {
                  final date = DateTime.now().subtract(Duration(days: 13 - index));
                  final isSelected = date.year == _selectedDate.year && 
                                     date.month == _selectedDate.month && 
                                     date.day == _selectedDate.day;
                  final note = ref.watch(noteProvider.notifier).getNoteForDate(date);
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = date);
                      _loadNoteForDate(date);
                    },
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary : colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? colors.primary : colors.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E').format(date),
                            style: TextStyle(
                              color: isSelected ? colors.onPrimary : colors.onSurface.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isSelected ? colors.onPrimary : colors.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(note?.mood != null ? '✨' : '', style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              DateFormat('EEEE, MMMM d').format(_selectedDate),
              style: TextStyle(
                fontSize: 18,
                color: colors.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              'How are you feeling?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood['label'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = mood['label']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary : colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (!isSelected)
                            BoxShadow(
                              color: colors.primary.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(mood['emoji']!, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            mood['label']!,
                            style: TextStyle(
                              color: isSelected ? colors.onPrimary : colors.onSurface.withOpacity(0.6),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 32),
            Text(
              'What are you grateful for?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _gratitudeController,
              hint: 'I am grateful for...',
              maxLines: 2,
              colors: colors,
            ),
            
            const SizedBox(height: 32),
            Text(
              'Journal Entry',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _journalController,
              hint: 'Write about your day...',
              maxLines: 6,
              colors: colors,
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveNote,
                child: const Text('Save Journal'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: TextStyle(color: colors.onSurface.withOpacity(0.4)),
        ),
        style: TextStyle(color: colors.onSurface),
      ),
    );
  }
}
