import 'package:colorize_text_avatar/colorize_text_avatar.dart';
import 'package:flutter/material.dart';

class Player extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final int score;

  const Player(
      {super.key,
      required this.name,
      required this.avatarUrl,
      required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.green.shade800.withAlpha(100),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: <Widget>[
          TextAvatar(
            text: name,
            numberLetters: 2,
            shape: Shape.Circular,
          ),
          const SizedBox(width: 10.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                'Score: $score',
                style: TextStyle(color: Colors.green.shade200),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
