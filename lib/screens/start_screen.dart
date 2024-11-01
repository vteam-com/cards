import 'dart:async';

import 'package:cards/models/backend_model.dart';
import 'package:cards/models/game_model.dart';
import 'package:cards/screens/game_screen.dart';
import 'package:cards/screens/screen.dart';
import 'package:cards/widgets/players_in_room_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  StartScreenState createState() => StartScreenState();
}

class StartScreenState extends State<StartScreen> {
  late StreamSubscription _streamSubscription;

  final TextEditingController _controllerRoom = TextEditingController(
    text: 'Banana', // Default player names
  );
  final String _errorTextRoom = '';

  final TextEditingController _controllerName = TextEditingController(
    text: '', // Default player names
  );
  final String _errorTextName = '';

  List<String> _playerNames = [];
  String get playerName => _controllerName.text.trim();

  @override
  void initState() {
    super.initState();

    useFirebase().then((_) {
      _streamSubscription =
          FirebaseDatabase.instance.ref().onValue.listen((event) {
        final DataSnapshot snapshot = event.snapshot;
        final Object? data = snapshot.value;
        if (data != null) {
          if (data is Map<Object?, Object?>) {
            final room = data['rooms'] as Map<Object?, Object?>;
            final room1 = room['room1'] as Map<Object?, Object?>;
            final players = room1['players'] as List<Object?>;

            setState(() {
              _playerNames = [];
              for (final Object? playerName in players) {
                if (playerName != null) {
                  var name = playerName as String;
                  _playerNames.add(name);
                }
              }
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Screen(
      backButton: false,
      title: '9 Cards Golf',
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: 600,
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const SizedBox(
                    height: 200,
                    child: Markdown(
                      selectable: true,
                      data:
                          '## Players swap cards in their grid to score as low as possible.'
                          '\n- Lining up three of the same rank in a row or column counts as zero.'
                          '\n- Anyone can end a round by “closing,” but if someone scores lower, the closer’s points are doubled!'
                          '\n'
                          '\n'
                          'Learn more [Wikipedia](https://en.wikipedia.org/wiki/Golf_(card_game))',
                    ),
                  ),
                  const SizedBox(height: 40),

                  //
                  // Input Room name
                  //

                  editBox('Room', _controllerRoom, _errorTextRoom),

                  const SizedBox(height: 20),

                  //
                  // Input your name
                  //
                  editBox('Name', _controllerName, _errorTextName),

                  const SizedBox(height: 40),

                  //
                  // Join Game | Start Game
                  //
                  actionButton(),

                  const SizedBox(height: 40),

                  //
                  // List of joined players
                  //
                  SizedBox(
                    width: 400,
                    height: 300,
                    child: PlayersInRoomWidget(
                      name: playerName,
                      playerNames: _playerNames,
                      onRemovePlayer: (String nameToRemove) {
                        removePlayer(nameToRemove);
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget editBox(
    final String label,
    final TextEditingController controller,
    final String errorStatus,
  ) {
    return Container(
      width: 400,
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color.fromARGB(255, 19, 67, 22),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          Expanded(
            child: Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Type your $label here',
                  hintStyle: TextStyle(color: Colors.black.withAlpha(100)),
                  errorText: errorStatus.isEmpty ? null : errorStatus,
                ),
                onSubmitted: (String _) => setState(() {
                  // update UI
                }),
                onChanged: (String _) => setState(() {
                  // update UI
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void joinGame(BuildContext context) {
    String nameOfPersonJoining = _controllerName.text.trim();

    _playerNames.add(nameOfPersonJoining);
    pushPlayersNamesToFirebase();
  }

  void pushPlayersNamesToFirebase() {
    useFirebase().then((_) {
      final refPlayers =
          FirebaseDatabase.instance.ref().child('rooms/room1/players');
      refPlayers.set(_playerNames);
    });
  }

  void removePlayer(final String nameToRemove) {
    _playerNames = _playerNames.where((name) => name != nameToRemove).toList();
    pushPlayersNamesToFirebase();
  }

  void startGame(BuildContext context, bool joinExistingGame) {
    final newGame = GameModel(
      names: _playerNames,
      gameRoomId: _controllerRoom.text.trim(),
      newGame: true,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(gameModel: newGame),
      ),
    );
  }

  List<String> parsePlayerNames(String input) {
    if (input.isEmpty) {
      return [];
    }

    // Split by spaces, commas, or semicolons and remove empty entries
    List<String> names = input
        .split(RegExp(r'[ ,;]+'))
        .where((name) => name.isNotEmpty)
        .toList();

    return names;
  }

  Widget actionButton() {
    if (playerName.isEmpty) {
      return const Text('Please enter your name above ⬆');
    }
    bool isPartOfTheList = _playerNames.contains(playerName);

    String label = isPartOfTheList == false
        ? 'Join Game'
        : _playerNames.length > 1
            ? 'Start Game'
            : 'Waiting for players';

    return ElevatedButton(
      onPressed: () {
        if (isPartOfTheList) {
          if (_playerNames.length > 1) {
            startGame(
              context,
              true,
            );
          }
        } else {
          joinGame(context);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
