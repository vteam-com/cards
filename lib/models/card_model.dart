class CardModel {
  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      suit: json['suit'],
      rank: json['rank'],
      isRevealed: json['isRevealed'] ?? false,
    );
  }
  CardModel({
    required this.suit,
    required this.rank,
    this.partOfSet = false,
    this.isRevealed = false,
  });
  final String suit;
  final String rank;

  bool isRevealed = false;
  bool isSelectable = false;
  bool partOfSet;

  @override
  String toString() {
    return '$rank $suit';
  }

  Map<String, dynamic> toJson() {
    return {
      'suit': suit,
      'rank': rank,
      'isRevealed': isRevealed ? true : null,
    };
  }

  static const List<String> suits = ['♥️', '♦️', '♣️', '♠️'];
  static const List<String> ranks = [
    'A',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'J',
    'Q',
    'K',
  ];

  /// Returns the numerical value of a card rank.
  ///
  /// Handles special cases for 'Joker', 'A', 'K', 'Q', 'J'.
  /// Ranks '2' through '10' return their face value.
  /// Returns 0 if the rank is invalid.
  int get value {
    if (rank == 'Joker') {
      return -2;
    }
    if (rank == 'A') {
      return 1;
    }
    if (rank == 'K') {
      return 0;
    }
    if (rank == 'Q') {
      return 12;
    }
    if (rank == 'J') {
      return 11;
    }

    // face value for cards from 2 to 10
    return int.tryParse(rank) ?? 0;
  }
}
