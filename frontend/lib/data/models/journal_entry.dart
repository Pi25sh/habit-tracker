class JournalEntry {
  final String id;
  final String title;
  final String? subtitle;
  final String body; // Rich text or markdown
  final DateTime date;
  final String mood; // Emoji
  final String? weather;
  final String? location;
  final String categoryId;
  final List<String> tags;
  final bool isFavorite;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int readingTimeMinutes;
  final int wordCount;
  
  // Attachments can be stored as a JSON string array of paths
  final String? attachmentsJson;

  JournalEntry({
    required this.id,
    required this.title,
    this.subtitle,
    required this.body,
    required this.date,
    required this.mood,
    this.weather,
    this.location,
    required this.categoryId,
    this.tags = const [],
    this.isFavorite = false,
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.readingTimeMinutes = 0,
    this.wordCount = 0,
    this.attachmentsJson,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'body': body,
      'date': date.toIso8601String(),
      'mood': mood,
      'weather': weather,
      'location': location,
      'categoryId': categoryId,
      'tags': tags.join(','),
      'isFavorite': isFavorite ? 1 : 0,
      'isPinned': isPinned ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'readingTimeMinutes': readingTimeMinutes,
      'wordCount': wordCount,
      'attachmentsJson': attachmentsJson,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'],
      title: map['title'],
      subtitle: map['subtitle'],
      body: map['body'],
      date: DateTime.parse(map['date']),
      mood: map['mood'],
      weather: map['weather'],
      location: map['location'],
      categoryId: map['categoryId'],
      tags: (map['tags'] as String).isEmpty ? [] : (map['tags'] as String).split(','),
      isFavorite: map['isFavorite'] == 1,
      isPinned: map['isPinned'] == 1,
      isArchived: map['isArchived'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      readingTimeMinutes: map['readingTimeMinutes'],
      wordCount: map['wordCount'],
      attachmentsJson: map['attachmentsJson'],
    );
  }
}
