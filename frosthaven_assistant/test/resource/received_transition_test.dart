// ignore_for_file: no-magic-number

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/game_event.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';

import '../command/test_helpers.dart';

void main() {
  late String baseline;

  setUpAll(() async {
    await setUpGame();
    baseline = gameState.toString();
  });

  setUp(() {
    expect(gameState.loadFromData(baseline), isTrue);
    gameState.commandIndex.value = -1;
    gameState.resetCommandHistory();
    gameState.save();
  });

  test(
    'successive received steps attach their exact snapshots immediately',
    () {
      final first = _withLevel(baseline, 2);
      final second = _withLevel(baseline, 3);

      expect(
        gameState.applyReceivedTransition(
          state: first,
          index: 0,
          description: 'first',
          event: const NoEvent(),
          kind: ReceivedTransitionKind.newStep,
        ),
        isTrue,
      );
      expect(gameState.snapshotAt(0)?.getState(), first);

      expect(
        gameState.applyReceivedTransition(
          state: second,
          index: 1,
          description: 'second',
          event: const NoEvent(),
          kind: ReceivedTransitionKind.newStep,
        ),
        isTrue,
      );

      expect(gameState.commandIndex.value, 1);
      expect(gameState.snapshotAt(0)?.getState(), first);
      expect(gameState.snapshotAt(1)?.getState(), second);
      expect(gameState.descriptionAt(0), 'first');
      expect(gameState.descriptionAt(1), 'second');
    },
  );

  test(
    'late invalid data preserves state, history, index, and figure identity',
    () {
      gameState.action(
        AddMonsterCommand('Zealot', 4, false, gameState: gameState),
      );
      gameState.action(
        AddStandeeCommand(
          1,
          null,
          'Zealot',
          MonsterType.normal,
          false,
          gameState: gameState,
        ),
      );
      final monster = gameState.currentList.single as Monster;
      final figure = monster.monsterInstances.single;
      final stateBefore = gameState.toString();
      final indexBefore = gameState.commandIndex.value;
      final revisionBefore = gameState.transitionRevision.value;
      final entriesBefore = gameState.historyEntries;
      final invalid = jsonDecode(stateBefore) as Map<String, dynamic>;
      invalid['currentList'] = <Object?>[];
      invalid['elementState'] = 'not a map';

      expect(
        gameState.applyReceivedTransition(
          state: jsonEncode(invalid),
          index: indexBefore + 1,
          description: 'invalid',
          event: const NoEvent(),
          kind: ReceivedTransitionKind.newStep,
        ),
        isFalse,
      );

      expect(gameState.toString(), stateBefore);
      expect(gameState.currentList.single, same(monster));
      expect(
        (gameState.currentList.single as Monster).monsterInstances.single,
        same(figure),
      );
      expect(gameState.commandIndex.value, indexBefore);
      expect(gameState.transitionRevision.value, revisionBefore);
      expect(gameState.historyEntries, orderedEquals(entriesBefore));
    },
  );

  test('rejects an out-of-range negative index without applying state', () {
    final stateBefore = gameState.toString();
    final revisionBefore = gameState.transitionRevision.value;

    expect(
      gameState.applyReceivedTransition(
        state: _withLevel(baseline, 7),
        index: -2,
        description: 'invalid index',
        event: const NoEvent(),
        kind: ReceivedTransitionKind.authoritativeCorrection,
      ),
      isFalse,
    );

    expect(gameState.toString(), stateBefore);
    expect(gameState.commandIndex.value, -1);
    expect(gameState.transitionRevision.value, revisionBefore);
  });

  test(
    'authoritative correction replaces the current snapshot and publishes',
    () {
      final initial = _withLevel(baseline, 2);
      final corrected = _withLevel(baseline, 4);
      expect(
        gameState.applyReceivedTransition(
          state: initial,
          index: 0,
          description: 'initial',
          event: const NoEvent(),
          kind: ReceivedTransitionKind.newStep,
        ),
        isTrue,
      );
      final revision = gameState.transitionRevision.value;

      expect(
        gameState.applyReceivedTransition(
          state: corrected,
          index: 0,
          description: 'corrected',
          event: const NoEvent(),
          kind: ReceivedTransitionKind.authoritativeCorrection,
        ),
        isTrue,
      );

      expect(gameState.level.value, 4);
      expect(gameState.snapshotAt(0)?.getState(), corrected);
      expect(gameState.descriptionAt(0), 'corrected');
      expect(gameState.transitionRevision.value, revision + 1);
    },
  );
}

String _withLevel(String source, int level) {
  final data = jsonDecode(source) as Map<String, dynamic>;
  data['level'] = level;
  return jsonEncode(data);
}
