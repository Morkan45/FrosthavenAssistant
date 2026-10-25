import '../enums.dart';
import '../game_methods.dart';
import '../state/game_state.dart';
import 'command_l10n.dart';

/// Applies a quick effect to the figures taking the current turn atomically.
class AddConditionToFiguresCommand extends Command {
  AddConditionToFiguresCommand(
    this.condition,
    this.targets, {
    required GameState gameState,
  }) : _gameState = gameState;

  final Condition condition;
  final List<(String, String)> targets;
  final GameState _gameState;

  @override
  void execute() {
    for (final target in targets) {
      AddConditionCommand(
        condition,
        target.$1,
        target.$2,
        gameState: _gameState,
      ).execute();
    }
  }

  @override
  String describe() => commandL10n.cmdAddCondition(condition.getName());
}

class AddConditionCommand extends Command {
  final Condition condition;
  final String? ownerId;
  final String figureId;
  final GameState _gameState;

  AddConditionCommand(
    this.condition,
    this.figureId,
    this.ownerId, {
    required GameState gameState,
  }) : _gameState = gameState;

  @override
  void execute() {
    FigureState? figure = GameMethods.getFigure(
      ownerId,
      figureId,
      gameState: _gameState,
    );
    if (figure != null) {
      List<Condition> newList = [];
      newList.addAll(figure.conditions.value);
      if (!newList.contains(condition) || //block from adding same condition
          condition == Condition.chill ||
          condition == Condition.plague) {
        newList.add(condition);
      }
      figure.setConditions(stateAccess, newList);

      if (condition == Condition.chill) {
        figure.setChill(stateAccess, figure.chill.value + 1);
      }
      if (condition == Condition.plague) {
        figure.setPlague(stateAccess, figure.plague.value + 1);
      }

      //only added this turn if is current or done
      for (final item in _gameState.currentList) {
        if (item.id == ownerId) {
          if (item.turnState.value != TurnsState.notDone &&
              _gameState.roundState.value == RoundState.playTurns) {
            figure.addToConditionsThisTurn(stateAccess, condition);
          }
        }
      }
      _gameState.updateList.notify();
    }
  }

  @override
  String describe() {
    return commandL10n.cmdAddCondition(condition.getName());
  }
}
