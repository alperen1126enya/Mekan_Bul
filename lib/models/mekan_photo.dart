class MekanPhoto {
  final int? id;
  final int mekanId;
  final String photoUrl;
  final int? uploadedBy;
  final DateTime createdAt;

  MekanPhoto({
    this.id,
    required this.mekanId,
    required this.photoUrl,
    this.uploadedBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mekan_id': mekanId,
      'photo_url': photoUrl,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MekanPhoto.fromMap(Map<String, dynamic> map) {
    return MekanPhoto(
      id: map['id'] as int?,
      mekanId: map['mekan_id'] as int,
      photoUrl: map['photo_url'] as String,
      uploadedBy: map['uploaded_by'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  MekanPhoto copyWith({
    int? id,
    int? mekanId,
    String? photoUrl,
    int? uploadedBy,
    DateTime? createdAt,
  }) {
    return MekanPhoto(
      id: id ?? this.id,
      mekanId: mekanId ?? this.mekanId,
      photoUrl: photoUrl ?? this.photoUrl,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
