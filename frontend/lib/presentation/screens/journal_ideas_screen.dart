import 'package:flutter/material.dart';

class JournalIdeasScreen extends StatefulWidget {
  const JournalIdeasScreen({super.key});

  @override
  State<JournalIdeasScreen> createState() => _JournalIdeasScreenState();
}

class _JournalIdeasScreenState extends State<JournalIdeasScreen> {
  final List<Map<String, dynamic>> _ideas = [
    {'title': 'Places I want to travel to', 'checked': false},
    {'title': 'Bucket lists', 'checked': false},
    {'title': 'Quotes', 'checked': false},
    {'title': 'Recipes', 'checked': false},
    {'title': 'About me page', 'checked': false, 'indent': true},
    {'title': 'Favourite songs', 'checked': false},
    {'title': 'Favourite movies', 'checked': false},
    {'title': 'Self care ideas', 'checked': false},
    {'title': 'One line a day', 'checked': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F0F1), // Very light pink background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Journal ideas ',
                  style: TextStyle(
                    fontSize: 28,
                    color: Color(0xFF2C2C2C),
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  '* ੈ✩‧₊˚♡',
                  style: TextStyle(
                    fontSize: 20,
                    color: const Color(0xFF2C2C2C).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ideas.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final idea = _ideas[index];
                final isIndented = idea['indent'] == true;
                
                return Row(
                  children: [
                    if (isIndented) const SizedBox(width: 32),
                    // Custom grip icon (6 dots)
                    Column(
                      children: [
                        Row(
                          children: [
                            _buildDot(),
                            const SizedBox(width: 4),
                            _buildDot(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildDot(),
                            const SizedBox(width: 4),
                            _buildDot(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildDot(),
                            const SizedBox(width: 4),
                            _buildDot(),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Custom Checkbox
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _ideas[index]['checked'] = !_ideas[index]['checked'];
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF5A5A5A), width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                          color: idea['checked'] ? const Color(0xFF5A5A5A) : Colors.transparent,
                        ),
                        child: idea['checked']
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        idea['title'],
                        style: TextStyle(
                          fontSize: 18,
                          color: const Color(0xFF2C2C2C),
                          decoration: idea['checked'] ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0xFF8C8C8C),
        shape: BoxShape.circle,
      ),
    );
  }
}
