// Regression guard for the shimmer-override fix (see line_builder.dart).
//
// The old code force-enabled the looping shimmer whenever a monster was
// turn-current and the line matched contains("advantage"), which ignored both
// the user's "Stat card text shimmers" setting and monster.isActive — and also
// matched inside the word "disadvantage". On device that pinned an idle board
// at ~90 fps with the setting off.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/line_builder/line_builder.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../../command/test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  setUp(() {
    getIt<GameState>().clearList();
  });

  /// Any monster works — the line under test is passed to [shouldAnimateLine]
  /// as a plain string, so the monster only supplies `isActive` and
  /// `turnState`. In the shipped data "Advantage" is a stat-card *attribute*
  /// carried by 21 monsters (Sun Demon, Night Demon, Black Imp and friends),
  /// but none of those are in `assets/testData/`.
  ///
  /// Adding a standee is what makes the monster active.
  Monster addMonster({required bool active}) {
    AddMonsterCommand(
      'Ancient Artillery (FH)',
      1,
      false,
      gameState: getIt<GameState>(),
    ).execute();
    final monster = getIt<GameState>().currentList.firstWhere((e) => e is Monster)
        as Monster;
    if (active) {
      AddStandeeCommand(
        1,
        null,
        'Ancient Artillery (FH)',
        MonsterType.normal,
        false,
        gameState: getIt<GameState>(),
      ).execute();
    }
    return monster;
  }

  void setTurn(Monster monster, TurnsState state) {
    (monster.turnState as ValueNotifier<TurnsState>).value = state;
  }

  group('shouldAnimateLine', () {
    test('THE BUG: shimmer off + turn-current + Advantage does not animate',
        () {
      final monster = addMonster(active: true);
      setTurn(monster, TurnsState.current);
      expect(
        shouldAnimateLine('Advantage', monster, false),
        isFalse,
        reason: 'the user setting must stay authoritative — this is the '
            'override that pinned an idle iOS board at ~90 fps',
      );
    });

    test('shimmer on + turn-current + Advantage still animates', () {
      final monster = addMonster(active: true);
      setTurn(monster, TurnsState.current);
      expect(
        shouldAnimateLine('Advantage', monster, true),
        isTrue,
      );
    });

    test('Advantage does not animate when the monster is not turn-current', () {
      final monster = addMonster(active: true);
      setTurn(monster, TurnsState.notDone);
      expect(
        shouldAnimateLine('Advantage', monster, true),
        isFalse,
      );
    });

    test('disadvantage animates via its own branch, not the advantage one', () {
      final monster = addMonster(active: true);
      // Not turn-current, so the advantage branch cannot be what matches.
      setTurn(monster, TurnsState.notDone);
      expect(
        shouldAnimateLine('Disadvantage', monster, true),
        isTrue,
      );
    });

    test('word boundary: "disadvantage" no longer matches the advantage branch',
        () {
      final monster = addMonster(active: true);
      setTurn(monster, TurnsState.current);
      // Both branches would return true here, so assert the regexp directly on
      // a line that contains "disadvantage" but must not count as "advantage".
      expect(RegExp(r'\badvantage\b').hasMatch('disadvantage'), isFalse);
    });

    test('deliberate tightening: turn-current but inactive no longer animates',
        () {
      final monster = addMonster(active: false);
      setTurn(monster, TurnsState.current);
      expect(monster.isActive, isFalse);
      expect(
        shouldAnimateLine('Advantage', monster, true),
        isFalse,
        reason: 'the old override bypassed isActive; folding it into the gate '
            'tightens this on purpose',
      );
    });

    test('null monster never animates', () {
      expect(
        shouldAnimateLine('Advantage', null, true),
        isFalse,
      );
    });
  });
}
