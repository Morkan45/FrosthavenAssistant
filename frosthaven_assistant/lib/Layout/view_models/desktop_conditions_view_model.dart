import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../Resource/commands/add_condition_command.dart';
import '../../Resource/enums.dart';
import '../../Resource/game_methods.dart';
import '../../Resource/settings.dart';
import '../../Resource/state/game_state.dart';
import '../../services/service_locator.dart';
import 'condition_button_view_model.dart';
import 'status_menu_view_model.dart';

/// Quick effects follow the current turn; drags always target a single figure.
class DesktopConditionsViewModel extends ChangeNotifier {
  DesktopConditionsViewModel({GameState? gameState, Settings? settings})
    : _gameState = gameState ?? getIt<GameState>(),
      _settings = settings ?? getIt<Settings>() {
    _gameState.updateList.addListener(_onGameChanged);
    _gameState.currentListNotifier.addListener(_onGameChanged);
    _gameState.roundState.addListener(_onGameChanged);
    _gameState.transitionRevision.addListener(_onGameChanged);
    _settings.style.addListener(notifyListeners);
    _settings.darkMode.addListener(notifyListeners);
  }

  static const _standardConditions = [
    Condition.stun,
    Condition.immobilize,
    Condition.disarm,
    Condition.wound,
    Condition.muddle,
    Condition.poison,
    Condition.bane,
    Condition.brittle,
    Condition.impair,
    Condition.strengthen,
    Condition.invisible,
    Condition.regenerate,
    Condition.ward,
  ];

  final GameState _gameState;
  final Settings _settings;
  Condition? _draggedCondition;
  (String, String?)? _hoveredTarget;
  bool _stickyDrag = false;
  bool _dragCancelled = false;
  bool _disposed = false;

  bool get isDarkMode => _settings.darkMode.value;
  Condition? get draggedCondition => _draggedCondition;
  bool get isStickyDrag => _stickyDrag;
  bool get isDragCancelled => _dragCancelled;

  void beginDrag(Condition condition) {
    _draggedCondition = condition;
    _hoveredTarget = null;
    _stickyDrag = false;
    _dragCancelled = false;
    notifyListeners();
  }

  void hoverTarget(String figureId, String? ownerId) {
    _hoveredTarget = (figureId, ownerId);
  }

  void clearHoverTarget() => _hoveredTarget = null;

  void leaveTarget(String figureId, String? ownerId) {
    if (_hoveredTarget == (figureId, ownerId)) _hoveredTarget = null;
  }

  void stickyDrop() {
    final condition = _draggedCondition;
    if (condition == null || _dragCancelled) return;
    _stickyDrag = true;
    final target = _hoveredTarget;
    if (target != null) apply(condition, target.$1, target.$2);
    notifyListeners();
  }

  void acceptDrop(Condition condition, String figureId, String? ownerId) {
    // The final release of the right button ends a sticky drag without
    // applying again.
    if (!_stickyDrag && !_dragCancelled) apply(condition, figureId, ownerId);
  }

  void cancelDrag({bool deferNotification = false}) {
    if (_disposed || _draggedCondition == null) return;
    _draggedCondition = null;
    _dragCancelled = true;
    _hoveredTarget = null;
    if (deferNotification) {
      // A source can disappear during a toolbar rebuild.
      scheduleMicrotask(() {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  void endDrag() {
    _draggedCondition = null;
    _hoveredTarget = null;
    _stickyDrag = false;
    _dragCancelled = false;
    notifyListeners();
  }

  ListItemData? get activeItem {
    if (_gameState.roundState.value != RoundState.playTurns) return null;
    for (final item in _gameState.currentList) {
      if (item.turnState.value == TurnsState.current &&
          (item is Character || item is Monster)) {
        return item;
      }
    }
    return null;
  }

  String? get activeName => switch (activeItem) {
    Character character => character.characterState.display.value,
    Monster monster => monster.type.display,
    _ => null,
  };

  List<Condition> get conditions => _standardConditions;

  List<(String, String)> get _activeTargets => switch (activeItem) {
    Character character when character.characterState.health.value > 0 => [
      (character.id, character.id),
    ],
    Monster monster when monster.isActive => [
      for (final standee in monster.monsterInstances)
        if (standee.health.value > 0) (standee.getId(), monster.id),
    ],
    _ => [],
  };

  bool isApplied(Condition condition) {
    final targets = _activeTargets;
    return targets.isNotEmpty &&
        targets.every(
          (target) =>
              GameMethods.getFigure(
                target.$2,
                target.$1,
                gameState: _gameState,
              )?.conditions.value.contains(condition) ??
              false,
        );
  }

  bool canApplyToActive(Condition condition) =>
      _activeTargets.any((target) => canApply(condition, target.$1, target.$2));

  bool canApply(Condition condition, String figureId, String? ownerId) {
    final figure = GameMethods.getFigure(
      ownerId,
      figureId,
      gameState: _gameState,
    );
    if (figure == null || !conditions.contains(condition)) return false;
    if (figure.conditions.value.contains(condition)) {
      return false;
    }

    final isMonster = _gameState.currentList.any(
      (item) => item is Monster && item.id == ownerId,
    );
    final status = StatusMenuViewModel(
      figureId: figureId,
      monsterId: isMonster ? ownerId : null,
      characterId: isMonster ? null : ownerId,
      gameState: _gameState,
      settings: _settings,
    );
    return ConditionButtonViewModel(
      condition: condition,
      figureId: figureId,
      ownerId: ownerId,
      immunities: status.immunities,
      gameState: _gameState,
      settings: _settings,
    ).enabled;
  }

  void apply(Condition condition, String figureId, String? ownerId) {
    // Re-resolve the target on release; it may have changed during a drag.
    if (!canApply(condition, figureId, ownerId)) return;
    _gameState.action(
      AddConditionCommand(condition, figureId, ownerId, gameState: _gameState),
    );
  }

  void applyToActive(Condition condition) {
    final targets = _activeTargets
        .where((target) => canApply(condition, target.$1, target.$2))
        .toList();
    if (targets.isEmpty) return;
    // One toolbar click is one undo step, including a monster group's standees.
    _gameState.action(
      AddConditionToFiguresCommand(condition, targets, gameState: _gameState),
    );
  }

  void _onGameChanged() => notifyListeners();

  @override
  void dispose() {
    _disposed = true;
    _gameState.updateList.removeListener(_onGameChanged);
    _gameState.currentListNotifier.removeListener(_onGameChanged);
    _gameState.roundState.removeListener(_onGameChanged);
    _gameState.transitionRevision.removeListener(_onGameChanged);
    _settings.style.removeListener(notifyListeners);
    _settings.darkMode.removeListener(notifyListeners);
    super.dispose();
  }
}
