class City {
  final int? id;
  final String name;
  final double lat;
  final double lng;
  final String? country;

  City({
    this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.country,
  });

  factory City.fromMap(Map<String, dynamic> map) => City(
    id: map['id'],
    name: map['name'],
    lat: map['lat'],
    lng: map['lng'],
    country: map['country'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'lat': lat,
    'lng': lng,
    'country': country,
  };
}
