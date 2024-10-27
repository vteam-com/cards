import 'package:cards/game_model.dart';
import 'package:cards/widgets/player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'playing_card_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  final TextEditingController _controller = TextEditingController();
  String _errorText = '';

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
              fit: BoxFit.cover, // Ensures the image covers the whole area
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.green.shade100,
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText:
                        'Enter players names separated by space, comma, or semicolon',
                    errorText: _errorText.isEmpty ? null : _errorText,
                  ),
                ),
              ),
              Expanded(
                child: Consumer<GameModel>(
                  builder: (context, gameModel, _) {
                    return ListView.builder(
                      itemCount: gameModel.numPlayers,
                      itemBuilder: (context, playerIndex) {
                        var playerName = gameModel.playerNames[playerIndex];
                        var playerScore =
                            gameModel.calculatePlayerScore(playerIndex);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Use the Player widget
                            Player(
                              name: playerName,
                              avatarUrl: 'https://example.com/avatar.jpg',
                              score: playerScore,
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                              ),
                              itemCount:
                                  gameModel.playerHands[playerIndex].length,
                              itemBuilder: (context, gridIndex) {
                                bool isVisible = gameModel
                                    .cardVisibility[playerIndex][gridIndex];
                                var card = gameModel.playerHands[playerIndex]
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
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      var playerNames = _controller.text
                          .split(RegExp(
                              r'[ ,;]+')) // Split by space, comma, or semicolon
                          .where((name) => name.isNotEmpty)
                          .toList();

                      if (playerNames.isNotEmpty) {
                        // Initialize a new GameModel with the entered player names
                        final gameModel =
                            Provider.of<GameModel>(context, listen: false);
                        gameModel.playerNames.clear();
                        gameModel.playerNames.addAll(playerNames);
                        gameModel.initializeGame(); // Re-initialize the game

                        setState(() {
                          _errorText = '';
                        });
                      } else {
                        setState(() {
                          _errorText = 'Enter valid player names.';
                        });
                      }
                    } else {
                      setState(() {
                        _errorText = 'Enter player names.';
                      });
                    }
                  },
                  child: const Text('Start Game'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
