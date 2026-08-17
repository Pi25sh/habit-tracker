import 'package:flutter/material.dart';

/// A row of small ○ circles showing habit progress.
///
/// Completed circles are filled sage green, incomplete ones are a
/// cream / beige outline — like dots on a paper tracker.
class ProgressDots extends StatelessWidget {
  final int completed;
  final int total;
  final double dotSize;
  final double spacing;
  final String? label;

  const ProgressDots({
    super.key,
    required this.completed,
    required this.total,
    this.dotSize = 18,
    this.spacing = 6,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = total <= 0 ? 1 : total;

    final dots = Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(count, (i) {
        final isDone = i < completed;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? scheme.primary : Colors.transparent,
            border: Border.all(
              color: isDone ? scheme.primary : Theme.of(context).dividerColor,
              width: 1.5,
            ),
          ),
          child: isDone
              ? Icon(Icons.check, size: dotSize * 0.6, color: scheme.onPrimary)
              : null,
        );
      }),
    );

    if (label == null) return dots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: TextStyle(
            fontSize: 11,
            color: scheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        dots,
      ],
    );
  }
}
