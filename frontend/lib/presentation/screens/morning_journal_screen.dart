import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MorningJournalScreen extends ConsumerStatefulWidget {
  const MorningJournalScreen({super.key});

  @override
  ConsumerState<MorningJournalScreen> createState() => _MorningJournalScreenState();
}

class _MorningJournalScreenState extends ConsumerState<MorningJournalScreen> {
  final _affirmationController = TextEditingController();
  final _goalController = TextEditingController();
  final _intentionController = TextEditingController();
  final _gratitudeController = TextEditingController();
  final _focusController = TextEditingController();
  final _visualizationController = TextEditingController();
  
  String _selectedMood = '😊';
  double _sleepHours = 7.0;
  String _sleepQuality = 'Good';

  @override
  void dispose() {
    _affirmationController.dispose();
    _goalController.dispose();
    _intentionController.dispose();
    _gratitudeController.dispose();
    _focusController.dispose();
    _visualizationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2), // Light cream
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Morning Reflection',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(now).toUpperCase(),
                      style: const TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMMM d, yyyy').format(now),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ]),
                  child: const Text('☀️', style: TextStyle(fontSize: 24)),
                )
              ],
            ),
            const SizedBox(height: 32),
            
            // Morning Quote (AI Gen Mock)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFE4EE)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                children: [
                  Icon(Icons.format_quote_rounded, color: Colors.black26, size: 40),
                  Text(
                    '"The secret of your future is hidden in your daily routine."',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('How are you feeling?'),
            const SizedBox(height: 16),
            _buildMoodSelector(),
            const SizedBox(height: 32),

            _buildSectionTitle('Sleep Check-in'),
            const SizedBox(height: 16),
            _buildSleepTracker(),
            const SizedBox(height: 32),

            _buildSectionTitle('Today\'s Affirmation'),
            const SizedBox(height: 16),
            _buildInputField(_affirmationController, 'I am capable of...', minLines: 2),
            const SizedBox(height: 32),

            _buildSectionTitle('Top 3 Priorities'),
            const SizedBox(height: 16),
            _buildChecklistMock(),
            const SizedBox(height: 32),

            _buildSectionTitle('Daily Intention'),
            const SizedBox(height: 16),
            _buildInputField(_intentionController, 'How do I want to feel today?', minLines: 2),
            const SizedBox(height: 32),

            _buildSectionTitle('Gratitude'),
            const SizedBox(height: 16),
            _buildInputField(_gratitudeController, '1.\n2.\n3.', minLines: 4),
            const SizedBox(height: 32),

            _buildSectionTitle('Health Goals'),
            const SizedBox(height: 16),
            _buildHealthGoals(),
            const SizedBox(height: 32),
            
            _buildSectionTitle('Visualization'),
            const SizedBox(height: 16),
            _buildInputField(_visualizationController, 'What does success today look like?', minLines: 3),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Morning Journal saved! ☀️')));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Save Journal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, {int minLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        minLines: minLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    final moods = ['😫', '😔', '😐', '😌', '😊', '🤩'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: moods.map((mood) {
          final isSelected = _selectedMood == mood;
          return GestureDetector(
            onTap: () => setState(() => _selectedMood = mood),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Text(mood, style: const TextStyle(fontSize: 28)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSleepTracker() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hours Slept', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${_sleepHours.toStringAsFixed(1)} hrs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Slider(
            value: _sleepHours,
            min: 0,
            max: 12,
            divisions: 24,
            activeColor: Colors.black,
            inactiveColor: Colors.black12,
            onChanged: (val) => setState(() => _sleepHours = val),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quality', style: TextStyle(fontWeight: FontWeight.w600)),
              DropdownButton<String>(
                value: _sleepQuality,
                underline: const SizedBox(),
                items: ['Poor', 'Average', 'Good', 'Excellent'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _sleepQuality = val);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChecklistMock() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              const Icon(Icons.radio_button_unchecked, color: Colors.black26),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(border: InputBorder.none, hintText: 'Priority ${index + 1}', hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.3))),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHealthGoals() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFE1F5FE), borderRadius: BorderRadius.circular(20)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.water_drop, color: Colors.blue),
                SizedBox(height: 8),
                Text('Water Goal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                SizedBox(height: 4),
                Text('8 Glasses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.fitness_center, color: Colors.green),
                SizedBox(height: 8),
                Text('Exercise', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                SizedBox(height: 4),
                Text('30 Mins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
