import 'dart:async';

import 'package:cards/firebase_options_private.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

bool backendReady = false;

Future<void> useFirebase() async {
  try {
    if (backendReady == false) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseAuth.instance.signInAnonymously();
      backendReady = true;
    }
  } catch (e) {
    backendReady = false;
    print('---------------------');
    print(e);
    print('---------------------');
  }
}

Future<List<String>> getPlayersInRoom(final String roomId) async {
  final DataSnapshot dataSnapshot = await FirebaseDatabase.instance
      .ref()
      .child('rooms/$roomId/invitees')
      .get();

  final List? players = dataSnapshot.value as List?;

  if (players == null) {
    return [];
  } else {
    return players.cast<String>().toList();
  }
}

void setPlayersInRoom(final String room, final Set<String> playersNames) {
  useFirebase().then((_) {
    FirebaseDatabase.instance
        .ref()
        .child('rooms/$room/invitees')
        .set(playersNames.toList());
  });
}

StreamSubscription onBackendInviteesUpdated(
  final String roomId,
  void Function(List<String>) onInviteesNamesChanged,
) {
  return FirebaseDatabase.instance
      .ref()
      .onValue
      .listen((final DatabaseEvent event) {
    getInviteesFromDataSnapshot(event.snapshot, roomId);
    onInviteesNamesChanged(getInviteesFromDataSnapshot(event.snapshot, roomId));
  });
}

List<String> getInviteesFromDataSnapshot(
  final DataSnapshot snapshot,
  final String roomId,
) {
  List<String> playersNames = [];
  if (snapshot.exists) {
    final Object? data = snapshot.value;

    // Safely access and update the player list from the Firebase snapshot.
    if (data != null && data is Map) {
      final rooms = data['rooms'] as Map?;
      if (rooms != null) {
        final room = rooms[roomId] as Map?;
        if (room != null) {
          final players = room['invitees'] as List?;
          if (players != null) {
            playersNames = players.cast<String>().toList();
          }
        }
      }
    }
  }
  return playersNames;
}

Future<List<String>> getAllRooms() async {
  final DataSnapshot dataSnapshot =
      await FirebaseDatabase.instance.ref('rooms').get();
  final List<String> rooms = [];

  if (dataSnapshot.exists && dataSnapshot.value is Map) {
    final Map<dynamic, dynamic> data =
        dataSnapshot.value as Map<dynamic, dynamic>;
    data.forEach((key, value) {
      rooms.add(key.toString());
    });
  }

  return rooms;
}
