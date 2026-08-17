import 'package:flutter/material.dart';

class CalendarAnalyticsScreen extends StatefulWidget {
  const CalendarAnalyticsScreen({super.key});

  @override
  State<CalendarAnalyticsScreen> createState() => _CalendarAnalyticsScreenState();
}

class _CalendarAnalyticsScreenState extends State<CalendarAnalyticsScreen> {
  final List<String> _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: const Text('Calendar Analytics', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('August 2026', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.chevron_left, color: Colors.black54), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.chevron_right, color: Colors.black54), onPressed: () {}),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Custom Calendar Grid
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  // Weekdays
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _weekdays.map((w) => Text(w, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Calendar Days Grid Mock
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: 35, // 5 weeks layout
                    itemBuilder: (context, index) {
                      final day = index - 2; // Offset for starting day
                      final isCurrentMonth = day > 0 && day <= 31;
                      if (!isCurrentMonth) {
                        return const SizedBox();
                      }
                      
                      // Mock activity levels
                      final activityLevel = (day % 4 == 0) ? 1.0 : ((day % 3 == 0) ? 0.6 : 0.2);
                      final hasPerfectDay = day == 15 || day == 22;
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: hasPerfectDay 
                              ? Colors.amber 
                              : const Color(0xFF673AB7).withValues(alpha: activityLevel),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              color: activityLevel > 0.5 || hasPerfectDay ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Month Highlights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 16),
            
            Row(
              children: [
                _buildHighlightCard('Perfect Days', '2', Icons.star, Colors.amber),
                const SizedBox(width: 16),
                _buildHighlightCard('Total Habits', '142', Icons.check_circle, Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildHighlightCard('Best Streak', '14 Days', Icons.local_fire_department, Colors.orange),
                const SizedBox(width: 16),
                _buildHighlightCard('Completion', '84%', Icons.pie_chart, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
