class AppNotification {
  final int? id;
  final int userId;
  final String title;
  final String body;
  final String type; // 'favorite_update', 'comment_reply', 'new_place'
  final int? referenceId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'reference_id': referenceId,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String,
      referenceId: map['reference_id'] as int?,
      isRead: (map['is_read'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  AppNotification copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    String? type,
    int? referenceId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case 'favorite_update':
        return '❤️ Favori Güncelleme';
      case 'comment_reply':
        return '💬 Yorum Yanıtı';
      case 'new_place':
        return '📍 Yeni Mekan';
      default:
        return '🔔 Bildirim';
    }
  }
}
