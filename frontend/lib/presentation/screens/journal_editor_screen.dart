import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:signature/signature.dart';
import '../../application/providers/journal_provider.dart';
import '../../data/models/journal_entry.dart';

class JournalEditorScreen extends ConsumerStatefulWidget {
  final JournalEntry? entry;

  const JournalEditorScreen({super.key, this.entry});

  @override
  ConsumerState<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _focusNode = FocusNode();

  String _mood = 'Choose mood';
  bool _remember = false;
  DateTime _selectedDate = DateTime.now();
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _bodyController.text = widget.entry!.body;
      _mood = widget.entry!.mood.isNotEmpty ? widget.entry!.mood : 'Choose mood';
      _selectedDate = widget.entry!.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty && _bodyController.text.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }

    final now = DateTime.now();
    final entry = JournalEntry(
      id: widget.entry?.id ?? now.millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      body: _bodyController.text,
      date: _selectedDate,
      mood: _mood == 'Choose mood' ? '' : _mood,
      categoryId: 'Thoughts',
      isFavorite: _remember,
      createdAt: widget.entry?.createdAt ?? now,
      updatedAt: now,
      wordCount: _bodyController.text.trim().split(RegExp(r'\s+')).length,
      readingTimeMinutes: 1,
    );

    if (widget.entry != null) {
      ref.read(journalProvider.notifier).updateEntry(entry);
    } else {
      ref.read(journalProvider.notifier).addEntry(entry);
    }
    
    Navigator.pop(context);
  }

  void _insertMarkdown(String prefix, String suffix) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;

    if (selection.isValid) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
      
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + prefix.length + selectedText.length),
      );
    } else {
      final newText = text + prefix + suffix;
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length - suffix.length),
      );
    }
    _focusNode.requestFocus();
  }

  void _openDoodleDialog() async {
    final SignatureController signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: const Color(0xFF1E2420),
      exportBackgroundColor: Colors.transparent,
    );

    final Uint8List? doodleBytes = await showDialog<Uint8List>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Draw a Doodle', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        content: Container(
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFEFEFEF))),
          child: Signature(
            controller: signatureController,
            height: 300,
            width: 300,
            backgroundColor: const Color(0xFFFBF9F6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => signatureController.clear(),
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7A8A62)),
            onPressed: () async {
              if (signatureController.isNotEmpty) {
                final bytes = await signatureController.toPngBytes();
                Navigator.pop(context, bytes);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Insert', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (doodleBytes != null) {
      final base64String = base64Encode(doodleBytes);
      final markdownImage = '\n\n![doodle](data:image/png;base64,$base64String)\n\n';
      _insertMarkdown(markdownImage, '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _save,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF9F6),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEFEFEF), width: 1.5),
                      ),
                      child: const Icon(Icons.arrow_back, color: Color(0xFF1E2420), size: 24),
                    ),
                  ),
                  Row(
                    children: [
                      // Preview Toggle
                      GestureDetector(
                        onTap: () => setState(() => _isPreview = !_isPreview),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isPreview ? const Color(0xFFE4ECD9) : const Color(0xFFFBF9F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFEFEFEF), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(_isPreview ? Icons.edit : Icons.remove_red_eye_outlined, size: 18, color: const Color(0xFF1E2420)),
                              const SizedBox(width: 6),
                              Text(_isPreview ? 'Edit' : 'Preview', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF1E2420), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF9F6),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFEFEFEF), width: 1.5),
                        ),
                        child: const Icon(Icons.more_vert, color: Color(0xFF1E2420), size: 20),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title Header
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New Journal Entry',
                          style: GoogleFonts.dancingScript(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2C4329), // Dark green
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('🌿', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Capture your thoughts, feelings and moments',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: const Color(0xFF5A5A5A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 40, height: 1, color: const Color(0xFFB8C5B3)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.favorite_border, color: Color(0xFF8DA989), size: 16),
                        ),
                        Container(width: 40, height: 1, color: const Color(0xFFB8C5B3)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Title Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF9F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEFEFEF), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, color: Color(0xFF1E2420), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        maxLength: 80,
                        style: GoogleFonts.nunito(fontSize: 16, color: const Color(0xFF1E2420)),
                        decoration: InputDecoration(
                          hintText: 'Give your entry a title...',
                          hintStyle: GoogleFonts.nunito(fontSize: 16, color: const Color(0xFF7A7A7A)),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        onChanged: (text) => setState(() {}),
                      ),
                    ),
                    Text(
                      '${_titleController.text.length}/80',
                      style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF7A7A7A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Editor Box
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF9F6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFEFEFEF), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isPreview)
                      Container(
                        padding: const EdgeInsets.all(20),
                        constraints: const BoxConstraints(minHeight: 250),
                        child: MarkdownBody(
                          data: _bodyController.text.isEmpty ? '*No content*' : _bodyController.text,
                          imageBuilder: (uri, title, alt) {
                            if (uri.scheme == 'data') {
                              final base64String = uri.path.split(',').last;
                              final bytes = base64Decode(base64String);
                              return Image.memory(bytes);
                            }
                            return Image.network(uri.toString());
                          },
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.nunito(fontSize: 16, color: const Color(0xFF1E2420), height: 1.5),
                            h1: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E2420)),
                            h2: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E2420)),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextField(
                          controller: _bodyController,
                          focusNode: _focusNode,
                          maxLines: null,
                          minLines: 10,
                          style: GoogleFonts.nunito(fontSize: 16, color: const Color(0xFF1E2420), height: 1.5),
                          decoration: InputDecoration(
                            hintText: 'Start writing your thoughts... (Markdown supported)',
                            hintStyle: GoogleFonts.nunito(fontSize: 16, color: const Color(0xFF7A7A7A)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    
                    // Toolbar
                    if (!_isPreview)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Color(0xFFEFEFEF))),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FormatIcon(iconText: 'B', isBold: true, onTap: () => _insertMarkdown('**', '**')),
                              _FormatIcon(iconText: 'I', isItalic: true, onTap: () => _insertMarkdown('*', '*')),
                              _FormatIcon(iconText: 'U', isUnderline: true, onTap: () => _insertMarkdown('<u>', '</u>')), // Standard markdown doesn't have U, but HTML works
                              const _Divider(),
                              _FormatIcon(iconText: 'H1', onTap: () => _insertMarkdown('# ', '\n')),
                              _FormatIcon(iconText: 'H2', onTap: () => _insertMarkdown('## ', '\n')),
                              GestureDetector(
                                onTap: () => _insertMarkdown('- ', '\n'),
                                child: const Icon(Icons.format_list_bulleted, color: Color(0xFF1E2420), size: 24),
                              ),
                              const _Divider(),
                              GestureDetector(
                                onTap: _openDoodleDialog,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.draw, color: Color(0xFF1E2420), size: 20),
                                    Text('Doodle', style: GoogleFonts.nunito(fontSize: 10, color: const Color(0xFF1E2420))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Metadata List
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF9F6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEFEFEF), width: 1.5),
                ),
                child: Column(
                  children: [
                    _MetaRow(
                      icon: Icons.sentiment_satisfied_alt,
                      title: 'Mood',
                      trailingText: _mood,
                      showArrow: true,
                    ),
                    const Divider(height: 1, color: Color(0xFFEFEFEF)),
                    const _MetaRow(
                      icon: Icons.local_offer_outlined,
                      title: 'Tags',
                      trailingText: 'Add tags',
                      showArrow: true,
                      isArrowRight: true,
                    ),
                    const Divider(height: 1, color: Color(0xFFEFEFEF)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.bookmark_border, color: Color(0xFF5A5A5A), size: 22),
                          const SizedBox(width: 16),
                          Text('Remember this?', style: GoogleFonts.nunito(fontSize: 16, color: const Color(0xFF1E2420))),
                          const Spacer(),
                          Switch(
                            value: _remember,
                            onChanged: (v) => setState(() => _remember = v),
                            activeColor: Colors.white,
                            activeTrackColor: const Color(0xFF67793D),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFD4D4D4),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFEFEFEF)),
                    _MetaRow(
                      icon: Icons.calendar_today,
                      title: 'Date',
                      trailingText: DateFormat('dd MMM yyyy').format(_selectedDate),
                      trailingIcon: Icons.calendar_month,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A8A62), // Green
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Save Entry', style: GoogleFonts.nunito(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      const Icon(Icons.favorite_border, color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatIcon extends StatelessWidget {
  final String iconText;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final VoidCallback onTap;

  const _FormatIcon({
    required this.iconText, 
    this.isBold = false, 
    this.isItalic = false, 
    this.isUnderline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Text(
          iconText,
          style: TextStyle(
            fontSize: 18,
            color: const Color(0xFF1E2420),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFEFEFEF),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailingText;
  final bool showArrow;
  final bool isArrowRight;
  final IconData? trailingIcon;

  const _MetaRow({
    required this.icon,
    required this.title,
    required this.trailingText,
    this.showArrow = false,
    this.isArrowRight = false,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF5A5A5A), size: 22),
          const SizedBox(width: 16),
          Text(title, style: GoogleFonts.nunito(fontSize: 16, color: const Color(0xFF1E2420))),
          const Spacer(),
          Text(trailingText, style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF5A5A5A))),
          if (showArrow) ...[
            const SizedBox(width: 8),
            Icon(isArrowRight ? Icons.chevron_right : Icons.keyboard_arrow_down, color: const Color(0xFF5A5A5A), size: 20),
          ],
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(trailingIcon, color: const Color(0xFF5A5A5A), size: 20),
          ],
        ],
      ),
    );
  }
}
