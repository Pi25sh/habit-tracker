import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/providers/background_provider.dart';
import '../../application/providers/bucket_list_provider.dart';
import '../widgets/add_bg_dialog.dart';

// Temporary local state model until state management provider is fully wired
class BucketItem {
  final String id;
  final String title;
  final bool isCompleted;

  BucketItem({required this.id, required this.title, this.isCompleted = false});
}

class ThoughtsScreen extends ConsumerStatefulWidget {
  const ThoughtsScreen({super.key});

  @override
  ConsumerState<ThoughtsScreen> createState() => _ThoughtsScreenState();
}

class _ThoughtsScreenState extends ConsumerState<ThoughtsScreen> {

  void _addItem(String title) {
    if (title.trim().isEmpty) return;
    ref.read(bucketListProvider.notifier).addItem(title);
  }

  void _toggleItem(String id) {
    ref.read(bucketListProvider.notifier).toggleItem(id);
  }

  void _showAddItemDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add to Bucket List', style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'What is your dream?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B92CB)),
            onPressed: () {
              _addItem(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgUrl = ref.watch(backgroundProvider);
    final items = ref.watch(bucketListProvider);

    return Scaffold(
      backgroundColor: bgUrl.isNotEmpty ? Colors.transparent : const Color(0xFFFDFCFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Bucket List',
                        style: GoogleFonts.kalam(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B92CB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_border, color: Color(0xFF6B92CB), size: 28),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => showAddBgDialog(context, ref),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: bgUrl.isNotEmpty ? dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: bgUrl.isNotEmpty ? Colors.white.withValues(alpha: 0.5) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: bgUrl.isNotEmpty ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFEFEFEF)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.image_outlined, size: 18, color: Color(0xFF6B92CB)),
                              const SizedBox(width: 6),
                              Text(
                                'Add BG',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: const Color(0xFF6B92CB),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: bgUrl.isNotEmpty ? dart_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: bgUrl.isNotEmpty 
                                ? (item.isCompleted ? const Color(0xFF6B92CB).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.6))
                                : (item.isCompleted ? const Color(0xFFEBF1F6) : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: bgUrl.isNotEmpty ? Colors.white.withValues(alpha: 0.4) : const Color(0xFFEFEFEF),
                            ),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _toggleItem(item.id),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: item.isCompleted ? const Color(0xFF6B92CB) : Colors.transparent,
                                    border: Border.all(
                                      color: const Color(0xFF6B92CB),
                                      width: 2,
                                    ),
                                  ),
                                  child: item.isCompleted
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    color: const Color(0xFF1E2420),
                                    fontWeight: FontWeight.w600,
                                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                    decorationColor: const Color(0xFF1E2420).withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              Icon(Icons.more_horiz, color: const Color(0xFF1E2420).withValues(alpha: 0.5)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        backgroundColor: const Color(0xFF6B92CB),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Dream', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }
}
