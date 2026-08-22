class ReadingPlanDocument {
  final int id;
  final String title;
  final bool isRead;
  final DateTime? openedAt;
  final DateTime createdAt;

  ReadingPlanDocument({
    required this.id,
    required this.title,
    required this.isRead,
    this.openedAt,
    required this.createdAt,
  });

  factory ReadingPlanDocument.fromJson(Map<String, dynamic> json) {
    return ReadingPlanDocument(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? 'Reading plan',
      isRead: json['is_read'] as bool? ?? false,
      openedAt: json['opened_at'] == null
          ? null
          : DateTime.tryParse(json['opened_at'] as String),
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at'] as String),
    );
  }
}

class ReadingChallenge {
  final int id;
  final String title;
  final String description;
  final String rules;
  final int targetBooks;
  final DateTime? deadline;
  final bool isActive;
  final bool joined;
  final bool alarmEnabled;
  final int membersCount;
  final DateTime createdAt;

  ReadingChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.rules,
    required this.targetBooks,
    this.deadline,
    required this.isActive,
    required this.joined,
    required this.alarmEnabled,
    required this.membersCount,
    required this.createdAt,
  });

  factory ReadingChallenge.fromJson(Map<String, dynamic> json) {
    return ReadingChallenge(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      rules: json['rules'] as String? ?? '',
      targetBooks: (json['target_books'] as num?)?.toInt() ?? 0,
      deadline: json['deadline'] == null
          ? null
          : DateTime.tryParse(json['deadline'] as String),
      isActive: json['is_active'] as bool? ?? true,
      joined: json['joined'] as bool? ?? false,
      alarmEnabled: json['alarm_enabled'] as bool? ?? false,
      membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at'] as String),
    );
  }

  ReadingChallenge copyWith({bool? joined, bool? alarmEnabled}) {
    return ReadingChallenge(
      id: id,
      title: title,
      description: description,
      rules: rules,
      targetBooks: targetBooks,
      deadline: deadline,
      isActive: isActive,
      joined: joined ?? this.joined,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      membersCount: membersCount,
      createdAt: createdAt,
    );
  }
}
