import 'package:cards/models/card_model.dart';
import 'package:cards/widgets/cards/card_widget.dart';
import 'package:flutter/material.dart';

class CardPileWidget extends StatelessWidget {
  const CardPileWidget({
    super.key,
    required this.cards,
    this.onDraw,
    required this.cardsAreHidden,
    required this.wiggleTopCard,
    required this.revealTopDeckCard,
    required this.isDragSource,
    required this.isDropTarget,
    required this.onDragDropped,
  });

  final List<CardModel> cards;
  final VoidCallback? onDraw;
  final bool cardsAreHidden;
  final bool revealTopDeckCard;
  final bool isDragSource;
  final bool isDropTarget;
  final bool wiggleTopCard;
  final Function(CardModel source, CardModel target) onDragDropped;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: _buildPileUnplayedCards(), // Build the discard pile
    );
  }

  Widget _buildPileUnplayedCards() {
    double cardStackOffset = 0.5;
    if (cards.length > 50) {
      cardStackOffset = 0.2;
    }
    return Tooltip(
      message: '${cards.length}\ncards',
      child: SizedBox(
        width: 140.0,
        child: GestureDetector(
          onTap: onDraw,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(cards.length, (index) {
              double offset = index.toDouble() *
                  cardStackOffset; // Offset for stacking effect
              bool isTopCard = index == cards.length - 1;
              final CardModel card = cards[index];
              card.isSelectable = isTopCard && wiggleTopCard;
              card.isRevealed = revealTopDeckCard && isTopCard;
              return Positioned(
                left: offset,
                top: offset,
                child: isDragSource
                    ? dragSource(card)
                    : CardWidget(
                        card: card,
                        onDropped: onDragDropped,
                      ),
              );
            }),
          ),
        ),
      ),
    );
  }
}