class CookingReminder {
  final String id;
  final String title;
  final DateTime scheduledDate;
  final String reminderType; // 'defrost', 'ingredient', 'prep', 'general'
  final bool isCompleted;

  const CookingReminder({
    required this.id,
    required this.title,
    required this.scheduledDate,
    this.reminderType = 'defrost',
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'scheduledDate': scheduledDate.toIso8601String(),
      'reminderType': reminderType,
      'isCompleted': isCompleted,
    };
  }

  factory CookingReminder.fromJson(Map<String, dynamic> json) {
    return CookingReminder(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      scheduledDate: DateTime.tryParse(json['scheduledDate'] as String? ?? '') ?? DateTime.now(),
      reminderType: json['reminderType'] as String? ?? 'defrost',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  CookingReminder copyWith({
    String? id,
    String? title,
    DateTime? scheduledDate,
    String? reminderType,
    bool? isCompleted,
  }) {
    return CookingReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      reminderType: reminderType ?? this.reminderType,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
