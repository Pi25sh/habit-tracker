class DailyStatistics {
  final String id; // usually YYYY-MM-DD
  final DateTime date;
  final int completedHabits;
  final int totalHabits;
  final double completionPercentage;
  final int productivityScore; // 0-100
  final String? generatedInsight;
  final DateTime updatedAt;

  DailyStatistics({
    required this.id,
    required this.date,
    this.completedHabits = 0,
    this.totalHabits = 0,
    this.completionPercentage = 0.0,
    this.productivityScore = 0,
    this.generatedInsight,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'completedHabits': completedHabits,
      'totalHabits': totalHabits,
      'completionPercentage': completionPercentage,
      'productivityScore': productivityScore,
      'generatedInsight': generatedInsight,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DailyStatistics.fromMap(Map<String, dynamic> map) {
    return DailyStatistics(
      id: map['id'],
      date: DateTime.parse(map['date']),
      completedHabits: map['completedHabits'],
      totalHabits: map['totalHabits'],
      completionPercentage: map['completionPercentage'],
      productivityScore: map['productivityScore'],
      generatedInsight: map['generatedInsight'],
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
