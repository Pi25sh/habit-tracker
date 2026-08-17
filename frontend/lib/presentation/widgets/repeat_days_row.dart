import 'package:flutter/material.dart';

/// A compact S M T W T F S row showing which days a todo repeats on.
///
/// Sunday-first to match the reference design.
class RepeatDaysRow extends StatelessWidget {
  final List<int> repeatDays; // 1=Mon … 7=Sun
  final double size;

  const RepeatDaysRow({super.key, required this.repeatDays, this.size = 26});

  static const List<String> _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (idx) {
        // Sunday-first: index 0 -> weekday 7
        final dayNumber = idx == 0 ? 7 : idx;
        final isSelected = repeatDays.contains(dayNumber);
        return Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(right: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? scheme.primary.withValues(alpha: 0.18) : Colors.transparent,
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            _labels[idx],
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              color: isSelected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        );
      }),
    );
  }
}
