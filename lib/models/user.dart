class User {
  final int? id;
  final String username;
  final String email;
  final String passwordHash;
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? passwordHash,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
