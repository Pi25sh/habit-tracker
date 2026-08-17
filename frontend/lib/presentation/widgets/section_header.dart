import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A small serif section header with a tiny botanical underline,
/// used for "TODAY", "UPCOMING", "PROGRESS" etc.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '🌿',
              style: TextStyle(fontSize: 14, color: scheme.primary),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        ?trailing,
      ],
    );
  }
}
