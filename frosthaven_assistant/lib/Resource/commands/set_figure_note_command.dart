import 'package:collection/collection.dart';

import '../state/game_state.dart';
import 'command_l10n.dart';

/// Sets the free-form inline note shown on a figure's row (character or
/// monster). Undo is handled by the snapshot-based history in [ActionHandler],
/// so no [onUndo] is needed.
class SetFigureNoteCommand extends Command {
  SetFigureNoteCommand(this.note, this.figureId, {required GameState gameState})
      : _gameState = gameState;
  final String note;
  final String figureId;
  final GameState _gameState;

  @override
  void execute() {
    final match = _gameState.currentList
        .firstWhereOrNull((element) => element.id == figureId);
    if (match != null) {
      match.setNote(stateAccess, note);
    }
  }

  @override
  String describe() {
    return commandL10n.cmdSetCharacterNote(figureId);
  }
}
