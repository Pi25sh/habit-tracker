import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The personal profile block: avatar + "Shivani" + tagline, used on the
/// Settings page and Profile screen.
class ProfileCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback? onTap;
  final String? avatarEmoji;
  final bool hasBg;

  const ProfileCard({
    super.key,
    this.name = 'Shivani',
    required this.subtitle,
    this.onTap,
    this.avatarEmoji,
    this.hasBg = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final content = Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFAFC8B3).withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            avatarEmoji ?? '👩🏻',
            style: const TextStyle(fontSize: 26),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(Icons.chevron_right, color: Colors.white70),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: hasBg ? dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: hasBg ? const Color(0xFF65508A).withValues(alpha: 0.75) : const Color(0xFF65508A),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: hasBg ? Colors.white.withValues(alpha: 0.2) : Colors.transparent),
          ),
          child: onTap == null
              ? content
              : InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: onTap,
                  child: content,
                ),
        ),
      ),
    );
  }
}
