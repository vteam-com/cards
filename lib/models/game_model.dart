import 'dart:convert';
import 'package:cards/models/player.dart';
import 'package:cards/screens/game_over_screen.dart';
import 'package:cards/widgets/playing_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameModel with ChangeNotifier {
  GameModel({required final List<String> names, required this.gameRoomId}) {
    // Initialize players from the list of names
    for (final String name in names) {
      players.add(Player(name: name));
    }
    initializeGame();
  }
  final String gameRoomId;
  // Player setup
  final List<Player> players = [];
  int numberOfDecks = 1;

  late int currentPlayerIndex;
  late bool finalTurn;
  late int playerIndexOfAttacker;

  // Game state initialization
  List<PlayingCard> cardsDeckPile = [];
  List<PlayingCard> cardsDeckDiscarded = [];

  // Private field to hold the state
  CurrentPlayerStates _currentPlayerStates =
      CurrentPlayerStates.pickCardFromPiles;

  String getPlayerName(final int index) {
    if (index == -1) {
      return 'No one';
    }
    return players[index].name;
  }

  // Public getter to access the current player states
  CurrentPlayerStates get currentPlayerStates => _currentPlayerStates;

  // Public setter to modify the current player states
  set currentPlayerStates(CurrentPlayerStates value) {
    if (_currentPlayerStates != value) {
      _currentPlayerStates = value;

      notifyListeners();
    }
  }

  PlayingCard? cardPickedUpFromDeckOrDiscarded;

  int get numPlayers => players.length;

  String get activePlayerName {
    if (currentPlayerIndex >= 0 && currentPlayerIndex < players.length) {
      return players[currentPlayerIndex].name;
    }
    return '';
  }

  /// Checks if all players have revealed all their cards.
  bool areAllCardsFromHandsRevealed() {
    for (int playerIndex = 0; playerIndex < numPlayers; playerIndex++) {
      if (!areAllCardRevealed(playerIndex)) {
        return false;
      }
    }
    return true;
  }

  /// Initializes the game by setting up the decks, hands, and visibility.
  void initializeGame() {
    currentPlayerIndex = 0;
    finalTurn = false;
    playerIndexOfAttacker = -1;

    final int numberOfDecks = numPlayers > 2 ? 2 : 1;
    cardsDeckPile = generateDeck(numberOfDecks: numberOfDecks);

    for (final Player player in players) {
      for (final _ in Iterable.generate(9)) {
        player.addCardToHand(cardsDeckPile.removeLast());
      }
      player.revealInitialCards();
    }

    if (cardsDeckPile.isNotEmpty) {
      cardsDeckDiscarded.add(cardsDeckPile.removeLast());
    }

    notifyListeners();
  }

  void drawCard(BuildContext context, {required bool fromDiscardPile}) {
    if (currentPlayerStates != CurrentPlayerStates.pickCardFromPiles) {
      showTurnNotification(context, "It's not your turn!");
      return;
    }

    if (fromDiscardPile && cardsDeckDiscarded.isNotEmpty) {
      cardPickedUpFromDeckOrDiscarded = cardsDeckDiscarded.removeLast();
      currentPlayerStates = CurrentPlayerStates.flipAndSwap;
    } else if (!fromDiscardPile && cardsDeckPile.isNotEmpty) {
      cardPickedUpFromDeckOrDiscarded = cardsDeckPile.removeLast();
      currentPlayerStates = CurrentPlayerStates.keepOrDiscard;
    } else {
      showTurnNotification(context, 'No cards available to draw!');
    }
    notifyListeners();
  }

  void swapCard(int playerIndex, int gridIndex) {
    if (cardPickedUpFromDeckOrDiscarded == null ||
        !validGridIndex(players[playerIndex].hand, gridIndex)) {
      // Access player's hand directly
      return;
    }

    PlayingCard cardToSwap =
        players[playerIndex].hand[gridIndex]; // Access player's hand directly
    cardsDeckDiscarded.add(cardToSwap);

    players[playerIndex].hand[gridIndex] =
        cardPickedUpFromDeckOrDiscarded!; // Access player's hand directly

    cardPickedUpFromDeckOrDiscarded = null;
    saveGameState();
  }

  bool validGridIndex(List<PlayingCard> hand, int index) {
    return index >= 0 && index < hand.length;
  }

  void revealAllRemainingCardsFor(int playerIndex) {
    final Player player = players[playerIndex];
    for (int indexCard = 0; indexCard < player.hand.length; indexCard++) {
      player.cardVisibility[indexCard] = true;
    }
    notifyListeners();
  }

  void revealCard(BuildContext context, int playerIndex, int cardIndex) {
    if (!canCurrentPlayerAct(playerIndex)) {
      notifyCardUnavailable(context, 'Wait your turn!');
      return;
    }

    if (handleFlipOneCardState(context, playerIndex, cardIndex) ||
        handleFlipAndSwapState(context, playerIndex, cardIndex)) {
      if (this.finalTurn) {
        revealAllRemainingCardsFor(playerIndex);
        if (areAllCardsFromHandsRevealed()) {
          endGame(context);
        }
      }
      return;
    }

    notifyCardUnavailable(context, 'Not allowed at the moment!');
  }

  void endGame(BuildContext context) {
    showGameOverDialog(
      context,
      players,
      initializeGame,
    );
  }

  bool handleFlipOneCardState(
    BuildContext context,
    int playerIndex,
    int cardIndex,
  ) {
    if (currentPlayerStates != CurrentPlayerStates.flipOneCard ||
        players[playerIndex].cardVisibility[cardIndex]) {
      return false;
    }

    players[playerIndex].cardVisibility[cardIndex] = true;
    currentPlayerStates = CurrentPlayerStates.pickCardFromPiles;
    finalizeAction(context);
    return true;
  }

  bool handleFlipAndSwapState(
    BuildContext context,
    int playerIndex,
    int cardIndex,
  ) {
    if (currentPlayerStates != CurrentPlayerStates.flipAndSwap) {
      return false;
    }

    players[playerIndex].cardVisibility[cardIndex] = true;
    swapCard(playerIndex, cardIndex);
    currentPlayerStates = CurrentPlayerStates.pickCardFromPiles;
    finalizeAction(context);
    return true;
  }

  void finalizeAction(BuildContext context) {
    advanceToNextPlayer(context);
    saveGameState();
    notifyListeners();
  }

  bool canCurrentPlayerAct(int playerIndex) {
    return currentPlayerIndex == playerIndex;
  }

  void notifyCardUnavailable(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  bool areAllCardRevealed(final int playerIndex) {
    return players[playerIndex]
        .cardVisibility
        .every((visible) => visible); // Access visibility directly
  }

  void advanceToNextPlayer(BuildContext context) {
    if (finalTurn == false) {
      if (areAllCardRevealed(currentPlayerIndex)) {
        playerIndexOfAttacker = currentPlayerIndex;
        triggerStartForRound(context);
      }
    }
    currentPlayerStates = CurrentPlayerStates.pickCardFromPiles;
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }

  Future<void> saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    // Directly access the player's hand from the players list
    prefs.setString(
      'playerHands',
      serializeHands(players.map((p) => p.hand).toList()),
    );
    prefs.setString(
      'cardVisibility',
      serializeVisibility(
        players.map((p) => p.cardVisibility).toList(),
      ),
    ); // Fix: Save cardVisibility per player
    prefs.setInt('currentPlayerIndex', currentPlayerIndex);
    prefs.setBool('finalTurn', finalTurn);
    prefs.setInt('playerIndexOfAttacker', playerIndexOfAttacker);
    prefs.setString(
      'cardsDeckPile',
      jsonEncode(cardsDeckPile.map((card) => card.toString()).toList()),
    );
    prefs.setString(
      'cardsDeckDiscarded',
      jsonEncode(cardsDeckDiscarded.map((card) => card.toString()).toList()),
    );
    // Consider saving other game state variables like cardsDeckPile, cardsDeckDiscarded, etc. as needed
  }

  String serializeHands(List<List<PlayingCard>> hands) {
    return jsonEncode(
      hands.map((hand) {
        return hand
            .map(
              (card) => {
                'suit': card.suit,
                'rank': card.rank,
                'value': card.value,
              },
            )
            .toList();
      }).toList(),
    );
  }

  List<List<PlayingCard>> deserializeHands(String data) {
    return (jsonDecode(data) as List).map<List<PlayingCard>>((hand) {
      return (hand as List).map<PlayingCard>((cardData) {
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
    return (jsonDecode(data) as List).map<List<bool>>((visibilityList) {
      return List<bool>.from(visibilityList);
    }).toList();
  }

  void triggerStartForRound(BuildContext context) {
    finalTurn = true;
    notifyListeners();
  }
}

void showTurnNotification(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}

enum CurrentPlayerStates {
  pickCardFromPiles,
  keepOrDiscard,
  flipOneCard,
  flipAndSwap,
  gameOver,
}
