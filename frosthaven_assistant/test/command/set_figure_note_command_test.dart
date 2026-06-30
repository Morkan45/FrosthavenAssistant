// ignore_for_file: avoid-late-keyword

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_figure_note_command.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  GameState gs() => getIt<GameState>();
  late Character character;

  setUp(() {
    gs().clearList();
    AddCharacterCommand('Blinkblade', 'Frosthaven', "Blinky", 1).execute();
    character = gs().currentList.firstWhere((e) => e is Character) as Character;
  });

  group('SetFigureNoteCommand', () {
    test('sets a character note (on the shared base) and survives save/load',
        () {
      expect(character.note.value, '');
      SetFigureNoteCommand('poison next turn', character.id, gameState: gs())
          .execute();

      expect(character.note.value, 'poison next turn');
      // Round-trips the whole game through toJson/fromJson and asserts the
      // serialized state is unchanged, proving the note persists.
      checkSaveState();
    });

    test('sets a monster note and survives save/load', () {
      AddMonsterCommand("Zealot", 1, false, gameState: gs()).execute();
      final monster =
          gs().currentList.firstWhere((e) => e is Monster) as Monster;
      expect(monster.note.value, '');

      SetFigureNoteCommand('focus first', monster.id, gameState: gs())
          .execute();

      expect(monster.note.value, 'focus first');
      checkSaveState();
    });

    test('clears the note when set to empty', () {
      SetFigureNoteCommand('temp', character.id, gameState: gs()).execute();
      expect(character.note.value, 'temp');

      SetFigureNoteCommand('', character.id, gameState: gs()).execute();
      expect(character.note.value, '');
      checkSaveState();
    });

    test('describe should return correct string', () {
      final command =
          SetFigureNoteCommand('note', 'Blinkblade', gameState: gs());
      expect(command.describe(), 'Set note for Blinkblade');
    });
  });
}
