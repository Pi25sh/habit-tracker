import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';
import '../../application/providers/habit_provider.dart';
import '../../data/models/habit.dart';
import 'create_habit_screen.dart';
import 'habit_details_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitProvider);
    final today = DateTime.now();
    final todaysHabits = habits.where((h) => !h.isPaused).toList(); 
    final pausedCount = habits.where((h) => h.isPaused).length;

    int completedCount = 0;
    for (var h in todaysHabits) {
      if (h.completedDates.any((d) => d.year == today.year && d.month == today.month && d.day == today.day)) {
        completedCount++;
      }
    }

    double progress = todaysHabits.isEmpty ? 0 : completedCount / todaysHabits.length;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${_getGreeting()},\nShivani 🌸',
                                style: GoogleFonts.dancingScript(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                              icon: Icon(Icons.settings_outlined, color: colors.onSurface, size: 32),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('EEEE, MMMM d').format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildProgressRing(progress, completedCount, todaysHabits.length, colors),
                        const SizedBox(height: 32),
                        _buildQuoteCard(colors),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today\'s Habits',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurface,
                                  ),
                                ),
                                if (habits.isNotEmpty)
                                  Text(
                                    '${todaysHabits.length} Active • $pausedCount Paused',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CreateHabitScreen()),
                                );
                              },
                              icon: Icon(Icons.add_circle, color: colors.primary, size: 32),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                
                if (todaysHabits.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.eco_outlined, size: 64, color: colors.secondary.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'No habits yet!\nTap the + to plant your first seed.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.onSurface.withOpacity(0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final habit = todaysHabits[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          child: _buildHabitCard(habit, today, colors),
                        );
                      },
                      childCount: todaysHabits.length,
                    ),
                  ),
                  
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildWeeklyTrendChart(habits, colors),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: _buildAdBanner(colors),
                  ),
                ),
                  
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                colors.primary,
                colors.secondary,
                Colors.yellow,
                Colors.pinkAccent,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote, color: colors.primary.withOpacity(0.5), size: 32),
          const SizedBox(height: 8),
          Text(
            '"The secret of your future is hidden in your daily routine."',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: colors.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing(double progress, int completed, int total, ColorScheme colors) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Daily\nProgress',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completed of $total completed',
                  style: TextStyle(
                    color: colors.onSurface.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: colors.primary,
                        value: progress * 100,
                        title: '',
                        radius: 12,
                      ),
                      PieChartSectionData(
                        color: colors.onSurface.withOpacity(0.05),
                        value: (1 - progress) * 100,
                        title: '',
                        radius: 12,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, DateTime today, ColorScheme colors) {
    final isCompleted = habit.completedDates.any((d) => 
      d.year == today.year && d.month == today.month && d.day == today.day
    );

    final cardColor = Color(habit.color);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HabitDetailsScreen(habit: habit)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(habit.icon ?? '✨', style: const TextStyle(fontSize: 24)),
          ),
          title: Text(
            habit.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: colors.onSurface,
            ),
          ),
          subtitle: Text(
            '${habit.currentStreak} day streak 🔥',
            style: TextStyle(color: colors.onSurface.withOpacity(0.5)),
          ),
          trailing: GestureDetector(
            onTap: () {
              ref.read(habitProvider.notifier).toggleHabitCompletion(habit, today);
              if (!isCompleted) {
                _confettiController.play();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted ? colors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? colors.primary : colors.onSurface.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check,
                size: 20,
                color: isCompleted ? colors.onPrimary : Colors.transparent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart(List<Habit> habits, ColorScheme colors) {
    // Calculate completions for the last 7 days
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    List<int> completionsPerDay = List.filled(7, 0);
    
    for (int i = 0; i < 7; i++) {
      final date = todayStart.subtract(Duration(days: 6 - i));
      int count = 0;
      for (var habit in habits) {
        if (habit.completedDates.any((d) => d.year == date.year && d.month == date.month && d.day == date.day)) {
          count++;
        }
      }
      completionsPerDay[i] = count;
    }

    final maxY = (completionsPerDay.reduce((a, b) => a > b ? a : b).toDouble() + 1).clamp(5.0, double.infinity);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Trend',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final date = todayStart.subtract(Duration(days: 6 - value.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('E').format(date).substring(0, 1),
                            style: TextStyle(
                              color: colors.onSurface.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: completionsPerDay[i].toDouble(),
                        color: colors.primary,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: colors.primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdBanner(ColorScheme colors) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.onSurface.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ad_units, color: colors.onSurface.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text(
            'Google AdMob Banner',
            style: TextStyle(color: colors.onSurface.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
