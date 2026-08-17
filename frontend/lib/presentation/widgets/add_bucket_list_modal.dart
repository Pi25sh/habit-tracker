import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../application/providers/task_provider.dart';
import '../../data/models/task.dart';

class AddBucketListModal extends ConsumerStatefulWidget {
  const AddBucketListModal({super.key});

  @override
  ConsumerState<AddBucketListModal> createState() => _AddBucketListModalState();
}

class _AddBucketListModalState extends ConsumerState<AddBucketListModal> {
  final _titleController = TextEditingController();
  final _imageController = TextEditingController();
  String _selectedCategory = 'Travel';
  final List<String> _categories = ['Travel', 'Personal', 'Dreams'];

  @override
  void dispose() {
    _titleController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) return;

    final newTask = Task(
      id: const Uuid().v4(),
      name: _titleController.text.trim(),
      color: 0xFF4A90E2, // Default color, can map to category later
      category: _selectedCategory,
      imagePaths: _imageController.text.trim().isNotEmpty 
          ? [_imageController.text.trim()] 
          : [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    ref.read(taskProvider.notifier).addTask(newTask);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFDFCFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        top: 32,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'New Bucket List Item 🌿',
            style: GoogleFonts.kalam(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E2F23),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          _buildTextField('What do you want to do?', _titleController, Icons.check_circle_outline),
          const SizedBox(height: 16),
          _buildTextField('Image URL (optional)', _imageController, Icons.image_outlined),
          const SizedBox(height: 24),
          
          Text(
            'Category',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7A7A7A),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(
                  cat,
                  style: GoogleFonts.nunito(
                    color: isSelected ? const Color(0xFF1E2F23) : const Color(0xFF7A7A7A),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFFE8F1E4),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : const Color(0xFFEFEFEF),
                  ),
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCategory = cat);
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A7851),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Text(
              'Add to Bucket List',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.nunito(fontSize: 16, color: const Color(0xFF1E2F23)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(fontSize: 16, color: const Color(0xFF9E9E9E)),
          prefixIcon: Icon(icon, color: const Color(0xFF7A7A7A)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
