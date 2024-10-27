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
      body: Consumer<GameModel>(
        builder: (context, gameModel, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/background.png',
                  fit: BoxFit.cover,
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Center(child: buildPlayers(gameModel)),
                    const SizedBox(height: 20),
                    _buildInstructionText(gameModel.activePlayerName),
                    const SizedBox(height: 20),
                    _buildDeckOfCards(context, gameModel),
                    const SizedBox(height: 10),
                    _buildCompleteTurnButton(context),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildPlayers(GameModel gameModel) {
    return Wrap(
      spacing: 40.0,
      runSpacing: 40.0,
      children: List.generate(gameModel.numPlayers, (index) {
        return buildPlayerCard(gameModel, index);
      }),
    );
  }

  Widget buildPlayerCard(GameModel gameModel, int index) {
    final playerName = gameModel.playerNames[index];
    final playerScore = gameModel.calculatePlayerScore(index);
    final isActivePlayer = gameModel.activePlayerIndex == index;
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade800.withAlpha(100),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isActivePlayer ? Colors.yellow : Colors.transparent,
          width: isActivePlayer ? 4.0 : 12.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Player(name: playerName, score: playerScore),
          const SizedBox(height: 20),
          _buildPlayerHand(gameModel, index),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlayerHand(GameModel gameModel, int index) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemCount: gameModel.playerHands[index].length,
      itemBuilder: (context, gridIndex) {
        return _buildCardTile(gameModel, index, gridIndex);
      },
    );
  }

  Widget _buildCardTile(GameModel gameModel, int playerIndex, int gridIndex) {
    final isVisible = gameModel.cardVisibility[playerIndex][gridIndex];
    final card = gameModel.playerHands[playerIndex][gridIndex];

    return GestureDetector(
      onTap: () {
        gameModel.toggleCardVisibility(playerIndex, gridIndex);
        gameModel.saveGameState();
      },
      child:
          isVisible ? PlayingCardWidget(card: card) : const HiddenCardWidget(),
    );
  }

  Widget _buildDeckOfCards(BuildContext context, GameModel gameModel) {
    return DeckOfCards(
      cardsInTheDeck: context.watch<GameModel>().cardsInTheDeck.length,
      discardedCards: context.watch<GameModel>().discardedCards,
      onDrawCard: () {
        final gameModel = context.read<GameModel>();
        gameModel.drawCard();
        gameModel.nextPlayer(); // Move to the next player
      },
    );
  }

  Widget _buildCompleteTurnButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.read<GameModel>().nextPlayer(); // Complete current turn
      },
      child: const Text('Complete Turn'),
    );
  }

  Widget _buildInstructionText(String playersName) {
    final instructionText =
        'It\'s your turn $playersName! Choose to either pick the open deck card or tap on the top of the hidden deck.';

    final parts = instructionText.split(playersName);
    final beforeName = parts[0];
    final afterName = parts[1];

    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.black54),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 20, color: Colors.black),
          children: <TextSpan>[
            TextSpan(text: beforeName),
            TextSpan(
              text: playersName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            TextSpan(text: afterName),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
