import 'dart:convert';

import 'package:cards/playing_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameModel with ChangeNotifier {
  List<PlayingCard> deck = [];
  List<List<PlayingCard>> playerHands = [];
  List<List<bool>> cardVisibility = [];
  final List<String> playerNames;

  GameModel({required this.playerNames}) {
    initializeGame();
  }

  int get numPlayers => playerNames.length;

  void initializeGame() {
    int numPlayers = playerNames.length;
    int numberOfDecks = numPlayers > 2 ? 2 : 1;
    deck = generateDeck(numberOfDecks: numberOfDecks);

    playerHands = List.generate(numPlayers, (_) => []);
    cardVisibility = List.generate(numPlayers, (_) => []);

    for (int i = 0; i < numPlayers; i++) {
      for (int j = 0; j < 9; j++) {
        playerHands[i].add(deck.removeLast());
        cardVisibility[i].add(false); // All cards are initially hidden
      }
      revealInitialCards(i);
    }
    notifyListeners();
  }

  void revealInitialCards(int playerIndex) {
    if (cardVisibility[playerIndex].length >= 2) {
      cardVisibility[playerIndex][0] = true;
      cardVisibility[playerIndex][1] = true;
    }
  }

  void toggleCardVisibility(int playerIndex, int cardIndex) {
    cardVisibility[playerIndex][cardIndex] =
        !cardVisibility[playerIndex][cardIndex];
    saveGameState(); // Save state after toggling visibility
    notifyListeners();
  }

  int calculatePlayerScore(index) {
    return 0;
  }

  void drawCard(int playerIndex) {
    if (deck.isNotEmpty) {
      playerHands[playerIndex].add(deck.removeLast());
      cardVisibility[playerIndex].add(true);
      saveGameState(); // Save state after drawing a card
      notifyListeners();
    }
  }

  Future<void> saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    // Save data to preferences
    prefs.setString('playerHands', _serializeHands(playerHands));
    prefs.setString('cardVisibility', _serializeVisibility(cardVisibility));
  }

  Future<void> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    // Load data from preferences
    String? handsData = prefs.getString('playerHands');
    String? visibilityData = prefs.getString('cardVisibility');
    if (handsData != null) {
      playerHands = _deserializeHands(handsData);
    }
    if (visibilityData != null) {
      cardVisibility = _deserializeVisibility(visibilityData);
    }
  }

  String _serializeHands(List<List<PlayingCard>> hands) {
    return jsonEncode(hands.map((hand) {
      return hand.map((card) {
        return {'suit': card.suit, 'rank': card.rank, 'value': card.value};
      }).toList();
    }).toList());
  }

  List<List<PlayingCard>> _deserializeHands(String data) {
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

  String _serializeVisibility(List<List<bool>> visibility) {
    return jsonEncode(visibility);
  }

  List<List<bool>> _deserializeVisibility(String data) {
    List<dynamic> jsonData = jsonDecode(data);
    return jsonData
        .map<List<bool>>((visibilityList) =>
            visibilityList.map<bool>((item) => item as bool).toList())
        .toList();
  }
}
