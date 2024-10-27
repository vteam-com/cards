class PlayingCard {
  PlayingCard({required this.suit, required this.rank, required this.value});
  final String suit;
  final String rank;
  final int value;
}

List<PlayingCard> generateDeck({int numberOfDecks = 1}) {
  List<String> suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
  List<String> ranks = [
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
  List<PlayingCard> deck = [];

  // Generate the specified number of decks
  for (int deckCount = 0; deckCount < numberOfDecks; deckCount++) {
    for (String suit in suits) {
      for (String rank in ranks) {
        deck.add(PlayingCard(suit: suit, rank: rank, value: getValue(rank)));
      }
    }
    // Add Jokers to each deck
    deck.addAll([
      PlayingCard(suit: 'Joker', rank: 'Black', value: 0),
      PlayingCard(suit: 'Joker', rank: 'Red', value: 0),
    ]);
  }

  deck.shuffle();
  return deck;
}

int getValue(String rank) {
  // Jokers have a special role and can be assigned a value of 0 or another special value as needed
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
  return int.tryParse(rank) ?? 0;
}
