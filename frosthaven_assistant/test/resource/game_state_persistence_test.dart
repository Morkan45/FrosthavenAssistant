import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/network/communication.dart';
import 'package:frosthaven_assistant/services/network/connection.dart';

void main() {
  test('rapid saves persist the newest captured game state', () async {
    final releaseFirstWrite = Completer<void>();
    final persistedLevels = <int>[];
    var activeWrites = 0;
    var maxActiveWrites = 0;

    final gameState = GameState(
      communication: Communication(connection: Connection()),
      settings: Settings(),
      stateWriter: (state) async {
        activeWrites++;
        maxActiveWrites = activeWrites > maxActiveWrites
            ? activeWrites
            : maxActiveWrites;
        persistedLevels.add(
          (jsonDecode(state) as Map<String, dynamic>)['level'] as int,
        );
        if (persistedLevels.length == 1) {
          await releaseFirstWrite.future;
        }
        activeWrites--;
      },
    )..init();

    gameState.save();
    _setLevel(gameState, 2);
    gameState.save();
    _setLevel(gameState, 3);
    gameState.save();

    expect(persistedLevels, [1]);
    releaseFirstWrite.complete();
    await gameState.flushPersistence();

    expect(persistedLevels, [1, 3]);
    expect(maxActiveWrites, 1);
  });
}

void _setLevel(GameState gameState, int level) {
  final data = jsonDecode(gameState.toString()) as Map<String, dynamic>;
  data['level'] = level;
  expect(gameState.loadFromData(jsonEncode(data)), isTrue);
}
