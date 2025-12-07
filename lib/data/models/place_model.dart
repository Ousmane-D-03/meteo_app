class Place {
  final int? id;
  final int cityId;
  final String name;
  final String category;
  final String? description;
  final double lat;
  final double lng;
  final String? imagePath;

  Place({
    this.id,
    required this.cityId,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    this.description,
    this.imagePath,
  });

  factory Place.fromMap(Map<String, dynamic> map) => Place(
    id: map['id'],
    cityId: map['cityId'],
    name: map['name'],
    category: map['category'],
    description: map['description'],
    lat: map['lat'],
    lng: map['lng'],
    imagePath: map['imagePath'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'cityId': cityId,
    'name': name,
    'category': category,
    'description': description,
    'lat': lat,
    'lng': lng,
    'imagePath': imagePath,
  };
}
