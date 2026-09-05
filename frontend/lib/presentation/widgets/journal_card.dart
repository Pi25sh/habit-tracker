import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../application/providers/journal_provider.dart';
import '../../data/models/journal_entry.dart';
import '../../presentation/screens/journal_editor_screen.dart';

class JournalCard extends ConsumerWidget {
  final JournalEntry entry;
  final bool hasBg;

  const JournalCard({
    super.key,
    required this.entry,
    this.hasBg = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = DateFormat('d').format(entry.date);
    final month = DateFormat('MMM').format(entry.date);
    final year = DateFormat('yyyy').format(entry.date);
    
    // Determine time format as per screenshot
    final now = DateTime.now();
    final isYesterday = now.difference(entry.date).inDays == 1 && now.day != entry.date.day;
    final timeStr = isYesterday ? 'Yesterday' : DateFormat('h:mm a').format(entry.date);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JournalEditorScreen(entry: entry)),
        );
      },
      onLongPress: () => _confirmDelete(context, ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: hasBg ? dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasBg ? Colors.white.withValues(alpha: 0.75) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: hasBg ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFEFEFEF), width: 1.5),
            ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Text Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title.isNotEmpty ? entry.title : 'Untitled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E2420),
                            ),
                          ),
                          if (entry.body.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              entry.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                color: const Color(0xFF1E2420),
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        timeStr,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: const Color(0xFF1E2420),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Date Chip
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: hasBg ? const Color(0xFFFBFBFB).withValues(alpha: 0.5) : const Color(0xFFFBFBFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: hasBg ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFEAEAEA)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        day,
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF67793D),
                        ),
                      ),
                      Text(
                        month,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF67793D),
                        ),
                      ),
                      Text(
                        year,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF67793D).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    ),
  );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete entry?'),
        content: Text('Remove "${entry.title.isEmpty ? 'Untitled' : entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(journalProvider.notifier).deleteEntry(entry.id);
    }
  }
}
