import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/habit_provider.dart';
import '../../data/models/habit.dart';

class CreateHabitScreen extends ConsumerStatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  ConsumerState<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends ConsumerState<CreateHabitScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedIcon = '💧';
  int? _selectedColor;
  String _selectedRoutine = 'morning';
  TimeOfDay? _reminderTime;
  String? _linkedHabitId;

  final List<String> _icons = ['💧', '📖', '🏃‍♀️', '🧘‍♀️', '🍎', '💤', '💻', '🎨', '🧹', '🌿'];
  late List<int> _colors;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scheme = Theme.of(context).colorScheme;
    _colors = [
      scheme.primary.value,
      scheme.secondary.value,
      Colors.orangeAccent.value,
      Colors.pinkAccent.value,
      Colors.purpleAccent.value,
    ];
    _selectedColor ??= scheme.primary.value;
  }

  void _saveHabit() {
    if (_nameController.text.isEmpty) return;

    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor ?? _colors.first,
      routine: _selectedRoutine,
      reminderTime: _reminderTime,
      linkedHabitId: _linkedHabitId,
    );

    ref.read(habitProvider.notifier).addHabit(habit);
    Navigator.of(context).pop();
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final existingHabits = ref.watch(habitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Habit'),
        actions: [
          TextButton(
            onPressed: _saveHabit,
            child: Text(
              'Save',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(_selectedColor ?? _colors.first).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(_selectedIcon, style: const TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSectionTitle('Name & Description', colors),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Drink Water',
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Stay hydrated (optional)',
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Choose Icon', colors),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _icons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primary.withOpacity(0.2) : colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? colors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Choose Color', colors),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              children: _colors.map((colorValue) {
                final isSelected = _selectedColor == colorValue;
                final color = Color(colorValue);
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorValue),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colors.onSurface : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Routine', colors),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Morning', 'Afternoon', 'Evening', 'Night', 
                'Study', 'Gym', 'Travel', 'Weekend', 'Anytime'
              ].map((routine) {
                final routineKey = routine.toLowerCase();
                final isSelected = _selectedRoutine == routineKey;
                return ChoiceChip(
                  label: Text(routine),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRoutine = routineKey);
                  },
                  selectedColor: colors.primary,
                  backgroundColor: colors.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? colors.onPrimary : colors.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? colors.primary : colors.onSurface.withOpacity(0.1),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle('Reminders & Stacking', colors),
            const SizedBox(height: 16),
            
            // Reminder Time Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.alarm, color: colors.primary),
              title: Text(_reminderTime == null ? 'Set Daily Reminder' : 'Reminder: ${_reminderTime!.format(context)}'),
              trailing: _reminderTime != null 
                  ? IconButton(
                      icon: const Icon(Icons.clear), 
                      onPressed: () => setState(() => _reminderTime = null)
                    ) 
                  : const Icon(Icons.chevron_right),
              onTap: () => _pickReminderTime(context),
            ),
            
            // Habit Stacking
            if (existingHabits.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _linkedHabitId,
                decoration: InputDecoration(
                  labelText: 'Habit Stacking (After I finish...)',
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.link, color: colors.primary),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None (Standalone Habit)')),
                  ...existingHabits.map((h) => DropdownMenuItem(
                    value: h.id,
                    child: Text('${h.icon ?? ''} ${h.name}'),
                  )),
                ],
                onChanged: (val) {
                  setState(() {
                    _linkedHabitId = val;
                  });
                },
              ),
            ],

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colors.onSurface,
      ),
    );
  }
}
