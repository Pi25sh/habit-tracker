import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  final int currentStreak;

  const AchievementsScreen({super.key, required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    final milestones = [1, 7, 14, 30, 50, 100, 200, 365, 730];
    
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBEB),
      appBar: AppBar(
        title: const Text('Achievements', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 32,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: milestones.length,
                  itemBuilder: (context, index) {
                    final milestone = milestones[index];
                    final isUnlocked = currentStreak >= milestone;

                    return Column(
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: isUnlocked ? const Color(0xFFFFD700).withValues(alpha: 0.2) : Colors.grey[300],
                                  shape: BoxShape.circle,
                                  border: isUnlocked ? Border.all(color: const Color(0xFFFFD700), width: 3) : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.emoji_events,
                                    size: 40,
                                    color: isUnlocked ? const Color(0xFFFFD700) : Colors.grey[500],
                                  ),
                                ),
                              ),
                              if (!isUnlocked)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black87,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.lock, size: 14, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$milestone days',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
