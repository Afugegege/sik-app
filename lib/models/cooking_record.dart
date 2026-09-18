class CookingRecord {
  final String id;
  final String recipeTitle;
  final String koreanTitle;
  final DateTime date;
  final String photoUrl;
  final int rating;
  final String notes;
  final List<String> tags;

  const CookingRecord({
    required this.id,
    required this.recipeTitle,
    this.koreanTitle = '',
    required this.date,
    this.photoUrl = '',
    this.rating = 5,
    this.notes = '',
    this.tags = const [],
  });

  bool get hasPhoto => photoUrl.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeTitle': recipeTitle,
      'koreanTitle': koreanTitle,
      'date': date.toIso8601String(),
      'photoUrl': photoUrl,
      'rating': rating,
      'notes': notes,
      'tags': tags,
    };
  }

  factory CookingRecord.fromJson(Map<String, dynamic> json) {
    return CookingRecord(
      id: json['id'] as String? ?? '',
      recipeTitle: json['recipeTitle'] as String? ?? 'Home Cooked Meal',
      koreanTitle: json['koreanTitle'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      photoUrl: json['photoUrl'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      notes: json['notes'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  CookingRecord copyWith({
    String? id,
    String? recipeTitle,
    String? koreanTitle,
    DateTime? date,
    String? photoUrl,
    int? rating,
    String? notes,
    List<String>? tags,
  }) {
    return CookingRecord(
      id: id ?? this.id,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      koreanTitle: koreanTitle ?? this.koreanTitle,
      date: date ?? this.date,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }
}
