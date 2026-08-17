import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class EveningReflectionScreen extends ConsumerStatefulWidget {
  const EveningReflectionScreen({super.key});

  @override
  ConsumerState<EveningReflectionScreen> createState() => _EveningReflectionScreenState();
}

class _EveningReflectionScreenState extends ConsumerState<EveningReflectionScreen> {
  final _wentWellController = TextEditingController();
  final _didntGoWellController = TextEditingController();
  final _achievementController = TextEditingController();
  final _lessonController = TextEditingController();
  final _improveController = TextEditingController();
  final _tomorrowController = TextEditingController();
  
  double _energyLevel = 5;
  double _stressLevel = 5;
  String _selectedMood = '😌';
  bool _finishedGoals = false;

  @override
  void dispose() {
    _wentWellController.dispose();
    _didntGoWellController.dispose();
    _achievementController.dispose();
    _lessonController.dispose();
    _improveController.dispose();
    _tomorrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Soft twilight blue/gray
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Evening Reflection',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  child: const Text('🌙', style: TextStyle(fontSize: 24)),
                )
              ],
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Evening Check-in'),
            const SizedBox(height: 16),
            _buildMoodSelector(),
            const SizedBox(height: 24),
            _buildSliders(),
            const SizedBox(height: 32),

            _buildSectionTitle('What went well today?'),
            const SizedBox(height: 16),
            _buildInputField(_wentWellController, 'List your wins...', minLines: 3),
            const SizedBox(height: 32),

            _buildSectionTitle('What didn\'t go as planned?'),
            const SizedBox(height: 16),
            _buildInputField(_didntGoWellController, 'Areas of friction...', minLines: 3),
            const SizedBox(height: 32),

            _buildSectionTitle('Biggest Achievement'),
            const SizedBox(height: 16),
            _buildInputField(_achievementController, 'The highlight of my day was...', minLines: 2),
            const SizedBox(height: 32),

            _buildSectionTitle('Lesson Learned'),
            const SizedBox(height: 16),
            _buildInputField(_lessonController, 'Today I learned...', minLines: 2),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Did I finish today\'s goals?', style: TextStyle(fontWeight: FontWeight.bold)),
                activeThumbColor: Colors.black,
                value: _finishedGoals,
                onChanged: (val) => setState(() => _finishedGoals = val),
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Tomorrow\'s Priorities'),
            const SizedBox(height: 16),
            _buildInputField(_tomorrowController, '1.\n2.\n3.', minLines: 4),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evening Reflection saved! 🌙')));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Save Reflection', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildSliders() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Energy Level', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${_energyLevel.toInt()}/10', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          Slider(
            value: _energyLevel,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: Colors.blue,
            inactiveColor: Colors.blue.withValues(alpha: 0.1),
            onChanged: (val) => setState(() => _energyLevel = val),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Stress Level', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${_stressLevel.toInt()}/10', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            ],
          ),
          Slider(
            value: _stressLevel,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: Colors.redAccent,
            inactiveColor: Colors.redAccent.withValues(alpha: 0.1),
            onChanged: (val) => setState(() => _stressLevel = val),
          ),
        ],
      ),
    );
  }
}
