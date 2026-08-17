import 'package:flutter/material.dart';
import '../../data/models/habit.dart';
import 'package:fl_chart/fl_chart.dart';

class HabitPerformanceCard extends StatefulWidget {
  final Habit habit;

  const HabitPerformanceCard({super.key, required this.habit});

  @override
  State<HabitPerformanceCard> createState() => _HabitPerformanceCardState();
}

class _HabitPerformanceCardState extends State<HabitPerformanceCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Always Visible)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Color(widget.habit.color).withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Text(widget.habit.icon ?? '✨', style: const TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.habit.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                              const SizedBox(height: 4),
                              Text('${widget.habit.currentStreak} Day Streak 🔥', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              value: 0.85, // Mock 85% completion
                              strokeWidth: 6,
                              backgroundColor: Colors.black.withValues(alpha: 0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(widget.habit.color)),
                            ),
                          ),
                          const Text('85%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  
                  // Expanded Content
                  if (_isExpanded) ...[
                    const SizedBox(height: 32),
                    const Divider(color: Colors.black12),
                    const SizedBox(height: 24),
                    
                    // Detailed Stats Grid
                    Row(
                      children: [
                        _buildStatBox('Longest Streak', '${widget.habit.longestStreak} Days'),
                        const SizedBox(width: 16),
                        _buildStatBox('Best Month', 'June'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatBox('Avg Duration', '24 mins'),
                        const SizedBox(width: 16),
                        _buildStatBox('Missed Days', '2'),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // AI Suggestion Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFF3E5F5), Color(0xFFE1F5FE)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.amber),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('AI Insight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text('You consistently complete ${widget.habit.name} better on Tuesday mornings.', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Mini Line Chart Mock
                    const Text('Last 30 Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 120,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: 6,
                          minY: 0,
                          maxY: 6,
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 3), FlSpot(1, 1), FlSpot(2, 4),
                                FlSpot(3, 2), FlSpot(4, 5), FlSpot(5, 4), FlSpot(6, 6)
                              ],
                              isCurved: true,
                              color: Color(widget.habit.color),
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Color(widget.habit.color).withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
