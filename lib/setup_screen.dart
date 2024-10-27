import 'package:cards/game_model.dart';
import 'package:cards/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlayerSetupScreen extends StatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  PlayerSetupScreenState createState() => PlayerSetupScreenState();
}

class PlayerSetupScreenState extends State<PlayerSetupScreen> {
  final TextEditingController _controller = TextEditingController(
    text: 'John, Paul, George, Ringo', // Default player names
  );
  String _errorText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('9 Cards Golf'),
      ),
      // Set the background color to a green color
      backgroundColor:
          const Color.fromARGB(255, 4, 69, 4), // Choose a color for felt
      body: Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover, // Ensures the image covers the whole area
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Enter players names separated by space, comma, or semicolon',
                style: TextStyle(color: Colors.green.shade100, fontSize: 24),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: Colors.green.shade900, fontSize: 24),
                  decoration: InputDecoration(
                    hintText: 'Names',
                    errorText: _errorText.isEmpty ? null : _errorText,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Material(
                elevation: 125,
                shadowColor: Colors.black,
                borderRadius: BorderRadius.circular(20),
                child: TextButton(
                  onPressed: () {
                    _startGame(context);
                  },
                  child: Text(
                    'Start Game',
                    style:
                        TextStyle(color: Colors.green.shade900, fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  void _startGame(BuildContext context) {
    String input = _controller.text.trim();
    List<String> playerNames = _parsePlayerNames(input);

    if (playerNames.length > 4) {
      setState(() {
        _errorText = 'Maximum 4 players allowed.';
      });
    } else if (playerNames.isEmpty) {
      setState(() {
        _errorText = 'Please enter at least one player name.';
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => GameModel(playerNames: playerNames),
            child: const GameScreen(),
          ),
        ),
      );
    }
  }

  List<String> _parsePlayerNames(String input) {
    if (input.isEmpty) return [];

    // Split by spaces, commas, or semicolons and remove empty entries
    List<String> names = input
        .split(RegExp(r'[ ,;]+'))
        .where((name) => name.isNotEmpty)
        .toList();

    return names;
  }
}
