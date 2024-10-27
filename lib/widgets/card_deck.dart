import 'package:cards/playing_card.dart';
import 'package:cards/playing_card_widget.dart';
import 'package:flutter/material.dart';

class DeckOfCards extends StatelessWidget {
  final int cardsRemaining; // Ensure this parameter is defined
  final PlayingCard? topOpenCard;
  final VoidCallback onDrawCard;
  const DeckOfCards({
    super.key,
    required this.cardsRemaining, // Ensure correct parameter usage
    this.topOpenCard,
    required this.onDrawCard,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onDrawCard,
          child: Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6.0,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.deck, size: 50, color: Colors.white),
                Text(
                  '$cardsRemaining cards', // Proper display of remaining cards
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20), // Space between deck and open cards
        if (topOpenCard != null)
          PlayingCardWidget(card: topOpenCard!), // Use the card widget
      ],
    );
  }
}
