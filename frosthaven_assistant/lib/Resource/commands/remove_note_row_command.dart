import '../state/game_state.dart';
import 'command_l10n.dart';

class RemoveNoteRowCommand extends Command {
  RemoveNoteRowCommand(this.noteId, {required GameState gameState})
      : _gameState = gameState;
  final String noteId;
  final GameState _gameState;

  @override
  void execute() {
    RoundMethods.removeFromMainList(stateAccess, noteId, gameState: _gameState);
  }

  @override
  String describe() {
    return commandL10n.cmdRemoveNoteRow;
  }
}
