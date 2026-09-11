// ignore_for_file: no-magic-number

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/imbue_element_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_level_command.dart';
import 'package:frosthaven_assistant/Resource/commands/use_element_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';
import '../unit_helpers.dart';

class _MutatingThrowCommand extends Command {
  _MutatingThrowCommand(this.gameState);

  final GameState gameState;

  @override
  void execute() {
    SetLevelCommand(7, null).execute();
    throw StateError('intentional transition failure');
  }

  @override
  String describe() => 'fails';
}

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  setUp(() {
    final gs = getIt<GameState>();
    gs.clearList();
    gs.resetCommandHistory();
    gs.save();
  });

  group('ActionHandler', () {
    test('failed command restores state without adding history', () {
      final gs = getIt<GameState>();
      gs.action(AddMonsterCommand('Zealot', 1, false, gameState: gs));
      final stateBefore = gs.toString();
      final indexBefore = gs.commandIndex.value;

      gs.action(_MutatingThrowCommand(gs));

      expect(gs.toString(), stateBefore);
      expect(gs.commandIndex.value, indexBefore);
    });

    group('getCurrent', () {
      test('getCurrent returns the last executed command', () {
        final gs = getIt<GameState>();
        final cmd = SetLevelCommand(3, null);
        gs.action(cmd);
        expect(gs.getCurrent(), same(cmd));
        gs.undo();
      });
    });

    group('redo', () {
      test('redo restores state after undo', () {
        final gs = getIt<GameState>();
        // Two actions so gameSaveStates has enough entries for redo
        gs.action(SetLevelCommand(2, null));
        gs.action(SetLevelCommand(5, null));
        expect(gs.level.value, 5);
        gs.undo(); // back to level 2
        expect(gs.level.value, 2);
        gs.redo(); // forward to level 5
        expect(gs.level.value, 5);
        gs.undo();
        gs.undo();
      });

      test('redo is a no-op when there is nothing to redo', () {
        final gs = getIt<GameState>();
        gs.action(SetLevelCommand(4, null));
        // No undo performed, so redo should not crash and not change state
        final levelBefore = gs.level.value;
        gs.redo();
        expect(gs.level.value, levelBefore);
        gs.undo();
      });

      test('redo increments commandIndex', () {
        final gs = getIt<GameState>();
        gs.action(SetLevelCommand(2, null));
        gs.action(SetLevelCommand(3, null));
        final indexAfterActions = gs.commandIndex.value;
        gs.undo();
        expect(gs.commandIndex.value, indexAfterActions - 1);
        gs.redo();
        expect(gs.commandIndex.value, indexAfterActions);
        gs.undo();
        gs.undo();
      });
    });

    group('redo list cleanup', () {
      test('new action after undo clears the redo list', () {
        final gs = getIt<GameState>();
        gs.action(SetLevelCommand(3, null));
        gs.action(SetLevelCommand(4, null));
        //final indexBefore = gs.commandIndex.value;
        gs.undo(); // undo SetLevel(4), now commandIndex = indexBefore - 1
        // Do a new action — should clear SetLevel(4) from the redo list
        gs.action(SetLevelCommand(5, null));
        expect(gs.historyEntries.last.index, gs.commandIndex.value);
        expect(gs.historyEntries.length, 2);
        // Undo back to baseline
        gs.undo();
        gs.undo();
      });

      test('accepted network action after undo replaces the redo branch', () {
        final gs = getIt<GameState>();
        gs.action(SetLevelCommand(2, null));
        gs.action(SetLevelCommand(3, null));
        gs.action(SetLevelCommand(4, null));
        gs.undo();
        gs.undo();

        gs.insertReceivedDescription(1, 'Set level 6 remotely');
        final remoteState = jsonDecode(gs.toString()) as Map<String, dynamic>
          ..['level'] = 6;
        expect(gs.loadFromData(jsonEncode(remoteState)), isTrue);
        gs.commandIndex.value = 1;
        gs.save();

        expect(gs.historyEntries.length, 2);
        expect(gs.historyEntries.last.description, 'Set level 6 remotely');
        expect(gs.snapshotAt(1), isNotNull);
        gs.undo();
        expect(gs.level.value, 2);
        gs.redo();
        expect(gs.level.value, 6);
        gs.redo();
        expect(gs.level.value, 6);
        gs.undo();
        gs.undo();
      });
    });

    group('maxUndo eviction', () {
      test('old metadata remains after its heavier snapshot is evicted', () {
        final gs = getIt<GameState>();
        final maxUndo = gs.maxUndo;
        final startIndex = gs.commandIndex.value;

        for (int i = 0; i <= maxUndo + 1; i++) {
          gs.action(SetLevelCommand((i % 7) + 1, null));
        }
        final oldestActionIndex = startIndex + 1;
        expect(gs.commandAt(oldestActionIndex), isNull);
        expect(gs.descriptionAt(oldestActionIndex), isNotEmpty);
        expect(gs.snapshotAt(oldestActionIndex), isNull);
        expect(gs.retainedSnapshotCount, lessThanOrEqualTo(maxUndo + 1));

        // Undo back to near the start (only valid undo states)
        for (int i = 0; i < maxUndo; i++) {
          gs.undo();
        }
      });
    });

    group('getCurrent edge cases', () {
      test(
        'getCurrent throws when there is no valid command at current index',
        () {
          final gs = getIt<GameState>();
          // Reset so commandIndex is -1 (no commands executed yet).
          gs.commandIndex.value = -1;
          gs.resetCommandHistory();
          // getCurrent accesses _commands[commandIndex] — either a RangeError
          // (negative index) or TypeError (null-check on a null entry). Either
          // way it must throw an Error so callers know to guard the call site.
          expect(() => gs.getCurrent(), throwsA(isA<Error>()));
        },
      );
    });

    group('redo after maxUndo eviction', () {
      test('redo from the oldest valid position does not crash', () {
        final gs = getIt<GameState>();
        final maxUndo = gs.maxUndo;

        // Execute maxUndo + 1 commands so the oldest save state is evicted.
        for (int i = 0; i <= maxUndo; i++) {
          gs.action(SetLevelCommand((i % 7) + 1, null));
        }

        // Undo all the way to the eviction boundary:
        // only the last maxUndo states are guaranteed non-null.
        for (int i = 0; i < maxUndo; i++) {
          gs.undo();
        }
        // commandIndex is now at the boundary; gameSaveStates[commandIndex + 1]
        // may be null (evicted). redo() must return early without crashing.
        expect(() => gs.redo(), returnsNormally);

        // Restore state for other tests.
        gs.undo();
      });
    });

    group('add monster then undo', () {
      test('undo after adding a monster removes it from the list', () {
        final gs = getIt<GameState>();
        gs.clearList();
        gs.action(
          AddMonsterCommand('Zealot', 1, false, gameState: getIt<GameState>()),
        );
        expect(gs.currentList.any((e) => e.id == 'Zealot'), isTrue);
        gs.undo();
        expect(gs.currentList.any((e) => e.id == 'Zealot'), isFalse);
      });
    });

    group('undo with commandIndex beyond retained history', () {
      // Regression test for:
      // ArgumentError: RangeError (length): Invalid value: Not in inclusive range 0..1079: 1080
      // ActionHandler.undo — crash when commandIndex >= gameSaveStates.length.
      //
      // Cause: in the server multiplayer path, Server.updateStateFromMessage sets
      // commandIndex.value = message.index directly, then calls save().  After a
      // resetState() (history cleared) a client that was ahead can send a message
      // whose index ends up beyond the current gameSaveStates length after save().
      // A subsequent "undo" message from any client then crashes at
      // _gameSaveStates[commandIndex.value] with no upper-bound guard.
      test('does not crash or move the index when no snapshot exists', () {
        final gs = getIt<GameState>();
        final settings = getIt<Settings>();

        // Build a small amount of history.
        gs.action(SetLevelCommand(3, null));
        gs.action(SetLevelCommand(4, null));

        // Advance commandIndex past the end of gameSaveStates, simulating the
        // server receiving a state message whose index was not matched by a save().
        gs.commandIndex.value = gs.historyEntries.last.index + 2;
        final invalidIndex = gs.commandIndex.value;

        // A client sends "undo" — the server calls undoState() → undo().
        // This must not throw a RangeError.
        settings.server.value = true;
        expect(() => gs.undo(), returnsNormally);
        expect(gs.commandIndex.value, invalidIndex);
        settings.server.value = false;

        // Restore a clean state for subsequent tests.
        gs.commandIndex.value = -1;
        gs.resetCommandHistory();
      });
    });

    group('redo after connection reset in server mode', () {
      // Regression test for: ArgumentError: RangeError (length): Invalid value:
      // Valid value range is empty: -1 in ActionHandler.redo when a stale client
      // sends "redo" after the server resets its command history on reconnect.
      test('does not crash when commandIndex is -1 after connection reset', () {
        final gs = getIt<GameState>();
        final settings = getIt<Settings>();

        // Build some history so gameSaveStates has an entry to retain.
        gs.action(SetLevelCommand(3, null));

        // Simulate the server-side connection-reset sequence:
        // commandIndex → -1, command/description lists cleared, last save state kept.
        gs.commandIndex.value = -1;
        gs.resetCommandHistory();

        // Stale client sends "redo" before it has re-synced with the server.
        settings.server.value = true;
        expect(() => gs.redo(), returnsNormally);
        settings.server.value = false;
      });
    });

    group('direct rollback', () {
      test('restores one target state and preserves the redo branch', () {
        final gs = getIt<GameState>();
        gs.action(SetLevelCommand(2, null));
        gs.action(SetLevelCommand(3, null));
        gs.action(SetLevelCommand(4, null));

        expect(gs.rollbackToHistoryIndex(0), isTrue);
        expect(gs.commandIndex.value, 0);
        expect(gs.level.value, 2);
        expect(gs.canRedo, isTrue);

        gs.redo();
        expect(gs.commandIndex.value, 1);
        expect(gs.level.value, 3);
      });
    });

    group('element restoration', () {
      test(
        'rollback restores element values and notifies existing listeners',
        () {
          final (gameState, _) = makeGameAndSettings();
          gameState.save();

          gameState.action(
            ImbueElementCommand(Elements.fire, false, gameState: gameState),
          );
          final fireIndex = gameState.commandIndex.value;
          gameState.action(
            ImbueElementCommand(Elements.ice, true, gameState: gameState),
          );
          gameState.action(
            UseElementCommand(Elements.fire, gameState: gameState),
          );

          final fireNotifier = gameState.elementStateFor(Elements.fire);
          final iceNotifier = gameState.elementStateFor(Elements.ice);
          var fireNotifications = 0;
          var iceNotifications = 0;
          fireNotifier.addListener(() => fireNotifications++);
          iceNotifier.addListener(() => iceNotifications++);

          expect(gameState.rollbackToHistoryIndex(fireIndex), isTrue);
          expect(gameState.elementState[Elements.fire], ElementState.full);
          expect(gameState.elementState[Elements.ice], ElementState.inert);
          expect(gameState.elementStateFor(Elements.fire), same(fireNotifier));
          expect(gameState.elementStateFor(Elements.ice), same(iceNotifier));
          expect(fireNotifications, 1);
          expect(iceNotifications, 1);
          expect(gameState.canRedo, isTrue);

          gameState.redo();
          expect(gameState.elementState[Elements.fire], ElementState.full);
          expect(gameState.elementState[Elements.ice], ElementState.half);
          expect(fireNotifications, 1);
          expect(iceNotifications, 2);

          gameState.redo();
          expect(gameState.elementState[Elements.fire], ElementState.inert);
          expect(gameState.elementState[Elements.ice], ElementState.half);
          expect(fireNotifications, 2);
          expect(iceNotifications, 2);
        },
      );
    });
  });
}
