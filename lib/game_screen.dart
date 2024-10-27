import 'package:cards/game_model.dart';
import 'package:cards/widgets/player.dart';
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
      body: Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover, // Ensures the image covers the whole area
          ),
        ),
        Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: gameModel.numPlayers,
                itemBuilder: (context, playerIndex) {
                  // Assuming player names and scores are available in your GameModel
                  var playerName = 'Player ${playerIndex + 1}'; // Example name
                  var playerScore = gameModel.calculatePlayerScore(
                      playerIndex); // Example score method

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Use the Player widget
                      Player(
                        name: playerName,
                        avatarUrl:
                            'https://example.com/avatar.jpg', // Replace with actual avatar data if available
                        score: playerScore,
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
      ]),
    );
  }
}
