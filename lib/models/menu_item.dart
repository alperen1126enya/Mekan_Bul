class MenuItem {
  final int? id;
  final int mekanId;
  final String name;
  final String? description;
  final double price;
  final String category;
  final String? imageUrl;
  final DateTime createdAt;

  MenuItem({
    this.id,
    required this.mekanId,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mekan_id': mekanId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as int?,
      mekanId: map['mekan_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      category: map['category'] as String,
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  MenuItem copyWith({
    int? id,
    int? mekanId,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      mekanId: mekanId ?? this.mekanId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Fiyatı Türk Lirası formatında döndür
  String get formattedPrice => '₺${price.toStringAsFixed(2)}';
}
