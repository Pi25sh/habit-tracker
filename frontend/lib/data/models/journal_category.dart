class JournalCategory {
  final String id;
  final String name;
  final String? emoji;
  final String? coverImageUrl;
  final int color;
  final bool isDefault;
  final DateTime createdAt;

  JournalCategory({
    required this.id,
    required this.name,
    this.emoji,
    this.coverImageUrl,
    required this.color,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'coverImageUrl': coverImageUrl,
      'color': color,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory JournalCategory.fromMap(Map<String, dynamic> map) {
    return JournalCategory(
      id: map['id'],
      name: map['name'],
      emoji: map['emoji'],
      coverImageUrl: map['coverImageUrl'],
      color: map['color'],
      isDefault: map['isDefault'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
