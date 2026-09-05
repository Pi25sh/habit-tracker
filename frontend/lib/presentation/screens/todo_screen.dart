import 'dart:ui' as dart_ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/providers/task_provider.dart';
import '../../application/providers/background_provider.dart';
import '../widgets/add_bucket_list_modal.dart';
import '../widgets/add_bg_dialog.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Travel', 'Personal', 'Dreams'];

  @override
  Widget build(BuildContext context) {
    final allTasks = ref.watch(taskProvider);
    final bgUrl = ref.watch(backgroundProvider);
    final tasks = _selectedFilter == 'All' 
        ? allTasks 
        : allTasks.where((t) => t.category == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: bgUrl.isNotEmpty ? Colors.transparent : const Color(0xFFFDFCFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Bucket List',
                            style: GoogleFonts.kalam(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E2F23),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.energy_savings_leaf_outlined, color: Color(0xFF5A7851), size: 24),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => showAddBgDialog(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEFEFEF)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined, size: 18, color: Color(0xFF5A7851)),
                          const SizedBox(width: 6),
                          Text(
                            'Add BG',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: const Color(0xFF5A7851),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE8F1E4) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? const Color(0xFF1E2F23) : const Color(0xFF7A7A7A),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Bucket List Items
            Expanded(
              child: tasks.isEmpty
                  ? _EmptyBucketList(
                      onAdd: _openAddModal,
                      hasBg: bgUrl.isNotEmpty,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: tasks.map((task) {
                        return _BucketListItem(
                          title: task.name,
                          tag: task.category ?? 'Dreams',
                          tagColor: _getCatColor(task.category),
                          tagBg: _getCatBgColor(task.category),
                          icon: _getCatIcon(task.category),
                          isCompleted: task.isCompleted,
                          hasBg: bgUrl.isNotEmpty,
                          onToggle: () => ref.read(taskProvider.notifier).toggleTaskCompletion(task),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'todoFab',
        onPressed: _openAddModal,
        backgroundColor: const Color(0xFF5A7851),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  void _openAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BackdropFilter(
        filter: dart_ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: const AddBucketListModal(),
      ),
    );
  }

  Color _getCatColor(String? cat) {
    if (cat == 'Personal') return const Color(0xFF9C27B0);
    return const Color(0xFF4A90E2); // default
  }

  Color _getCatBgColor(String? cat) {
    if (cat == 'Personal') return const Color(0xFFF8EFFF);
    return const Color(0xFFF4F8FE); // default
  }

  IconData _getCatIcon(String? cat) {
    switch (cat) {
      case 'Travel':
        return Icons.flight_takeoff;
      case 'Personal':
        return Icons.favorite_border;
      default:
        return Icons.emoji_events_outlined;
    }
  }
}

class _EmptyBucketList extends StatelessWidget {
  final VoidCallback onAdd;
  final bool hasBg;

  const _EmptyBucketList({required this.onAdd, required this.hasBg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: hasBg ? Colors.white.withValues(alpha: 0.75) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 44, color: Color(0xFF5A7851)),
            const SizedBox(height: 12),
            Text(
              'No bucket list items yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E2F23),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add the things you dream of doing.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: const Color(0xFF7A7A7A),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A7851),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Add a dream'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BucketListItem extends StatelessWidget {
  final String title;
  final String tag;
  final Color tagColor;
  final Color tagBg;
  final IconData icon;
  final bool isCompleted;
  final bool hasBg;
  final VoidCallback? onToggle;

  const _BucketListItem({
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.tagBg,
    required this.icon,
    required this.isCompleted,
    required this.hasBg,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: hasBg ? dart_ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8) : dart_ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: hasBg ? Colors.white.withValues(alpha: 0.75) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: hasBg ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFEFEFEF), width: 1.5),
          ),
      child: Row(
        children: [
          // Leading category visual (local, no network)
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: tagColor, size: 34),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2F23),
                      height: 1.3,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: tagColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, left: 10, top: 10, bottom: 10),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF5A7851) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted ? const Color(0xFF5A7851) : const Color(0xFFC4C4C4),
                    width: 2,
                  ),
                ),
                child: isCompleted 
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}
