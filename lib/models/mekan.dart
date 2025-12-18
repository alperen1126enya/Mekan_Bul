class Mekan {
  final int? id;
  final String name;
  final String category;
  final int ageMin;
  final int ageMax;
  final double rating;
  final String address;
  final String mapsUrl;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  bool isFavorite;
  bool isRecentlyViewed;

  Mekan({
    this.id,
    required this.name,
    required this.category,
    required this.ageMin,
    required this.ageMax,
    this.rating = 0.0,
    required this.address,
    required this.mapsUrl,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
    this.isFavorite = false,
    this.isRecentlyViewed = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'age_min': ageMin,
      'age_max': ageMax,
      'rating': rating,
      'address': address,
      'maps_url': mapsUrl,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Mekan.fromMap(Map<String, dynamic> map) {
    return Mekan(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      ageMin: map['age_min'] as int,
      ageMax: map['age_max'] as int,
      rating: (map['rating'] as num).toDouble(),
      address: map['address'] as String,
      mapsUrl: map['maps_url'] as String,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Mekan copyWith({
    int? id,
    String? name,
    String? category,
    int? ageMin,
    int? ageMax,
    double? rating,
    String? address,
    String? mapsUrl,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    bool? isFavorite,
    bool? isRecentlyViewed,
  }) {
    return Mekan(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      rating: rating ?? this.rating,
      address: address ?? this.address,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isRecentlyViewed: isRecentlyViewed ?? this.isRecentlyViewed,
    );
  }

  String get categoryDisplayName {
    switch (category.toLowerCase()) {
      case 'restoran':
        return '🍽️ Restoran';
      case 'cafe':
        return '☕ Cafe';
      case 'eglence':
        return '🎉 Eğlence';
      case 'fast_food':
        return '🍔 Fast Food';
      case 'bar':
        return '🍸 Bar';
      default:
        return category;
    }
  }
}
