import 'package:collection/collection.dart';

import '../state/game_state.dart';
import 'command_l10n.dart';

class SetNoteRowColorCommand extends Command {
  SetNoteRowColorCommand(this.color, this.noteId, {required GameState gameState})
      : _gameState = gameState;
  final int color;
  final String noteId;
  final GameState _gameState;

  @override
  void execute() {
    final match = _gameState.currentList
        .firstWhereOrNull((element) => element.id == noteId);
    if (match is NoteRow) {
      match.setColor(stateAccess, color);
    }
  }

  @override
  String describe() {
    return commandL10n.cmdSetNoteRowColor;
  }
}
