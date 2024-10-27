import 'package:cards/playing_card_widget.dart';
import 'package:cards/widgets/card_deck.dart';
import 'package:cards/widgets/player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_model.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('9-Card Golf Game'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Consumer<GameModel>(
                    builder: (context, gameModel, _) {
                      return SingleChildScrollView(
                        child: Wrap(
                          spacing: 40.0,
                          runSpacing: 40.0,
                          children: List.generate(
                            gameModel.numPlayers,
                            (playerIndex) {
                              var playerName =
                                  gameModel.playerNames[playerIndex];
                              var playerScore =
                                  gameModel.calculatePlayerScore(playerIndex);

                              return Container(
                                width: 300,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade800.withAlpha(100),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Player(
                                      name: playerName,
                                      score: playerScore,
                                    ),
                                    const SizedBox(height: 20),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                      ),
                                      itemCount: gameModel
                                          .playerHands[playerIndex].length,
                                      itemBuilder: (context, gridIndex) {
                                        bool isVisible = gameModel
                                                .cardVisibility[playerIndex]
                                            [gridIndex];
                                        var card =
                                            gameModel.playerHands[playerIndex]
                                                [gridIndex];
                                        return GestureDetector(
                                          onTap: () {
                                            gameModel.toggleCardVisibility(
                                                playerIndex, gridIndex);
                                            gameModel.saveGameState();
                                          },
                                          child: isVisible
                                              ? PlayingCardWidget(card: card)
                                              : const HiddenCardWidget(),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              DeckOfCards(
                cardsRemaining: context.watch<GameModel>().deck.length,
                topOpenCard: context.watch<GameModel>().openCards.isNotEmpty
                    ? context.watch<GameModel>().openCards.last
                    : null, // Correct param usage
                onDrawCard: () {
                  context.read<GameModel>().drawCard(
                      0); // Ensure the method is correctly implemented
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}
