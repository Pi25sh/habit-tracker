import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../application/providers/task_provider.dart';
import '../../application/services/media_service.dart';
import '../../data/models/task.dart';
import 'create_task_screen.dart';

/// Task Detail — the scrapbook / doodle screen for a single task.
///
/// Includes date & chips, chat memories, doodles, scrapbook images,
/// a paper note, and a Toolbar.
class TaskDetailsScreen extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  late final TextEditingController _noteController;
  final GlobalKey _notesKey = GlobalKey();
  bool _editingNote = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.task.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Task get _current {
    return ref.watch(taskProvider).firstWhere(
          (t) => t.id == widget.task.id,
          orElse: () => widget.task,
        );
  }

  void _save(Task t) => ref.read(taskProvider.notifier).updateTask(t);

  // ---- Note ----

  void _saveNote() {
    final t = _current;
    t.note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    _save(t);
    setState(() => _editingNote = false);
  }

  // ---- Images ----

  Future<void> _addImage(ImageSource source) async {
    final dest = await MediaService.pickImageToDocuments(
      prefix: widget.task.id,
      source: source,
    );
    if (dest == null || !mounted) return;
    final t = _current;
    t.imagePaths = List.of(t.imagePaths)..add(dest);
    _save(t);
  }

  void _deleteImage(int index) {
    final t = _current;
    final path = t.imagePaths[index];
    t.imagePaths = List.of(t.imagePaths)..removeAt(index);
    _save(t);
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  void _imageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Image',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_camera_outlined,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _addImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _addImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = _current;
    final dueDate = t.dueDate ?? DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2), // Warm Off-White/Cream
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E2420), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF1E2420), size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateTaskScreen(editTask: t)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                // Title
                Center(
                  child: Text(
                    t.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E2420),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Date
                Center(
                  child: Text(
                    '${DateFormat('d MMMM yyyy').format(dueDate)}  •  ${DateFormat('EEEE').format(dueDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF1E2420),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Chips: reminder + time + category + priority
                Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      if (t.dueTime != null)
                        _InfoChip(
                          label: t.dueTime!.format(context),
                          iconData: Icons.access_time,
                        ),
                      if (t.reminderTime != null)
                        _InfoChip(
                          label: 'Today', // As per mockup
                          iconData: Icons.notifications_none,
                        ),
                      if (t.category != null)
                        _InfoChip(
                          label: t.category!,
                          iconData: Icons.folder_outlined,
                        ),
                      if (t.priority != null)
                        _InfoChip(
                          label: t.priority!,
                          iconData: Icons.star_border,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Scrapbook images
                if (t.imagePaths.isNotEmpty) ...[
                  _SectionLabel('Images'),
                  const SizedBox(height: 12),
                  _ImageGrid(
                    paths: t.imagePaths,
                    onDelete: _deleteImage,
                  ),
                  const SizedBox(height: 28),
                ],

                // Paper note (Post-it style)
                Center(
                  child: Container(
                    key: _notesKey,
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          offset: const Offset(4, 8),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // The paper
                        _PaperNote(
                          controller: _noteController,
                          editing: _editingNote,
                          onTapEdit: () => setState(() => _editingNote = true),
                          onSave: _saveNote,
                          onDelete: () {
                            _noteController.clear();
                            _saveNote();
                          },
                        ),
                        // Tape graphic placeholder
                        Positioned(
                          top: -10,
                          left: MediaQuery.of(context).size.width * 0.4 - 30,
                          child: Container(
                            width: 60,
                            height: 20,
                            color: const Color(0xFFE8D3AD).withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Notes Checkbox section
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2420),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0D1C2), // Sage Green background
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildMockCheckbox(true, 'Fruits'),
                          const SizedBox(width: 40),
                          _buildMockCheckbox(false, 'Oats'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildMockCheckbox(false, 'Vegetables'),
                          const SizedBox(width: 40),
                          _buildMockCheckbox(false, 'Eggs'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildMockCheckbox(false, 'Milk'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),

          // Bottom toolbar
          _BottomToolbar(
            onImage: _imageSourceSheet,
            onNotes: () {
              setState(() => _editingNote = true);
              final ctx = _notesKey.currentContext;
              if (ctx != null) {
                Scrollable.ensureVisible(
                  ctx,
                  alignment: 1.0,
                  duration: const Duration(milliseconds: 300),
                );
              }
            },
          ),
        ],
      ),
    );
  }
  Widget _buildMockCheckbox(bool isChecked, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_box_outlined : Icons.check_box_outline_blank,
            color: const Color(0xFF1E2420),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF1E2420),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData iconData;

  const _InfoChip({required this.label, required this.iconData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE6D9), // Pastel beige background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 18, color: const Color(0xFF1E2420)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF1E2420),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: scheme.onSurface.withValues(alpha: 0.45),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> paths;
  final void Function(int) onDelete;

  const _ImageGrid({required this.paths, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: paths.length,
      itemBuilder: (context, i) {
        final path = paths[i];
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: File(path).existsSync()
                  ? Image.file(File(path), fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFDDE8D9),
                      child: const Center(
                        child: Icon(Icons.image_outlined, color: Colors.black38),
                      ),
                    ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => onDelete(i),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PaperNote extends StatelessWidget {
  final TextEditingController controller;
  final bool editing;
  final VoidCallback onTapEdit;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const _PaperNote({
    required this.controller,
    required this.editing,
    required this.onTapEdit,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasContent = controller.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF4E3), // Post-it paper color
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20), // Folded corner effect placeholder
          bottomRight: Radius.circular(8),
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Stack(
        children: [
          // Graphic Placeholder
          Positioned(
            bottom: -20,
            right: -20,
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 140,
              color: const Color(0xFFD6A268).withValues(alpha: 0.3), // Grocery bag brown
            ),
          ),
          
          editing
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLines: null,
                      style: GoogleFonts.caveat(fontSize: 28, color: const Color(0xFF1E2420), height: 1.5),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: onDelete,
                          child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: onSave,
                          child: const Text(
                            'Done',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: onTapEdit,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 60, bottom: 80), // Make room for graphic
                    child: Text(
                      hasContent ? controller.text : 'Tap to add a handwritten note…',
                      style: GoogleFonts.caveat(
                        fontSize: 32,
                        height: 1.5,
                        color: hasContent
                            ? const Color(0xFF1E2420)
                            : scheme.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: scheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  final VoidCallback onImage;
  final VoidCallback onNotes;

  const _BottomToolbar({
    required this.onImage,
    required this.onNotes,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F7F2),
        border: Border(top: BorderSide(color: Color(0x1A1E2420))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomAction(
            icon: Icons.draw_outlined,
            label: 'Doodle',
            onTap: () {},
          ),
          _BottomAction(
            icon: Icons.image_outlined,
            label: 'Image',
            onTap: onImage,
          ),
          _BottomAction(
            icon: Icons.notes,
            label: 'Notes',
            onTap: onNotes,
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF1E2420), size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1E2420),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
