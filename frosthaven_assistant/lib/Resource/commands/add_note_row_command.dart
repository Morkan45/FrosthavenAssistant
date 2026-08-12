import '../state/game_state.dart';
import 'command_l10n.dart';

/// Adds a [NoteRow] to the main list. If the note is linked, the list's reflow
/// step positions it directly beneath its target; otherwise it is appended.
class AddNoteRowCommand extends Command {
  AddNoteRowCommand(this.noteRow, {required GameState gameState})
      : _gameState = gameState;
  final NoteRow noteRow;
  final GameState _gameState;

  @override
  void execute() {
    RoundMethods.addToMainList(stateAccess, null, noteRow, gameState: _gameState);
  }

  @override
  String describe() {
    return commandL10n.cmdAddNoteRow;
  }
}
