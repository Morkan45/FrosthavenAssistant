// ignore_for_file: no-magic-number, avoid-late-keyword

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_note_row_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/commands/change_stat_commands/change_health_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  GameState gs() => getIt<GameState>();

  test('a note tied to a specific standee is deleted when that standee dies', () {
    gs().clearList();
    AddMonsterCommand("Zealot", 1, false, gameState: gs()).execute();
    AddStandeeCommand(1, null, "Zealot", MonsterType.normal, false,
            gameState: gs())
        .execute();
    final monster = gs().currentList.firstWhere((e) => e is Monster) as Monster;
    final instance = monster.monsterInstances.first;
    final standeeNr = instance.standeeNr;

    // A note pinned to this standee, plus a whole-group note (standeeNr 0).
    gs().action(AddNoteRowCommand(
        NoteRow.create('standeeNote',
            linkedId: monster.id, standeeNr: standeeNr),
        gameState: gs()));
    gs().action(AddNoteRowCommand(
        NoteRow.create('groupNote', linkedId: monster.id),
        gameState: gs()));
    expect(gs().currentList.any((e) => e.id == 'standeeNote'), true);

    // Defeat the standee (drop its health to 0).
    gs().action(ChangeHealthCommand(
        -instance.health.value, instance.getId(), monster.id,
        gameState: gs()));

    // The standee's note is gone; the whole-group note remains.
    expect(gs().currentList.any((e) => e.id == 'standeeNote'), false,
        reason: 'note tied to the defeated standee should be deleted');
    expect(gs().currentList.any((e) => e.id == 'groupNote'), true,
        reason: 'whole-group note is not standee-specific and should remain');
  });
}
