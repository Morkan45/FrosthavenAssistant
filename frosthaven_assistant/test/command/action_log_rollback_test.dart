// ignore_for_file: no-magic-number, avoid-late-keyword

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  GameState gs() => getIt<GameState>();

  // The tap-to-rollback in ActionLogMenu rolls back to a chosen entry by calling
  // undo (currentIndex - targetIndex) times. This verifies that semantics: the
  // chosen action stays, later ones are undone, and everything stays redoable.
  test('rolling back to an action undoes only the later ones (redoable)', () {
    gs().clearList();
    final startMonsters = gs().currentList.whereType<Monster>().length;

    gs().action(AddMonsterCommand("Zealot", 1, false, gameState: gs()));
    final afterZealotIndex = gs().commandIndex.value; // the entry we roll back to
    gs().action(
        AddMonsterCommand("Ancient Artillery (FH)", 1, false, gameState: gs()));

    expect(gs().currentList.whereType<Monster>().length, startMonsters + 2);

    // Roll back to "after Zealot": undo (current - target) times.
    final count = gs().commandIndex.value - afterZealotIndex;
    expect(count, 1);
    for (int k = 0; k < count; k++) {
      gs().undo();
    }

    // Zealot remains; the later add is undone.
    expect(gs().currentList.any((e) => e.id == "Zealot"), true);
    expect(gs().currentList.any((e) => e.id == "Ancient Artillery (FH)"), false);

    // Still redoable until a new action is taken.
    for (int k = 0; k < count; k++) {
      gs().redo();
    }
    expect(gs().currentList.any((e) => e.id == "Ancient Artillery (FH)"), true);
  });
}
