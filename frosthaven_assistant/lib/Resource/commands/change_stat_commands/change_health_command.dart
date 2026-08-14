import '../../../services/service_locator.dart';
import '../../enums.dart';
import '../../game_event.dart';
import '../../game_methods.dart';
import '../../settings.dart';
import '../../state/game_state.dart';
import 'change_stat_command.dart';
import '../command_l10n.dart';

class ChangeHealthCommand extends ChangeStatCommand {
  static const Set<Condition> _removedOnDamage = {
    Condition.ward,
    Condition.regenerate,
    Condition.brittle,
  };
  static const Set<Condition> _removedOnHeal = {
    Condition.poison,
    Condition.wound,
    Condition.brittle,
    Condition.bane,
  };

  ChangeHealthCommand(
    super.change,
    super.figureId,
    super.ownerId, {
    required super.gameState,
    Settings? settings,
  }) : _settings = settings ?? getIt<Settings>();

  final Settings _settings;

  @override
  void execute() {
    FigureState? figure = GameMethods.getFigure(
      ownerId,
      figureId,
      gameState: gameState,
    );
    if (figure != null) {
      final previousValue = figure.health.value;
      if (previousValue + change < 0) {
        //no negative values
        figure.setHealth(stateAccess, 0);
      } else {
        figure.setHealth(stateAccess, figure.health.value + change);
      }
      final newValue = figure.health.value;
      _removeHealthTriggeredConditions(figure, newValue - previousValue);
      if (previousValue <= 0 && newValue > 0) {
        //un death
        gameState.updateList.notify();
      }

      if (newValue <= 0) {
        handleDeath();
      }
    }
  }

  void _removeHealthTriggeredConditions(FigureState figure, int actualChange) {
    if (!_settings.expireConditions.value || actualChange == 0) return;

    final removedConditions = actualChange < 0
        ? _removedOnDamage
        : _removedOnHeal;
    final currentConditions = figure.conditions.value;
    if (!currentConditions.any(removedConditions.contains)) return;

    figure.setConditions(
      stateAccess,
      currentConditions
          .where((condition) => !removedConditions.contains(condition))
          .toList(),
    );
    for (final condition in removedConditions) {
      figure.removeFromConditionsThisTurn(stateAccess, condition);
      figure.removeFromConditionsPreviousTurn(stateAccess, condition);
    }
    gameState.updateList.notify();
  }

  @override
  GameEvent get event => HealthChangedEvent(figureId, ownerId ?? '', change);

  @override
  String describe() {
    if (change > 0) {
      //TODO: looks bad
      return commandL10n.cmdIncreaseHealth(figureId, change);
    }
    FigureState? figure = GameMethods.getFigure(
      ownerId,
      figureId,
      gameState: gameState,
    );
    if (figure == null || figure.health.value <= 0) {
      return commandL10n.cmdKill(ownerId ?? '');
    }
    //TODO: incorrect for character summons
    return commandL10n.cmdDecreaseHealth(ownerId ?? '', -change);
  }
}
