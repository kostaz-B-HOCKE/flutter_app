
class Review {
  final int id;
  final int playerId; // ID игрока
  final String author;
  final String text;
  final bool isPositive; // Положительный или негативный отзыв
  final DateTime createdAt;

  Review({
    required this.id,
    required this.playerId,
    required this.author,
    required this.text,
    required this.isPositive,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      playerId: json['player_id'],
      author: json['author'],
      text: json['text'],
      isPositive: json['is_positive'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_id': playerId,
      'author': author,
      'text': text,
      'is_positive': isPositive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}