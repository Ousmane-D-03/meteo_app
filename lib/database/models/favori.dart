class Favorite {
  int? id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String city;
  bool isFavorite;

  Favorite({
    this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.city,
    this.isFavorite = false, // false: cache, true: favori
  });
  factory Favorite.fromMap(Map<String, dynamic> map) => Favorite(
        id: map['id'] as int?,
        name: map['name'] as String,
        category: map['category'] as String,
        latitude: map['latitude'] as double,
        longitude: map['longitude'] as double,
        city: map['city'] as String,
        isFavorite: (map['isFavorite'] as int?) == 1,
      );
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'isFavorite': isFavorite ? 1 : 0,
      };
}
