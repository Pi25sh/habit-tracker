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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Journal',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2420),
                    ),
                  ),
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
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                itemCount: entries.isEmpty ? 3 : entries.length,
                itemBuilder: (context, index) {
                  if (entries.isEmpty) {
                    // Placeholder data for matching screenshot
                    final entry = JournalEntry(
                      id: index.toString(),
                      title: index == 0 ? 'A grateful heart' : index == 1 ? 'Morning thoughts' : 'Small wins',
                      body: index == 0 
                        ? 'Today I felt truly grateful for the little things...' 
                        : index == 1 
                          ? 'Started the day with meditation and a cup...'
                          : 'Completed my workout and stayed focused...',
                      date: DateTime.now().subtract(Duration(days: index)),
                      categoryId: 'All',
                      mood: '',
                      createdAt: DateTime.now().subtract(Duration(days: index)),
                      updatedAt: DateTime.now().subtract(Duration(days: index)),
                    );
                    return JournalCard(entry: entry, hasBg: bgUrl.isNotEmpty);
                  }
                  return JournalCard(entry: entries[index], hasBg: bgUrl.isNotEmpty);
                },
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
