import '../game_data.dart';
import '../settings.dart';
import '../state/game_state.dart';
import 'command_l10n.dart';

class SetScenarioCommand extends Command {
  final String _scenario;
  final bool _section;
  final GameState _gameState;
  final GameData? _gameData;
  final Settings? _settings;

  SetScenarioCommand(
    this._scenario,
    this._section, {
    required GameState gameState,
    GameData? gameData,
    Settings? settings,
  }) : _gameState = gameState,
       _gameData = gameData,
       _settings = settings;

  @override
  void execute() {
    ScenarioMethods.setScenario(
      stateAccess,
      _scenario,
      _section,
      gameState: _gameState,
      gameData: _gameData,
      settings: _settings,
    );
  }

  @override
  String describe() {
    if (!_section) {
      return commandL10n.cmdSetScenario;
    }
    return commandL10n.cmdAddSection;
  }
}
