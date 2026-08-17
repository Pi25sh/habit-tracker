import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../application/providers/background_provider.dart';
import '../../application/providers/navigation_provider.dart';

void showAddBgDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: const AddBgDialog(),
    ),
  );
}

class AddBgDialog extends ConsumerStatefulWidget {
  const AddBgDialog({super.key});

  @override
  ConsumerState<AddBgDialog> createState() => _AddBgDialogState();
}

class _AddBgDialogState extends ConsumerState<AddBgDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Because we need ref to read the index, we can't do it in initState directly.
    // Instead we do it in didChangeDependencies.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentIndex = ref.read(navigationIndexProvider);
    final bgMap = ref.read(backgroundProvider);
    final currentBg = bgMap[currentIndex] ?? '';
    
    if (currentBg.startsWith('http')) {
      _controller.text = currentBg;
    } else if (currentBg.isNotEmpty) {
      _controller.text = '(Custom Image Selected)';
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isLoading = true);
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Compress to save storage
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final currentIndex = ref.read(navigationIndexProvider);
        ref.read(backgroundProvider.notifier).setBackground(currentIndex, 'base64,$base64String');
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Set Background Image',
        style: GoogleFonts.kalam(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E2F23),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pick an image from your device or enter a URL.',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: const Color(0xFF7A7A7A),
            ),
          ),
          const SizedBox(height: 24),
          
          if (_isLoading)
            const CircularProgressIndicator(color: Color(0xFF5A7851))
          else
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library, color: Colors.white),
              label: Text(
                'Choose from Device',
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A7851),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('OR', style: GoogleFonts.nunito(color: const Color(0xFF9E9E9E), fontWeight: FontWeight.w700)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFBF9F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFEFEF), width: 1.5),
            ),
            child: TextField(
              controller: _controller,
              style: GoogleFonts.nunito(fontSize: 16, color: const Color(0xFF1E2F23)),
              decoration: InputDecoration(
                hintText: 'https://example.com/image.jpg',
                hintStyle: GoogleFonts.nunito(fontSize: 16, color: const Color(0xFF9E9E9E)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final currentIndex = ref.read(navigationIndexProvider);
            ref.read(backgroundProvider.notifier).clearBackground(currentIndex);
            Navigator.pop(context);
          },
          child: Text(
            'Clear',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFD32F2F),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7A7A7A),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text != '(Custom Image Selected)' && text.isNotEmpty) {
              final currentIndex = ref.read(navigationIndexProvider);
              ref.read(backgroundProvider.notifier).setBackground(currentIndex, text);
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E2F23),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Save URL',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
