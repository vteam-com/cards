// ignore: avoid_web_libraries_in_flutter
import 'package:cards/models/backend_model.dart';
import 'package:cards/models/deck_model.dart';
import 'package:cards/models/player_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
export 'package:cards/models/deck_model.dart';
export 'package:cards/models/player_model.dart';

class GameModel with ChangeNotifier {
  /// Creates a new game model.
  ///
  /// [gameRoomId] is the ID of the room this game is in.
  /// [names] is the list of player names.
  /// [isNewGame] indicates whether this is a new game or joining an existing one.
  GameModel({
    required this.gameRoomId,
    required this.loginUserName,
    required final List<String> names,
    bool isNewGame = false,
  }) {
    // Initialize players from the list of names
    for (final String name in names) {
      players.add(PlayerModel(name: name));
    }
    if (isNewGame) {
      initializeGame();
    }
  }

  /// The ID of the game room.
  final String gameRoomId;

  /// The name of the person running the app.
  final String loginUserName;

  /// List of players in the game.
  final List<PlayerModel> players = [];

  /// The deck of cards used in the game.
  DeckModel deck = DeckModel(1);

  /// The index of the player currently playing.
  int playerIdPlaying = 0;

  /// The index of the player being attacked in the final turn. -1 if not the final turn.
  int playerIdAttacking = -1;

  /// Whether the game is in the final turn.
  bool get isFinalTurn => playerIdAttacking != -1;

  /// The current state of the game.
  GameStates _gameState = GameStates.notStarted;

  /// The current state of the game.
  GameStates get gameState => _gameState;

  /// Sets the game state and updates the database if backend is ready.
  set gameState(GameStates value) {
    if (_gameState != value) {
      _gameState = value;

      if (backendReady) {
        final refPlayers =
            FirebaseDatabase.instance.ref().child('rooms/$gameRoomId');
        refPlayers.set(this.toJson());
      }
    }
  }

  /// The number of players in the game.
  int get numPlayers => players.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is GameModel &&
        other.gameState == gameState &&
        other.playerIdPlaying == playerIdPlaying &&
        listEquals(other.players, players);
  }

  @override
  int get hashCode =>
      Object.hash(gameState, playerIdPlaying, Object.hashAll(players));

  /// Loads the game state from a JSON object.
  ///
  /// [json] should contain:
  /// - 'deck': JSON object representing the deck state
  /// - 'playerIdPlaying': index of active player
  /// - 'playerIdAttacking': index of player being attacked (-1 if not in final turn)
  /// - 'state': string representation of game state
  void _loadGameState(Map<String, dynamic> json) {
    deck = DeckModel.fromJson(json['deck']);
    setActivePlayer(json['playerIdPlaying']);
    playerIdAttacking = json['playerIdAttacking'];
    _gameState = GameStates.values.firstWhere(
      (e) => e.toString() == json['state'],
      orElse: () => GameStates.pickCardFromEitherPiles,
    );
  }

  /// Updates the game model from a JSON object.
  ///
  /// [json] should contain:
  /// - 'players': array of player JSON objects
  /// - 'deck': deck JSON object
  /// - 'playerIdPlaying': active player index
  /// - 'playerIdAttacking': attacked player index
  /// - 'state': game state string
  void fromJson(Map<String, dynamic> json) {
    _loadPlayers(json['players']);
    _loadGameState(json);
  }

  /// Loads player data from a JSON array.
  ///
  /// [playersJson] array of player JSON objects containing player state.
  /// Clears existing players and recreates them from the JSON data,
  /// assigning sequential IDs starting from 0.
  void _loadPlayers(List<dynamic> playersJson) {
    players.clear();
    int index = 0;
    for (final playerJson in playersJson) {
      final PlayerModel player = PlayerModel.fromJson(playerJson);
      player.id = index++;
      players.add(player);
    }
  }

  void setActivePlayer(final int index) {
    playerIdPlaying = index;
    for (int index = 0; index < players.length; index++) {
      players[index].isActivePlayer = (index == playerIdPlaying);
    }
  }

  /// Converts the game model to a JSON object.
  ///
  /// The JSON object contains the following properties:
  /// - `players`: a list of JSON objects representing the players in the game
  /// - `deck`: a JSON object representing the game deck
  /// - `invitees`: a list of player names
  /// - `playerIdPlaying`: the index of the player currently playing
  /// - `playerIdAttacking`: the index of the player being attacked in the final turn, or -1 if not the final turn
  /// - `state`: the current state of the game as a string
  Map<String, dynamic> toJson() {
    return {
      'players': players.map((player) => player.toJson()).toList(),
      'deck': deck.toJson(),
      'invitees': players.map((player) => player.name).toList(),
      'playerIdPlaying': playerIdPlaying,
      'playerIdAttacking': playerIdAttacking,
      'state': gameState.toString(),
    };
  }

  /// Returns the name of the player at the given index.
  String getPlayerName(final int index) {
    if (index < 0 || index >= players.length) {
      return 'No one';
    }
    return players[index].name;
  }

  List<String> getPlayersNames() {
    return players.map((player) => player.name).toList();
  }

  /// Initializes the game state, including dealing cards and setting the initial game state.
  void initializeGame() {
    playerIdPlaying = 0;
    playerIdAttacking = -1;

    // Calculate number of decks based on number of players.
    final int numDecks = (numPlayers - 2) ~/ 2;
    deck.shuffle(numberOfDecks: 1 + numDecks);

    // Deal 9 cards to each player and reveal the initial 3.
    for (final PlayerModel player in players) {
      player.reset();
      dealCards(player);
      player.revealInitialCards();
    }

    // Add a card to the discard pile if the deck is not empty.
    if (deck.cardsDeckPile.isNotEmpty) {
      deck.cardsDeckDiscarded.add(deck.cardsDeckPile.removeLast());
    }
    gameState = GameStates.pickCardFromEitherPiles;
  }

  /// Deals 9 cards to the given player from the deck.
  ///
  /// [player The player to deal cards to.
  void dealCards(PlayerModel player) {
    for (int i = 0; i < 9; i++) {
      player.addCardToHand(deck.cardsDeckPile.removeLast());
    }
  }

  /// Allows a player to draw a card, either from the discard pile or the deck.
  ///
  /// [context] is the BuildContext used for displaying snackbar messages.
  /// [fromDiscardPile] indicates whether to draw from the discard pile or the deck.
  void selectTopCardOfDeck(
    BuildContext context, {
    required bool fromDiscardPile,
  }) {
    if (gameState != GameStates.pickCardFromEitherPiles) {
      showTurnNotification(context, "It's not your turn!");
      return;
    }

    if (fromDiscardPile && deck.cardsDeckDiscarded.isNotEmpty) {
      gameState = GameStates.swapDiscardedCardWithAnyCardsInHand;
    } else if (!fromDiscardPile && deck.cardsDeckPile.isNotEmpty) {
      gameState = GameStates.swapTopDeckCardWithAnyCardsInHandOrDiscard;
    } else {
      showTurnNotification(context, 'No cards available to draw!');
    }
  }

  /// Swaps the selected card with a card in the player's hand.
  ///
  /// [playerIndex] is the index of the player whose hand is being modified.
  /// [gridIndex] is the index of the card in the player's hand to swap.
  void swapCardWithTopPile(
    final PlayerModel player,
    final int gridIndex,
  ) {
    if (!validGridIndex(player.hand, gridIndex)) {
      return;
    }

    // do the swap
    CardModel cardToSwapFromPlayer = player.hand[gridIndex];
    // replace players card in their 3x3 with the selected card
    if (gameState == GameStates.swapDiscardedCardWithAnyCardsInHand) {
      player.hand[gridIndex] = deck.cardsDeckDiscarded.removeLast();
    } else {
      player.hand[gridIndex] = deck.cardsDeckPile.removeLast();
    }

    // ensure this card is revealed
    player.hand[gridIndex].isRevealed = true;

    // add players old card to to discard pile
    deck.cardsDeckDiscarded.add(cardToSwapFromPlayer);
  }

  /// Checks if the given grid index is valid for the given hand.
  bool validGridIndex(List<CardModel> hand, int index) {
    return index >= 0 && index < hand.length;
  }

  /// Reveals all remaining cards for the specified player.
  ///
  /// [playerIndex] is the index of the player whose cards should be revealed.
  void revealAllRemainingCardsFor(int playerIndex) {
    final PlayerModel player = players[playerIndex];
    for (final CardModel card in player.hand) {
      card.isRevealed = true;
    }
  }

  /// Handles revealing a card, either for flipping or swapping.
  ///
  /// [context] is the BuildContext used for displaying snackbar messages.
  /// [playerIndex] is the index of the player revealing the card.
  /// [cardIndex] is the index of the card being revealed.
  void revealCard(
    BuildContext context,
    final PlayerModel player,
    int cardIndex,
  ) {
    if (player.isActivePlayer == false) {
      notifyCardUnavailable(context, 'Wait your turn!');
      return;
    }

    if (handleFlipOneCardState(player, cardIndex) ||
        handleFlipAndSwapState(player, cardIndex)) {
      moveToNextPlayer(context);

      if (this.isFinalTurn) {
        if (areAllCardsFromHandsRevealed()) {
          gameState = GameStates.gameOver;
        }
      }
      return;
    }

    notifyCardUnavailable(context, 'Not allowed at the moment!');
  }

  /// Handles the logic for flipping a card during the [GameStates.revealOneHiddenCard] game state.
  bool handleFlipOneCardState(
    final PlayerModel player,
    final int cardIndex,
  ) {
    if (gameState == GameStates.revealOneHiddenCard &&
        player.hand[cardIndex].isRevealed == false) {
      // reveal the card
      player.hand[cardIndex].isRevealed = true;

      return true;
    }
    return false;
  }

  /// Handles the logic for flipping and swapping a card during the 'flipAndSwap' game state.
  bool handleFlipAndSwapState(
    final PlayerModel player,
    final int cardIndex,
  ) {
    if (gameState == GameStates.swapTopDeckCardWithAnyCardsInHandOrDiscard ||
        gameState == GameStates.swapDiscardedCardWithAnyCardsInHand) {
      swapCardWithTopPile(
        player,
        cardIndex,
      );

      return true;
    }
    return false;
  }

  /// Checks if the current player can perform an action.
  bool canCurrentPlayerAct(int playerIndex) {
    return playerIdPlaying == playerIndex;
  }

  /// Displays a snackbar message indicating that a card is unavailable.
  void notifyCardUnavailable(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// Checks if all cards are revealed for a specific player.
  bool areAllCardRevealed(final int playerIndex) {
    return players[playerIndex].areAllCardsRevealed();
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

  /// Advances the game to the next player's turn.
  void moveToNextPlayer(BuildContext context) {
    if (isFinalTurn) {
      revealAllRemainingCardsFor(playerIdPlaying);
    } else {
      if (areAllCardRevealed(playerIdPlaying)) {
        // Start Final Turn
        playerIdAttacking = playerIdPlaying;
      }
    }
    setActivePlayer((playerIdPlaying + 1) % players.length);
    gameState = GameStates.pickCardFromEitherPiles;
  }

  /// Returns a string representing the current game state, including the current player's name
  /// and the attacker's name if it's the final turn.
  String getGameStateAsString() {
    String playersName = getPlayerName(playerIdPlaying);
    String playerAttackerName = getPlayerName(playerIdAttacking);

    String inputText = playersName == loginUserName
        ? 'It\'s your turn $playersName'
        : 'It\'s $playersName\'s turn';

    if (isFinalTurn) {
      inputText =
          'Final Round. $inputText. You have to beat $playerAttackerName';
    }

    return inputText;
  }

  static String getLinkToGameFromInput(
    final String room,
    final List<String> names,
  ) {
    return '?room=$room&players=${names.join(",")}';
  }

  String get linkUri =>
      getLinkToGameFromInput(this.gameRoomId, this.getPlayersNames());

  String getLinkToGame() {
    if (kIsWeb) {
      return Uri.base.origin + linkUri;
    }
    return '';
  }
}

void showTurnNotification(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}

enum GameStates {
  notStarted,
  pickCardFromEitherPiles,
  swapTopDeckCardWithAnyCardsInHandOrDiscard,
  revealOneHiddenCard,
  swapDiscardedCardWithAnyCardsInHand,
  gameOver,
}
