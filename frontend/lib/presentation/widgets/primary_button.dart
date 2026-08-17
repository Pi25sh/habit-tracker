import 'package:flutter/material.dart';

/// The app's primary action button — generous padding, rounded corners
/// and the sage accent. Used for "Save Todo", "Add Todo" and friends.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool outline;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: expanded ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );

    final style = ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
      backgroundColor: WidgetStatePropertyAll(outline ? Colors.transparent : scheme.primary),
      foregroundColor: WidgetStatePropertyAll(outline ? scheme.primary : scheme.onPrimary),
      side: outline ? WidgetStatePropertyAll(BorderSide(color: scheme.primary)) : null,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );

    return expanded ? SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onPressed, style: style, child: content)) : ElevatedButton(onPressed: onPressed, style: style, child: content);
  }
}
