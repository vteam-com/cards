import 'package:cards/game_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PlayerSetupScreen(),
    );
  }
}

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
        title: const Text('Enter Player Names'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter names separated by space, comma, or semicolon',
                errorText: _errorText.isEmpty ? null : _errorText,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _startGame(context);
              },
              child: const Text('Start Game'),
            ),
          ],
        ),
      ),
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
