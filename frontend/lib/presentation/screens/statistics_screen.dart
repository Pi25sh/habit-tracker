import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/providers/habit_provider.dart';
import '../../data/models/habit.dart';
import '../../presentation/widgets/app_card.dart';
import '../../presentation/widgets/filter_chip.dart';
import 'habit_detail_screen.dart';

/// Habit Stats — a soft, editorial summary (never a hard analytics
/// dashboard). Circular progress, this-week chart and summary numbers.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  final List<String> _periods = ['This Week', 'This Month', 'All Time'];
  String _period = 'This Week';

  // ---- helpers ----

  bool _isInRange(DateTime d, DateTime start, DateTime end) =>
      !d.isBefore(start) && !d.isAfter(end);

  (DateTime, DateTime) get _range {
    final now = DateTime.now();
    if (_period == 'This Week') {
      final monday = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      return (monday, monday.add(const Duration(days: 6)));
    }
    if (_period == 'This Month') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      return (start, end);
    }
    return (DateTime(2020, 1, 1), DateTime(2035, 12, 31));
  }

  int _completedInRange(List<Habit> habits, DateTime start, DateTime end) {
    int count = 0;
    for (final h in habits) {
      count += h.completedDates
          .where((d) => _isInRange(d, start, end))
          .length;
    }
    return count;
  }

  int _scheduledInRange(List<Habit> habits, DateTime start, DateTime end) {
    int count = 0;
    for (final h in habits) {
      for (var d = start;
          !d.isAfter(end);
          d = d.add(const Duration(days: 1))) {
        if (h.repeatDays.contains(d.weekday)) count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final habits = ref.watch(habitProvider).where((h) => !h.isPaused).toList();

    final (start, end) = _range;
    final completed = _completedInRange(habits, start, end);
    final scheduled = _scheduledInRange(habits, start, end);
    final percent = scheduled == 0 ? 0 : (completed / scheduled * 100).round();

    int maxStreak = 0;
    for (final h in habits) {
      if (h.currentStreak > maxStreak) maxStreak = h.currentStreak;
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Habit Stats',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          // Period filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _periods.map((p) {
                return AppFilterChip(
                  label: p,
                  selected: _period == p,
                  onTap: () => setState(() => _period = p),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Circular progress
          Center(
            child: _CircularProgress(percent: percent),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              percent >= 75
                  ? 'Great Progress!'
                  : percent >= 50
                      ? 'Keep it up!'
                      : 'Every step counts',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '$completed of $scheduled days completed',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Summary numbers
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  value: '$completed',
                  label: 'Completed',
                  emoji: '✅',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  value: '${habits.length}',
                  label: 'Total Habits',
                  emoji: '🌱',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  value: '$maxStreak',
                  label: 'Current Streak',
                  emoji: '🔥',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Subtle weekly chart
          if (_period == 'This Week') ...[
            _WeekChart(habits: habits),
            const SizedBox(height: 28),
          ],

          // Habit list → Habit Detail
          Text(
            'Your habits',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          for (final h in habits)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HabitRow(
                habit: h,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HabitDetailScreen(habit: h),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircularProgress extends StatelessWidget {
  final int percent;

  const _CircularProgress({required this.percent});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = 180.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _ArcPainter(
              progress: percent / 100,
              trackColor: const Color(0xFFDDE8D9),
              progressColor: scheme.primary,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  'completion',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _ArcPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final arcAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      arcAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;

  const _SummaryCard({required this.value, required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  final List<Habit> habits;

  const _WeekChart({required this.habits});

  static const List<String> _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final counts = List<int>.filled(7, 0);
    for (var i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      for (final h in habits) {
        final done = h.completedDates.any(
          (c) => c.year == d.year && c.month == d.month && c.day == d.day,
        );
        if (done) counts[i]++;
      }
    }
    final maxCount = counts.reduce(math.max);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final height = maxCount == 0
                  ? 6.0
                  : 8.0 + (counts[i] / maxCount) * 52;
              final isToday = i == now.weekday - 1;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: height,
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFFF4C85D) : scheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _days[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                      color: isToday
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;

  const _HabitRow({required this.habit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Text(habit.icon ?? '🌱', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                habit.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '🔥 ${habit.currentStreak}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: scheme.onSurface.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}
