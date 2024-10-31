import 'package:cards/models/game_model.dart';
import 'package:cards/widgets/blink_widget.dart';
import 'package:cards/widgets/blinking_text_widget.dart';
import 'package:cards/widgets/card_piles_widget.dart';
import 'package:cards/widgets/card_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayerZoneCtaWidget extends StatelessWidget {
  const PlayerZoneCtaWidget({
    super.key,
    required this.playerIndex,
    required this.isActivePlayer,
    required this.gameModel,
  });
  final int playerIndex;
  final bool isActivePlayer;
  final GameModel gameModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(child: buildContent(context)),
    );
  }

  Widget buildContent(BuildContext context) {
    if (isActivePlayer) {
      switch (gameModel.currentPlayerStates) {
        case CurrentPlayerStates.keepOrDiscard:
          return ctaKeepOrDiscard();
        case CurrentPlayerStates.flipAndSwap:
          return ctaSwapWithKeptCard();
        case CurrentPlayerStates.flipOneCard:
          return ctaFlipOneOfYourHiddenCards();
        case CurrentPlayerStates.pickCardFromPiles:
        default:
          return ctaPickCardFromPiles(context);
      }
    } else {
      return buildWaitingForTurnContent();
    }
  }

  Widget ctaKeepOrDiscard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: BlinkWidget(
            child: ElevatedButton(
              child: const Text(
                'Keep',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                gameModel.currentPlayerStates = CurrentPlayerStates.flipAndSwap;
              },
            ),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        FittedBox(
          fit: BoxFit.cover,
          child: CardWidget(
            card: gameModel.cardPickedUpFromDeckOrDiscarded!,
            revealed: true,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: BlinkWidget(
            child: ElevatedButton(
              child: const Text(
                'Discard',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                gameModel.deck.cardsDeckDiscarded
                    .add(gameModel.cardPickedUpFromDeckOrDiscarded!);
                gameModel.cardPickedUpFromDeckOrDiscarded = null;
                gameModel.currentPlayerStates = CurrentPlayerStates.flipOneCard;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget ctaSwapWithKeptCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildMiniInstructions(
          true,
          'Tap any of your ↓ cards\nto swap with this →',
        ),
        const SizedBox(
          width: 10,
        ),
        CardWidget(
          card: gameModel.cardPickedUpFromDeckOrDiscarded!,
          revealed: true,
        ),
      ],
    );
  }

  Widget ctaFlipOneOfYourHiddenCards() {
    return buildMiniInstructions(
      true,
      'Flip open one of your hidden cards',
    );
  }

  Widget ctaPickCardFromPiles(final BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        buildMiniInstructions(
          true,
          'Draw a card\nfrom\nthe piles ⇉',
        ),
        const SizedBox(
          width: 10,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: CardPilesWidget(
            cardsInDrawPile: context.watch<GameModel>().deck.cardsDeckPile,
            cardsDiscardPile:
                context.watch<GameModel>().deck.cardsDeckDiscarded,
            onPickedFromDrawPile: () {
              final gameModel = context.read<GameModel>();
              gameModel.drawCard(context, fromDiscardPile: false);
            },
            onPickedFromDiscardPile: () {
              final gameModel = context.read<GameModel>();
              gameModel.drawCard(context, fromDiscardPile: true);
            },
          ),
        ),
      ],
    );
  }

  Widget buildWaitingForTurnContent() {
    return buildMiniInstructions(
      isActivePlayer,
      gameModel.areAllCardRevealed(playerIndex)
          ? 'You are done.'
          : 'Wait for your turn :)',
    );
  }
}

Widget buildMiniInstructions(bool isActivePlayer, String text) {
  final style = TextStyle(
    fontSize: 18,
    color: Colors.white.withAlpha(isActivePlayer ? 255 : 140),
  );

  if (isActivePlayer) {
    return BlinkingTextWidget(text: text, style: style);
  } else {
    return Text(text, style: style);
  }
}