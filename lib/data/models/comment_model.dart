class Comment {
  final int? id;
  final int placeId;
  final String text;
  final int rating;
  final String date;

  Comment({
    this.id,
    required this.placeId,
    required this.text,
    required this.rating,
    required this.date,
  });

  factory Comment.fromMap(Map<String, dynamic> map) => Comment(
    id: map['id'],
    placeId: map['placeId'],
    text: map['text'],
    rating: map['rating'],
    date: map['date'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'placeId': placeId,
    'text': text,
    'rating': rating,
    'date': date,
  };
}
