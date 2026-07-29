import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/action_history.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';

void main() {
  test('metadata and snapshots enforce independent retention limits', () {
    final history = ActionHistory(maxEntries: 3, maxSnapshots: 2);
    history.reset(GameSaveState());

    for (var index = 0; index < 4; index++) {
      history.append(
        index: index,
        description: 'Action $index',
        command: _TestCommand(),
      );
      history.attachSnapshot(index, GameSaveState());
    }

    expect(history.entries.map((entry) => entry.index), [1, 2, 3]);
    expect(history.retainedSnapshotCount, 2);
    expect(history.snapshotAt(1), isNull);
    expect(history.commandAt(1), isNull);
    expect(history.commandAt(2), isNotNull);
    expect(history.snapshotAt(2), isNotNull);
    expect(history.snapshotAt(3), isNotNull);
  });

  test('new action after rollback replaces the abandoned branch', () {
    final history = ActionHistory();
    history.append(index: 0, description: 'A');
    history.append(index: 1, description: 'B');
    history.append(index: 2, description: 'C');

    history.append(index: 1, description: 'D');

    expect(history.entries.map((entry) => entry.description), ['A', 'D']);
    expect(history.lastIndex, 1);
  });

  test('remote synchronization can start at an absolute session index', () {
    final history = ActionHistory();

    history.synchronizeDescription(42, 'Remote action');
    history.attachSnapshot(42, GameSaveState());

    expect(history.descriptionAt(42), 'Remote action');
    expect(history.snapshotAt(42), isNotNull);
  });
}

class _TestCommand extends Command {
  @override
  String describe() => 'test';

  @override
  void execute() {}
}
