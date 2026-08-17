import 'package:flutter/material.dart';

class NotificationSchedulingScreen extends StatefulWidget {
  const NotificationSchedulingScreen({super.key});

  @override
  State<NotificationSchedulingScreen> createState() => _NotificationSchedulingScreenState();
}

class _NotificationSchedulingScreenState extends State<NotificationSchedulingScreen> {
  bool _morningReminder = true;
  bool _eveningReminder = false;
  bool _smartReminders = true;
  
  TimeOfDay _morningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 20, minute: 0);

  Future<void> _selectTime(BuildContext context, bool isMorning) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isMorning ? _morningTime : _eveningTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      }
    );
    if (picked != null) {
      setState(() {
        if (isMorning) {
          _morningTime = picked;
        } else {
          _eveningTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Daily Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 16),
          
          _buildToggleCard(
            title: 'Morning Journal',
            subtitle: 'Set intentions for the day',
            icon: Icons.wb_sunny_outlined,
            color: Colors.orange,
            value: _morningReminder,
            onChanged: (val) => setState(() => _morningReminder = val),
            time: _morningTime,
            onTimeTap: () => _selectTime(context, true),
          ),
          
          _buildToggleCard(
            title: 'Evening Reflection',
            subtitle: 'Review your day and wind down',
            icon: Icons.nightlight_round,
            color: Colors.indigo,
            value: _eveningReminder,
            onChanged: (val) => setState(() => _eveningReminder = val),
            time: _eveningTime,
            onTimeTap: () => _selectTime(context, false),
          ),
          
          const SizedBox(height: 32),
          const Text('Smart Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF673AB7).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF673AB7)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Smart Prompts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('AI-generated contextual reminders based on your mood', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: _smartReminders,
                  onChanged: (val) => setState(() => _smartReminders = val),
                  activeThumbColor: Colors.black,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
    required TimeOfDay time,
    required VoidCallback onTimeTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.black,
              ),
            ],
          ),
          if (value) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Reminder Time', style: TextStyle(fontWeight: FontWeight.w600)),
                GestureDetector(
                  onTap: onTimeTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      time.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}
