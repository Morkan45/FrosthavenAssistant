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
}
