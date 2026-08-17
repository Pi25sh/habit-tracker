import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../../application/providers/habit_provider.dart';
import '../../data/models/habit.dart';

/// A single freehand stroke.
class _Stroke {
  final Color color;
  final double width;
  final bool eraser;
  final List<Offset> points;

  _Stroke({
    required this.color,
    required this.width,
    required this.eraser,
    required this.points,
  });
}

/// Doodle editor — a notebook-paper canvas with pen, eraser, undo, redo,
/// clear, brush size, a muted palette and a real save-to-PNG flow that
/// persists the doodle on the habit.
class DoodleScreen extends ConsumerStatefulWidget {
  final Habit habit;

  const DoodleScreen({super.key, required this.habit});

  @override
  ConsumerState<DoodleScreen> createState() => _DoodleScreenState();
}

class _DoodleScreenState extends ConsumerState<DoodleScreen> {
  final GlobalKey _boundaryKey = GlobalKey();

  final List<_Stroke> _strokes = [];
  final List<_Stroke> _redoStack = [];
  final List<Offset> _activePoints = [];

  Color _color = const Color(0xFF342D28);
  double _brushWidth = 6;
  bool _eraser = false;

  static const List<Color> _palette = [
    Color(0xFF342D28), // ink
    Color(0xFF756B61), // warm brown
    Color(0xFFAFC8B3), // sage
    Color(0xFFF4C85D), // sunshine
    Color(0xFFC9B8D8), // lavender
    Color(0xFFE9B8A7), // peach
  ];

  Habit get _current => ref.watch(habitProvider).firstWhere(
        (h) => h.id == widget.habit.id,
        orElse: () => widget.habit,
      );

  bool get _canUndo => _strokes.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _redoStack.add(_strokes.removeLast()));
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() => _strokes.add(_redoStack.removeLast()));
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _redoStack.clear();
    });
  }

  Future<void> _save() async {
    if (_strokes.isEmpty) {
      Navigator.pop(context);
      return;
    }
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final doodlesDir = Directory('${dir.path}/habit_doodles');
      if (!doodlesDir.existsSync()) doodlesDir.createSync(recursive: true);
      final file = File(
        '${doodlesDir.path}/${widget.habit.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());

      final h = _current;
      h.doodlePaths = List.of(h.doodlePaths)..add(file.path);
      ref.read(habitProvider.notifier).updateHabit(h);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Doodle save failed: $e');
    }
  }

  void _onPanStart(DragStartDetails details) {
    final ctx = _boundaryKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);
    setState(() {
      _activePoints
        ..clear()
        ..add(local);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final ctx = _boundaryKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox;
    final local = box.globalToLocal(details.globalPosition);
    setState(() => _activePoints.add(local));
  }

  void _onPanEnd(DragEndDetails details) {
    if (_activePoints.isEmpty) return;
    final stroke = _Stroke(
      color: _color,
      width: _brushWidth,
      eraser: _eraser,
      points: List.of(_activePoints),
    );
    setState(() {
      _strokes.add(stroke);
      _redoStack.clear();
      _activePoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F0DE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: scheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Doodle',
          style: GoogleFonts.caveat(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        actions: [
          // Undo / Redo
          IconButton(
            icon: const Icon(Icons.undo),
            color: _canUndo ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.25),
            onPressed: _canUndo ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            color: _canRedo ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.25),
            onPressed: _canRedo ? _redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: _strokes.isEmpty
                ? scheme.onSurface.withValues(alpha: 0.25)
                : Colors.redAccent,
            onPressed: _strokes.isEmpty ? null : _clear,
          ),
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Notebook canvas
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _DoodlePainter(
                          strokes: _strokes,
                          activePoints: _activePoints,
                          color: _color,
                          brushWidth: _brushWidth,
                          eraser: _eraser,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Toolbar
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pen / eraser toggle + brush size
                Row(
                  children: [
                    _ModeButton(
                      icon: Icons.edit,
                      label: 'Pen',
                      active: !_eraser,
                      onTap: () => setState(() => _eraser = false),
                    ),
                    const SizedBox(width: 8),
                    _ModeButton(
                      icon: Icons.auto_fix_high,
                      label: 'Eraser',
                      active: _eraser,
                      onTap: () => setState(() => _eraser = true),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 10),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                activeTrackColor: scheme.primary,
                                inactiveTrackColor: scheme.primary.withValues(alpha: 0.2),
                                thumbColor: scheme.primary,
                                overlayColor: scheme.primary.withValues(alpha: 0.15),
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                              ),
                              child: Slider(
                                value: _brushWidth,
                                min: 2,
                                max: 22,
                                onChanged: (v) => setState(() => _brushWidth = v),
                              ),
                            ),
                          ),
                          const Icon(Icons.circle, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Palette
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _palette.map((c) {
                    final selected = !_eraser && _color == c;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _eraser = false;
                        _color = c;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? scheme.onSurface : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    );
                  }).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  final List<_Stroke> strokes;
  final List<Offset> activePoints;
  final Color color;
  final double brushWidth;
  final bool eraser;

  _DoodlePainter({
    required this.strokes,
    required this.activePoints,
    required this.color,
    required this.brushWidth,
    required this.eraser,
  });

  static const Color _paper = Color(0xFFFBF7EA);
  static const Color _line = Color(0xFFD8CCB8);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Paper
    canvas.drawRect(rect, Paint()..color = _paper);

    // Ruled notebook lines
    final linePaint = Paint()
      ..color = _line.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (double y = 42; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    canvas.drawLine(
      const Offset(44, 0),
      const Offset(44, 0) + Offset(0, size.height),
      Paint()
        ..color = const Color(0xFFE9B8A7).withValues(alpha: 0.6)
        ..strokeWidth = 1.5,
    );

    // Strokes
    canvas.saveLayer(rect, Paint());
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (activePoints.length >= 2) {
      _drawStroke(
        canvas,
        _Stroke(
          color: color,
          width: brushWidth,
          eraser: eraser,
          points: activePoints,
        ),
      );
    }
    canvas.restore();
  }

  void _drawStroke(Canvas canvas, _Stroke stroke) {
    if (stroke.points.isEmpty) return;
    final paint = Paint()
      ..color = stroke.eraser ? Colors.transparent : stroke.color
      ..blendMode = stroke.eraser ? BlendMode.clear : BlendMode.srcOver
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(_smoothPath(stroke.points), paint);
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path();
    if (points.length < 2) {
      path.moveTo(points.first.dx, points.first.dy);
      path.lineTo(points.first.dx + 0.1, points.first.dy + 0.1);
      return path;
    }
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) => true;
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? scheme.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? scheme.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? scheme.primary : scheme.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                color: active ? scheme.primary : scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
