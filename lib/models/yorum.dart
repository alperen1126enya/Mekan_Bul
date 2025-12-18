class Yorum {
  final int? id;
  final int mekanId;
  final int userId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? username; // For display purposes

  Yorum({
    this.id,
    required this.mekanId,
    required this.userId,
    required this.rating,
    required this.comment,
    DateTime? createdAt,
    this.username,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mekan_id': mekanId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Yorum.fromMap(Map<String, dynamic> map) {
    return Yorum(
      id: map['id'] as int?,
      mekanId: map['mekan_id'] as int,
      userId: map['user_id'] as int,
      rating: map['rating'] as int,
      comment: map['comment'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      username: map['username'] as String?,
    );
  }

  Yorum copyWith({
    int? id,
    int? mekanId,
    int? userId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    String? username,
  }) {
    return Yorum(
      id: id ?? this.id,
      mekanId: mekanId ?? this.mekanId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      username: username ?? this.username,
    );
  }
}
