import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/network/communication.dart';
import 'package:frosthaven_assistant/services/network/connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Direct platform substitution is required to exercise the legacy API's
// false-return contract; shared_preferences exposes no public failing fake.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

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

  test('saveAndFlush reports a writer failure', () async {
    final error = StateError('write failed');
    final gameState = _gameState(stateWriter: (_) async => throw error);

    await expectLater(gameState.saveAndFlush(), throwsA(same(error)));
    expect(gameState.persistenceStatus.value.error, same(error));
  });

  test(
    'settled background save failure remains visible without uncaught error',
    () async {
      final uncaught = <Object>[];
      late GameState gameState;

      await runZonedGuarded(() async {
        gameState = _gameState(
          stateWriter: (_) async => throw StateError('background failure'),
        );
        gameState.save();
        await Future<void>.delayed(Duration.zero);
        await expectLater(gameState.flushPersistence(), throwsStateError);
      }, (error, _) => uncaught.add(error));

      expect(uncaught, isEmpty);
      expect(gameState.persistenceStatus.value.hasError, isTrue);
    },
  );

  test('successful retry clears persistence failure status', () async {
    var fail = true;
    final gameState = _gameState(
      stateWriter: (_) async {
        if (fail) throw StateError('temporary failure');
      },
    );

    gameState.save();
    await expectLater(gameState.flushPersistence(), throwsStateError);
    expect(gameState.persistenceStatus.value.hasError, isTrue);

    fail = false;
    await gameState.retryPersistence();

    expect(gameState.persistenceStatus.value.writing, isFalse);
    expect(gameState.persistenceStatus.value.hasError, isFalse);
    await gameState.flushPersistence();
  });

  test(
    'default SharedPreferences writer reports a false setString result',
    () async {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = _FailingSetStore();
      final gameState = _gameState();

      try {
        await expectLater(gameState.saveAndFlush(), throwsStateError);
        expect(gameState.persistenceStatus.value.hasError, isTrue);
      } finally {
        SharedPreferences.setMockInitialValues({});
      }
    },
  );
}

GameState _gameState({Future<void> Function(String state)? stateWriter}) =>
    GameState(
      communication: Communication(connection: Connection()),
      settings: Settings(),
      stateWriter: stateWriter,
    )..init();

class _FailingSetStore extends InMemorySharedPreferencesStore {
  _FailingSetStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}

void _setLevel(GameState gameState, int level) {
  final data = jsonDecode(gameState.toString()) as Map<String, dynamic>;
  data['level'] = level;
  expect(gameState.loadFromData(jsonEncode(data)), isTrue);
}
