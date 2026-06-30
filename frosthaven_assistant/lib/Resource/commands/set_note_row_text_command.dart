import 'package:collection/collection.dart';

import '../state/game_state.dart';
import 'command_l10n.dart';

class SetNoteRowTextCommand extends Command {
  SetNoteRowTextCommand(this.text, this.noteId, {required GameState gameState})
      : _gameState = gameState;
  final String text;
  final String noteId;
  final GameState _gameState;

  @override
  void execute() {
    final match = _gameState.currentList
        .firstWhereOrNull((element) => element.id == noteId);
    if (match is NoteRow) {
      match.setText(stateAccess, text);
    }
  }

  @override
  String describe() {
    return commandL10n.cmdSetNoteRowText;
  }
}
