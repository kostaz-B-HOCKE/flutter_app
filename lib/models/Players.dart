
class Player {
  final int id;
  final String nickname;
  final double rating;
  final int matchesPlayed;

  Player({
    required this.id,
    required this.nickname,
    required this.rating,
    required this.matchesPlayed,
  });

  // Краткое описание для отладки
  @override
  String toString() {
    return 'Player: $nickname (Рейтинг: $rating)';
  }
}