import 'package:cards/game_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'playing_card_widget.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var gameModel = Provider.of<GameModel>(context);

    // Load game state when the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      gameModel.loadGameState();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('9-Card Golf Game'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: gameModel.numPlayers,
              itemBuilder: (context, playerIndex) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Player ${playerIndex + 1}'),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                      ),
                      itemCount: gameModel.playerHands[playerIndex].length,
                      itemBuilder: (context, gridIndex) {
                        bool isVisible =
                            gameModel.cardVisibility[playerIndex][gridIndex];
                        var card =
                            gameModel.playerHands[playerIndex][gridIndex];
                        return GestureDetector(
                          onTap: () {
                            gameModel.toggleCardVisibility(
                                playerIndex, gridIndex);
                            gameModel
                                .saveGameState(); // Save state after changes
                          },
                          child: isVisible
                              ? PlayingCardWidget(card: card)
                              : const HiddenCardWidget(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                gameModel.drawCard(0);
                gameModel.saveGameState(); // Save state after draw action
              },
              child: Text('Draw from Deck (${gameModel.deck.length} left)'),
            ),
          ),
        ],
      ),
    );
  }
}
