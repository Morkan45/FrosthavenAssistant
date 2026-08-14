import '../../services/service_locator.dart';
import '../game_event.dart';
import '../settings.dart';
import '../state/game_state.dart';
import 'command_l10n.dart';

class TurnDoneCommand extends Command {
  int index = 0;
  final String id;
  final GameState _gameState;
  final Settings _settings;

  TurnDoneCommand(this.id, {required GameState gameState, Settings? settings})
    : _gameState = gameState,
      _settings = settings ?? getIt<Settings>() {
    index = 0;
    for (int i = 0; i < _gameState.currentList.length; i++) {
      if (id == _gameState.currentList[i].id) {
        index = i;
        break;
      }
    }
  }

  @override
  void execute() {
    RoundMethods.setTurnDone(
      stateAccess,
      index,
      gameState: _gameState,
      settings: _settings,
    );
    _gameState.updateList.notify();
  }

  @override
  GameEvent get event => TurnDoneEvent(id);

  @override
  String describe() {
    return commandL10n.cmdTurnDone(id);
  }
}
