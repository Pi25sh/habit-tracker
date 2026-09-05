import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/providers/journal_provider.dart';
import '../../application/providers/background_provider.dart';
import '../../data/models/journal_entry.dart';
import '../../presentation/widgets/filter_chip.dart';
import '../../presentation/widgets/journal_card.dart';
import '../widgets/add_bg_dialog.dart';
import 'journal_editor_screen.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final List<String> _categories = ['All', 'Thoughts', 'Gratitude', 'Affirmation'];
  String _selected = 'All';

  List<JournalEntry> _filter(List<JournalEntry> entries) {
    List<JournalEntry> result = entries;
    if (_selected != 'All') {
      result = result.where((e) => e.categoryId == _selected).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = ref.watch(journalProvider);
    final bgUrl = ref.watch(backgroundProvider);
    final entries = _filter(allEntries);

    return Scaffold(
      backgroundColor: bgUrl.isNotEmpty ? Colors.transparent : const Color(0xFFFDFCFB), // Very clean off-white
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'My Journal',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E2420),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => showAddBgDialog(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E2420).withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image_outlined, size: 20, color: Color(0xFF1E2420)),
                          const SizedBox(width: 6),
                          Text(
                            'Add BG',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: const Color(0xFF1E2420),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                children: _categories.map((c) {
                  return AppFilterChip(
                    label: c,
                    selected: _selected == c,
                    onTap: () => setState(() => _selected = c),
                  );
                }).toList(),
              ),
            ),

            // Journal List
            Expanded(
              child: entries.isEmpty
                  ? _EmptyJournal(
                      onCompose: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JournalEditorScreen()),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      itemCount: entries.length,
                      itemBuilder: (context, index) =>
                          JournalCard(entry: entries[index], hasBg: bgUrl.isNotEmpty),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 8),
        child: FloatingActionButton(
          heroTag: 'journalFab',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JournalEditorScreen()),
            );
          },
          backgroundColor: const Color(0xFFFFB74D), // Golden yellow
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.black87, size: 36),
        ),
      ),
    );
  }
}

class _EmptyJournal extends StatelessWidget {
  final VoidCallback onCompose;

  const _EmptyJournal({required this.onCompose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_outlined, size: 44, color: Color(0xFFB08968)),
            const SizedBox(height: 12),
            Text(
              'No journal entries yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E2420),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Capture a thought, a moment, or a small win.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF7A7A7A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onCompose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Write first entry'),
            ),
          ],
        ),
      ),
    );
  }
}
