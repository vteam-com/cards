import 'package:cards/playing_card.dart';
import 'package:flutter/material.dart';

class PlayingCardWidget extends StatelessWidget {
  final PlayingCard card;

  const PlayingCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      width: 60.0,
      height: 80.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2.0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: card.suit == 'Joker' ? _buildJoker() : _buildRegularCard(),
    );
  }

  Widget _buildRegularCard() {
    return Stack(
      children: [
        Positioned(
          top: 4,
          left: 4,
          child: Text(
            card.rank,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getSuitColor(card.suit),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Text(
            card.rank,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getSuitColor(card.suit),
            ),
          ),
        ),
        Center(
          child: Text(
            _getSuitSymbol(card.suit),
            style: TextStyle(
              fontSize: 15,
              color: _getSuitColor(card.suit),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoker() {
    return Center(
      child: Text(
        'Joker',
        style: TextStyle(
          fontSize: 24,
          color: card.rank == 'Black' ? Colors.black : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getSuitSymbol(String suit) {
    switch (suit) {
      case 'Hearts':
        return '♥️';
      case 'Diamonds':
        return '♦️';
      case 'Clubs':
        return '♣️';
      case 'Spades':
        return '♠️';
      default:
        return '';
    }
  }

  Color _getSuitColor(String suit) {
    switch (suit) {
      case 'Hearts':
      case 'Diamonds':
        return Colors.red;
      case 'Clubs':
      case 'Spades':
        return Colors.black;
      default:
        return Colors.black;
    }
  }
}

class HiddenCardWidget extends StatelessWidget {
  const HiddenCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      width: 60.0,
      height: 80.0,
      decoration: BoxDecoration(
        color: Colors.blueGrey[800],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2.0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.question_mark, color: Colors.white),
      ),
    );
  }
}
