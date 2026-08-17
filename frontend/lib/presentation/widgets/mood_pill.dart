import 'package:flutter/material.dart';

/// Maps a stored mood emoji to the label shown on journal cards.
const Map<String, String> kMoodLabels = {
  '😊': 'JOYFUL',
  '😀': 'HAPPY',
  '🙂': 'CONTENT',
  '😌': 'PEACEFUL',
  '😐': 'NEUTRAL',
  '😢': 'SAD',
  '😔': 'LOW',
  '😤': 'FRUSTRATED',
  '😴': 'TIRED',
  '🤩': 'EXCITED',
  '🥰': 'GRATEFUL',
  '🙏': 'GRATEFUL',
  '🌿': 'CALM',
  '✨': 'INSPIRED',
};

/// A tiny uppercase pill showing the entry's mood label (or emoji).
class MoodPill extends StatelessWidget {
  final String mood;

  const MoodPill({super.key, required this.mood});

  @override
  Widget build(BuildContext context) {
    final label = kMoodLabels[mood] ?? mood.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4C85D).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Color(0xFFC8951A),
        ),
      ),
    );
  }
}
