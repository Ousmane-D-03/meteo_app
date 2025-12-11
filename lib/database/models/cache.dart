class Place {
  int? id;
  final String name;
  final String cityName;
  final double? latitude;
  final double? longitude;

  Place({
    this.id,
    required this.name,
    required this.cityName,
    required this.latitude,
    required this.longitude,
  });

  factory Place.fromMap(Map<String, dynamic> map) => Place(
    id: map['id'] as int?,
    name: map['name'] as String,
    cityName: map['cityName'] as String,
    latitude: map['latitude'] as double?,
    longitude: map['longitude'] as double?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'cityName': cityName,
    'latitude': latitude,
    'longitude': longitude,
  };
}
