import 'dart:convert';

import 'package:frosthaven_assistant_server/server_state.dart';
import 'package:test/test.dart';

void main() {
  test('undo uses baseline slot zero and can undo the first command', () {
    final state = ServerState();
    state.gameSaveStates.first.loadFromData('base', state);
    state.acceptUpdate(0, 'A', 'state-a');

    final message = jsonDecode(state.undoState()) as Map<String, dynamic>;

    expect(message['i'], -1);
    expect(message['d'], '');
    expect(message['s'], 'base');
    expect(state.commandIndex, -1);
  });

  test('new update after undo truncates the abandoned redo branch', () {
    final state = ServerState();
    state.gameSaveStates.first.loadFromData('base', state);
    state.acceptUpdate(0, 'A', 'state-a');
    state.acceptUpdate(1, 'B', 'state-b');
    state.acceptUpdate(2, 'C', 'state-c');
    state.undoState();
    state.undoState();

    state.acceptUpdate(1, 'D', 'state-d');

    expect(state.commandDescriptions, ['A', 'D']);
    expect(state.gameSaveStates.map((item) => item.getState()), [
      'base',
      'state-a',
      'state-d',
    ]);
    expect(state.redoState(), isEmpty);
  });

  test('rollback restores the target in one operation and preserves redo', () {
    final state = ServerState();
    state.gameSaveStates.first.loadFromData('base', state);
    state.acceptUpdate(0, 'A', 'state-a');
    state.acceptUpdate(1, 'B', 'state-b');
    state.acceptUpdate(2, 'C', 'state-c');

    final message = jsonDecode(state.rollbackState(0)) as Map<String, dynamic>;

    expect(message['i'], 0);
    expect(message['d'], 'A');
    expect(message['s'], 'state-a');
    expect(state.commandIndex, 0);
    expect(jsonDecode(state.redoState())['s'], 'state-b');
  });

  test('entry retention preserves absolute indices and a baseline snapshot',
      () {
    final state = ServerState(maxHistoryEntries: 2);
    state.gameSaveStates.first.loadFromData('base', state);
    state.acceptUpdate(0, 'A', 'state-a');
    state.acceptUpdate(1, 'B', 'state-b');
    state.acceptUpdate(2, 'C', 'state-c');

    expect(state.firstRetainedIndex, 1);
    expect(state.oldestRetainedStateIndex, 0);
    expect(state.commandIndex, 2);
    expect(state.commandDescriptions, ['B', 'C']);
    expect(state.gameSaveStates.map((item) => item.getState()), [
      'state-a',
      'state-b',
      'state-c',
    ]);

    expect((jsonDecode(state.undoState()) as Map)['i'], 1);
    final baseline = jsonDecode(state.undoState()) as Map<String, dynamic>;
    expect(baseline['i'], 0);
    expect(baseline['d'], '');
    expect(baseline['s'], 'state-a');
    expect(state.undoState(), isEmpty);
    expect((jsonDecode(state.redoState()) as Map)['i'], 1);
  });

  test('byte retention evicts oldest history within the configured budget', () {
    final state = ServerState(maxHistoryEntries: 10, maxHistoryBytes: 14);
    state.acceptUpdate(0, 'A', 'aaaa');
    state.acceptUpdate(1, 'B', 'bbbb');
    state.acceptUpdate(2, 'C', 'cccc');

    expect(state.firstRetainedIndex, 1);
    expect(state.retainedHistoryBytes, lessThanOrEqualTo(14));
    expect(state.currentState, 'cccc');
  });

  test('rollback older than retained baseline returns current correction', () {
    final state = ServerState(maxHistoryEntries: 2);
    state.acceptUpdate(0, 'A', 'state-a');
    state.acceptUpdate(1, 'B', 'state-b');
    state.acceptUpdate(2, 'C', 'state-c');

    final correction =
        jsonDecode(state.rollbackState(-1)) as Map<String, dynamic>;

    expect(correction['i'], 2);
    expect(correction['d'], 'C');
    expect(correction['s'], 'state-c');
    expect(state.commandIndex, 2);
  });

  test('new branch after eviction truncates retained redo using absolute index',
      () {
    final state = ServerState(maxHistoryEntries: 2);
    state.acceptUpdate(0, 'A', 'state-a');
    state.acceptUpdate(1, 'B', 'state-b');
    state.acceptUpdate(2, 'C', 'state-c');
    state.undoState();
    state.undoState();

    state.acceptUpdate(1, 'D', 'state-d');

    expect(state.firstRetainedIndex, 1);
    expect(state.commandIndex, 1);
    expect(state.commandDescriptions, ['D']);
    expect(state.gameSaveStates.map((item) => item.getState()), [
      'state-a',
      'state-d',
    ]);
    expect(state.redoState(), isEmpty);
  });

  test('reset removes retained snapshots from the prior game', () {
    final state = ServerState()..acceptUpdate(0, 'A', 'secret-state');

    state.resetState();

    expect(state.commandIndex, -1);
    expect(state.currentState, isEmpty);
    expect(state.commandDescriptions, isEmpty);
  });
}
