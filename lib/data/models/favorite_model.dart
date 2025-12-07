class Favorite {
  final int? id;
  final int placeId;
  final String createdAt;

  Favorite({
    this.id,
    required this.placeId,
    required this.createdAt,
  });

  factory Favorite.fromMap(Map<String, dynamic> map) => Favorite(
    id: map['id'],
    placeId: map['placeId'],
    createdAt: map['createdAt'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'placeId': placeId,
    'createdAt': createdAt,
  };
}
