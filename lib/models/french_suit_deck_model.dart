import 'package:cards/models/game_model.dart';
import 'package:cards/models/golf_french_suit_card_model.dart';
export 'package:cards/models/card_model.dart';

class FrenchSuitDeckModel extends DeckModel {
  FrenchSuitDeckModel({required super.numberOfDecks});

  factory FrenchSuitDeckModel.fromJson(Map<String, dynamic> json) {
    return FrenchSuitDeckModel(numberOfDecks: json['numberOfDecks'] ?? 1)
      ..cardsDeckPile = List<GolfFrenchSuitCardModel>.from(
        json['cardsDeckPile']
                ?.map((card) => GolfFrenchSuitCardModel.fromJson(card)) ??
            [],
      )
      ..cardsDeckDiscarded = List<GolfFrenchSuitCardModel>.from(
        json['cardsDeckDiscarded']
                ?.map((card) => GolfFrenchSuitCardModel.fromJson(card)) ??
            [],
      );
  }

  @override
  void addCardsToDeck() {
    for (String suit in GolfFrenchSuitCardModel.suits) {
      for (String rank in GolfFrenchSuitCardModel.ranks) {
        cardsDeckPile.add(
          GolfFrenchSuitCardModel(
            suit: suit,
            rank: rank,
          ),
        );
      }
    }
    // Add 2 Jokers to each deck
    cardsDeckPile.addAll([
      CardModel(suit: '*', rank: '§'),
      CardModel(suit: '*', rank: '§'),
    ]);
  }
}
