// ignore_for_file: avoid-late-keyword, no-magic-number

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_note_row_command.dart';
import 'package:frosthaven_assistant/Resource/commands/draw_command.dart';
import 'package:frosthaven_assistant/Resource/commands/remove_note_row_command.dart';
import 'package:frosthaven_assistant/Resource/commands/reorder_list_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_init_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_note_row_color_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_note_row_link_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_note_row_text_command.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  GameState gs() => getIt<GameState>();

  setUp(() {
    gs().clearList();
    AddCharacterCommand('Blinkblade', 'Frosthaven', "Blinky", 1).execute();
    AddMonsterCommand("Zealot", 1, false, gameState: gs()).execute();
  });

  int indexOfId(String id) =>
      gs().currentList.toList().indexWhere((e) => e.id == id);

  group('NoteRow commands', () {
    test('unlinked note is added as its own row and survives save/load', () {
      gs().action(AddNoteRowCommand(NoteRow.create('note1', text: 'remember'),
          gameState: gs()));

      final match = gs().currentList.firstWhere((e) => e.id == 'note1');
      expect(match, isA<NoteRow>());
      expect((match as NoteRow).text.value, 'remember');
      checkSaveState();
    });

    test('linked note is glued directly after its target', () {
      // Link a note to the Zealot monster.
      gs().action(AddNoteRowCommand(
          NoteRow.create('note1', text: 'focus first', linkedId: 'Zealot'),
          gameState: gs()));

      final monsterIndex = indexOfId('Zealot');
      final noteIndex = indexOfId('note1');
      expect(noteIndex, monsterIndex + 1,
          reason: 'linked note must sit immediately after its target');
      checkSaveState();
    });

    test('note re-glues after the list is reordered', () {
      gs().action(AddNoteRowCommand(
          NoteRow.create('note1', linkedId: 'Zealot'),
          gameState: gs()));

      // Move the note to the very top; reflow should pull it back under Zealot.
      final from = indexOfId('note1');
      gs().action(ReorderListCommand(0, from, gameState: gs()));

      final monsterIndex = indexOfId('Zealot');
      expect(indexOfId('note1'), monsterIndex + 1);
    });

    test('linked note stays glued under its target through the draw (round start)',
        () {
      // Give the character an initiative and link a note to it.
      SetInitCommand('Blinkblade', 25, gameState: gs()).execute();
      gs().action(AddNoteRowCommand(
          NoteRow.create('note1', linkedId: 'Blinkblade'),
          gameState: gs()));
      expect(indexOfId('note1'), indexOfId('Blinkblade') + 1);

      // Drawing for the round sorts the list by initiative (scattering notes,
      // which have no initiative) and notifies via updateList.notify(). The
      // reflow in the sort must still re-glue the note under its target.
      gs().action(DrawCommand(gameState: gs()));

      expect(indexOfId('note1'), indexOfId('Blinkblade') + 1,
          reason: 'note must follow its target across the initiative sort');
    });

    test('setText / setColor / link / unlink mutate the note', () {
      gs().action(
          AddNoteRowCommand(NoteRow.create('note1'), gameState: gs()));
      final note =
          gs().currentList.firstWhere((e) => e.id == 'note1') as NoteRow;

      gs().action(SetNoteRowTextCommand('hello', 'note1', gameState: gs()));
      expect(note.text.value, 'hello');

      gs().action(
          SetNoteRowColorCommand(0xFFAA0000, 'note1', gameState: gs()));
      expect(note.color.value, 0xFFAA0000);

      gs().action(
          SetNoteRowLinkCommand('note1', 'Zealot', 3, gameState: gs()));
      expect(note.linkedId.value, 'Zealot');
      expect(note.standeeNr.value, 3);

      // Unlink clears the standee too.
      gs().action(SetNoteRowLinkCommand('note1', '', 0, gameState: gs()));
      expect(note.linkedId.value, '');
      expect(note.standeeNr.value, 0);
      checkSaveState();
    });

    test('remove deletes the note row', () {
      gs().action(
          AddNoteRowCommand(NoteRow.create('note1'), gameState: gs()));
      expect(indexOfId('note1') >= 0, true);

      gs().action(RemoveNoteRowCommand('note1', gameState: gs()));
      expect(indexOfId('note1'), -1);
      checkSaveState();
    });
  });
}
