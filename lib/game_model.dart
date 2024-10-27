import 'dart:convert';
import 'package:cards/widgets/playing_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CurrentPlayerStates {
  pickCardFromDeck,
  takeKeepOrDiscard,
  flipOneCard,
  flipAndSwap,
}

String getInstructionToPlayer(CurrentPlayerStates state) {
  switch (state) {
    case CurrentPlayerStates.pickCardFromDeck:
      return 'Pick a card from the deck or the discard pile';
    case CurrentPlayerStates.takeKeepOrDiscard:
      return 'Take, keep, or discard';
    case CurrentPlayerStates.flipOneCard:
      return 'Flip one card';
    case CurrentPlayerStates.flipAndSwap:
      return 'Swap one\nof your\ncards';
  }
}

class GameModel with ChangeNotifier {
  // Initialize with the first player by default

  GameModel({required this.playerNames}) {
    initializeGame();
  }
  List<PlayingCard> cardsInTheDeck = [];
  List<PlayingCard> discardedCards = [];
  List<List<PlayingCard>> playerHands = [];
  List<List<bool>> cardVisibility = [];
  final List<String> playerNames;
  int currentPlayerIndex = 0;

  int get numPlayers => playerNames.length;

  String get activePlayerName => playerNames[currentPlayerIndex];

  // This ensures the player has picked or drawn a card during their turn
  CurrentPlayerStates currentPlayerStates =
      CurrentPlayerStates.pickCardFromDeck;
  PlayingCard? cardPickedUpFromDeckOrDiscarded;

  void initializeGame() {
    // for testing
    // initializeGameWithAllAcesToFirstPlayer();
    // return;
    int numPlayers = playerNames.length;
    int numberOfDecks = numPlayers > 2 ? 2 : 1;
    cardsInTheDeck = generateDeck(numberOfDecks: numberOfDecks);

    playerHands = List.generate(numPlayers, (_) => []);
    cardVisibility = List.generate(numPlayers, (_) => []);

    for (int i = 0; i < numPlayers; i++) {
      for (int j = 0; j < 9; j++) {
        playerHands[i].add(cardsInTheDeck.removeLast());
        cardVisibility[i].add(false); // All cards are initially hidden
      }
      revealInitialCards(i);
    }
    notifyListeners();
  }

  void initializeGameWithAllAcesToFirstPlayer() {
    int numPlayers = playerNames.length;
    int numberOfDecks = numPlayers > 2 ? 2 : 1;
    cardsInTheDeck = generateDeck(numberOfDecks: numberOfDecks);

    playerHands = List.generate(numPlayers, (_) => []);
    cardVisibility = List.generate(numPlayers, (_) => []);

    // Extract all aces from the deck
    List<PlayingCard> aces =
        cardsInTheDeck.where((PlayingCard card) => card.rank == 'A').toList();

    cardsInTheDeck.removeWhere((card) => card.rank == 'A');

    // Add all aces to the first player's hand
    playerHands[0].addAll(aces);
    cardVisibility[0].addAll(List.generate(aces.length, (_) => true));

    // Deal the remaining cards to the first player
    for (int j = aces.length; j < 9; j++) {
      playerHands[0].add(cardsInTheDeck.removeLast());
      cardVisibility[0].add(true);
    }

    // Give specific cards to the second player at positions 2, 5, and 8
    if (numPlayers > 1) {
      for (int i = 0; i < 9; i++) {
        if (i == 2 || i == 5 || i == 8) {
          PlayingCard tenCard =
              cardsInTheDeck.firstWhere((card) => card.rank == '10');
          cardsInTheDeck.remove(tenCard);
          playerHands[1].add(tenCard);
        } else {
          playerHands[1].add(cardsInTheDeck.removeLast());
        }
        cardVisibility[1]
            .add(true); // Assume all cards should be visible initially
      }
    }

    // Deal cards to the remaining players, if any
    for (int i = 2; i < numPlayers; i++) {
      for (int j = 0; j < 9; j++) {
        playerHands[i].add(cardsInTheDeck.removeLast());
        cardVisibility[i].add(true);
      }
    }

    for (int i = 0; i < numPlayers; i++) {
      revealInitialCards(i);
    }

    notifyListeners();
  }

  bool isCardInDiscardPile(PlayingCard card) {
    // Implement logic to check if the specified card is in the discard pile
    return true; // Placeholder
  }

  void advanceToNextPlayer() {
    currentPlayerStates = CurrentPlayerStates.pickCardFromDeck;
    currentPlayerIndex = (currentPlayerIndex + 1) % playerNames.length;
    // Optional: Handle any additional end-turn actions, like checking game state
  }

  // Ensure that only the active player can draw a card
  void playerDrawsFromDeck(BuildContext context) {
    if (currentPlayerStates == CurrentPlayerStates.pickCardFromDeck &&
        cardsInTheDeck.isNotEmpty &&
        currentPlayerIndex == currentPlayerIndex) {
      cardPickedUpFromDeckOrDiscarded = cardsInTheDeck.removeLast();

      // Restrict further picking in the same turn
      currentPlayerStates = CurrentPlayerStates.takeKeepOrDiscard;

      notifyListeners();
    } else {
      showTurnNotification(context, "It's not your turn!");
    }
  }

  // Ensure that only the active player can draw a card
  void playerDrawsFromDiscardedDeck(BuildContext context) {
    if (currentPlayerStates == CurrentPlayerStates.pickCardFromDeck &&
        cardsInTheDeck.isNotEmpty &&
        currentPlayerIndex == currentPlayerIndex) {
      cardPickedUpFromDeckOrDiscarded = discardedCards.removeLast();

      // Restrict further picking in the same turn
      currentPlayerStates = CurrentPlayerStates.takeKeepOrDiscard;

      notifyListeners();
    } else {
      showTurnNotification(context, "It's not your turn!");
    }
  }

  void swapCard(int playerIndex, int gridIndex) {
    if (cardPickedUpFromDeckOrDiscarded == null) {
      // If no card has been picked up, the swap cannot occur
      return;
    }

    if (playerHands[playerIndex].isNotEmpty &&
        gridIndex >= 0 &&
        gridIndex < playerHands[playerIndex].length) {
      // Swap the player's card with the picked-up card
      PlayingCard cardToSwap = playerHands[playerIndex][gridIndex];

      // Add the player's card to the discard pile
      discardedCards.add(cardToSwap);

      // Place the picked-up card in the player's hand at the same position
      playerHands[playerIndex][gridIndex] = cardPickedUpFromDeckOrDiscarded!;

      // Clear the cardPickedUpFromDeckOrDiscarded after the swap
      cardPickedUpFromDeckOrDiscarded = null;

      // Save state and notify listeners to update UI
      saveGameState();
      notifyListeners();
    }
  }

  void moveCardToDiscardPile(int playerIndex, int cardIndex) {
    if (playerHands[playerIndex].isNotEmpty) {
      // Remove the card from the player's hand
      PlayingCard cardToDiscard = playerHands[playerIndex].removeAt(cardIndex);

      // Add the card to the top of the discarded pile
      discardedCards.add(cardToDiscard);

      // After updating, save the game state and notify listeners to reflect changes in the UI
      saveGameState();
      notifyListeners();
    }
  }

  /// This method can be called to automatically end the turn if all actions are complete
  void onPlayerActionComplete() {
    advanceToNextPlayer();
  }

  void revealInitialCards(int playerIndex) {
    if (cardVisibility[playerIndex].length >= 2) {
      cardVisibility[playerIndex][0] = true;
      cardVisibility[playerIndex][1] = true;
    }
  }

  void toggleCardVisibility(
    BuildContext context,
    int playerIndex,
    int cardIndex,
  ) {
    if (currentPlayerIndex == playerIndex) {
      if (currentPlayerStates == CurrentPlayerStates.flipOneCard) {
        currentPlayerStates = CurrentPlayerStates.pickCardFromDeck;
        cardVisibility[playerIndex][cardIndex] =
            !cardVisibility[playerIndex][cardIndex];
        saveGameState(); // Save state after toggling visibility
        notifyListeners();
      }
    } else {
      showTurnNotification(context, "It's not your turn!");
    }

    cardVisibility[playerIndex][cardIndex] =
        !cardVisibility[playerIndex][cardIndex];
    saveGameState(); // Save state after toggling visibility
    notifyListeners();
  }

  void revealCard(
    BuildContext context,
    int playerIndex,
    int cardIndex,
  ) {
    if (currentPlayerIndex == playerIndex &&
        !cardVisibility[playerIndex][cardIndex]) {
      if (currentPlayerStates == CurrentPlayerStates.flipOneCard ||
          currentPlayerStates == CurrentPlayerStates.flipAndSwap) {
        cardVisibility[playerIndex][cardIndex] = true;

        if (currentPlayerStates == CurrentPlayerStates.flipAndSwap) {
          swapCard(playerIndex, cardIndex);
        }
        currentPlayerStates = CurrentPlayerStates.pickCardFromDeck;

        saveGameState(); // Save state after changing visibility
        notifyListeners();
        nextPlayer();
      }
    } else {
      showTurnNotification(context, "It's not your turn!");
    }
  }

  bool areAllTheSameRank(
    final String rank1,
    final String rank2,
    final String rank3,
  ) {
    return rank1 == rank2 && rank2 == rank3;
  }

  bool areAllTheSameRankAndNotAlreadyUsed(
    final PlayingCard card1,
    final PlayingCard card2,
    final PlayingCard card3,
  ) {
    if (card1.partOfSet || card2.partOfSet || card3.partOfSet) {
      return false; // If any of the cards are already part of a set, return false
    }
    return areAllTheSameRank(card1.rank, card2.rank, card3.rank);
  }

  void markIfSameRankHorizontal(
    List<PlayingCard> hand,
    List<bool> markedForZeroScore,
    int startIndex,
  ) {
    if (areAllTheSameRankAndNotAlreadyUsed(
      hand[startIndex],
      hand[startIndex + 1],
      hand[startIndex + 2],
    )) {
      hand[startIndex + 0].partOfSet = true;
      hand[startIndex + 1].partOfSet = true;
      hand[startIndex + 2].partOfSet = true;
    }
  }

  void markIfSameRankVertical(
    List<PlayingCard> hand,
    List<bool> markedForZeroScore,
    int startIndex,
  ) {
    if (areAllTheSameRankAndNotAlreadyUsed(
      hand[startIndex + 0],
      hand[startIndex + 3],
      hand[startIndex + 6],
    )) {
      hand[startIndex + 0].partOfSet = true;
      hand[startIndex + 3].partOfSet = true;
      hand[startIndex + 6].partOfSet = true;
    }
  }

  int calculatePlayerScore(int index) {
    int score = 0;
    List<bool> markedForZeroScore =
        List.filled(playerHands[index].length, false);

    // Check for three identical ranks in a horizontally
    markIfSameRankHorizontal(playerHands[index], markedForZeroScore, 0);
    markIfSameRankHorizontal(playerHands[index], markedForZeroScore, 3);
    markIfSameRankHorizontal(playerHands[index], markedForZeroScore, 6);

    // Check for three identical ranks in a horizontally
    markIfSameRankVertical(playerHands[index], markedForZeroScore, 0);
    markIfSameRankVertical(playerHands[index], markedForZeroScore, 1);
    markIfSameRankVertical(playerHands[index], markedForZeroScore, 2);

    // Calculate the score
    for (int i = 0; i < playerHands[index].length; i++) {
      if (cardVisibility[index][i] && !playerHands[index][i].partOfSet) {
        // Add value of visible and non-zero-marked cards
        score += playerHands[index][i].value;
      }
    }

    return score;
  }

  void setActivePlayer(int index) {
    currentPlayerIndex = index;
    notifyListeners();
  }

  void nextPlayer() {
    setActivePlayer((currentPlayerIndex + 1) % numPlayers);
  }

  Future<void> saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('playerHands', serializeHands(playerHands));
    prefs.setString('cardVisibility', serializeVisibility(cardVisibility));
  }

  Future<void> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    String? handsData = prefs.getString('playerHands');
    String? visibilityData = prefs.getString('cardVisibility');
    if (handsData != null) {
      playerHands = deserializeHands(handsData);
    }
    if (visibilityData != null) {
      cardVisibility = deserializeVisibility(visibilityData);
    }
  }

  String serializeHands(List<List<PlayingCard>> hands) {
    return jsonEncode(
      hands.map((hand) {
        return hand.map((card) {
          return {'suit': card.suit, 'rank': card.rank, 'value': card.value};
        }).toList();
      }).toList(),
    );
  }

  List<List<PlayingCard>> deserializeHands(String data) {
    List<dynamic> jsonData = jsonDecode(data);
    return jsonData.map<List<PlayingCard>>((hand) {
      return hand.map<PlayingCard>((cardData) {
        return PlayingCard(
          suit: cardData['suit'],
          rank: cardData['rank'],
          value: cardData['value'],
        );
      }).toList();
    }).toList();
  }

  String serializeVisibility(List<List<bool>> visibility) {
    return jsonEncode(visibility);
  }

  List<List<bool>> deserializeVisibility(String data) {
    List<dynamic> jsonData = jsonDecode(data);
    return jsonData
        .map<List<bool>>(
          (visibilityList) =>
              visibilityList.map<bool>((item) => item as bool).toList(),
        )
        .toList();
  }
}

void showTurnNotification(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(
        seconds: 2,
      ), // Duration for which the SnackBar will be visible
    ),
  );
}
