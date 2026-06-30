import 'package:collection/collection.dart';

import '../state/game_state.dart';
import 'command_l10n.dart';

/// Attaches a note to a figure (character or monster) by [linkedId], optionally
/// pinned to [standeeNr] for a monster standee, or detaches it when [linkedId]
/// is empty. The list's reflow step repositions the note accordingly.
class SetNoteRowLinkCommand extends Command {
  SetNoteRowLinkCommand(this.noteId, this.linkedId, this.standeeNr,
      {required GameState gameState})
      : _gameState = gameState;
  final String noteId;
  final String linkedId;
  final int standeeNr;
  final GameState _gameState;

  @override
  void execute() {
    final match = _gameState.currentList
        .firstWhereOrNull((element) => element.id == noteId);
    if (match is NoteRow) {
      match.setLink(stateAccess, linkedId, standeeNr);
    }
  }

  @override
  String describe() {
    return commandL10n.cmdLinkNoteRow;
  }
}
