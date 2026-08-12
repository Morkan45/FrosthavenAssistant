import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Model/campaign.dart';
import 'package:frosthaven_assistant/Resource/commands/draw_modifier_card_command.dart';
import 'package:frosthaven_assistant/Resource/game_data.dart';
import 'package:frosthaven_assistant/Resource/game_event.dart';
import 'package:frosthaven_assistant/Resource/game_methods.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/Resource/ui_utils.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../menus/ModifierDeckMenu/modifier_deck_menu.dart';
import '../menus/modifier_card_zoom.dart';

class ModifierDeckViewModel {
  ModifierDeckViewModel(
    this.name, {
    GameState? gameState,
    GameData? gameData,
    Settings? settings,
  })  : _gameState = gameState ?? getIt<GameState>(),
        _gameData = gameData ?? getIt<GameData>(),
        _settings = settings ?? getIt<Settings>();

  final String name;
  final GameState _gameState;
  final GameData _gameData;
  final Settings _settings;

  // Notifiers the widget subscribes to
  ValueListenable<double> get userScalingBars => _settings.userScalingBars;
  ValueListenable<GameEvent> get lastEvent => _gameState.lastEvent;
  Listenable get cardCount => deck.drawPileNotifier;
  ValueListenable<int> get revealedCount => deck.revealedCount;
  ValueListenable<Map<String, CampaignModel>> get modelData =>
      _gameData.modelData;

  // Derived state
  ModifierDeck get deck => GameMethods.getModifierDeck(name, _gameState);

  Character? get currentCharacter {
    final c = GameMethods.getCurrentCharacter();
    if (c != null && c.id == deck.name) return c;
    return null;
  }

  Color get currentCharacterColor =>
      currentCharacter != null ? Colors.black : Colors.transparent;

  String? get currentCharacterName => currentCharacter?.characterClass.name;

  // The draw event we have already animated. [_gameState.lastEvent] keeps the
  // last ModifierCardDrawnEvent set until the next command replaces it, so a
  // rebuild that is not itself a new draw (scaling the bars, revealing, opening
  // the menu) would otherwise re-trigger the animation and replay it. Tracking
  // the event by identity lets us animate each draw exactly once.
  Object? _lastAnimatedEvent;

  /// The pending draw event for this deck that has not yet been consumed, or
  /// null if the last event is not a draw for this deck.
  GameEvent? get _pendingDrawEvent {
    final event = _gameState.lastEvent.value;
    if (event is ModifierCardDrawnEvent && event.deckName == name) return event;
    return null;
  }

  /// Whether a draw animation should start now: there is a pending draw for
  /// this deck and we have not already animated it. Pure — call
  /// [markDrawAnimated] once the animation has been started.
  bool initAnimationEnabled() {
    final event = _pendingDrawEvent;
    return event != null && !identical(event, _lastAnimatedEvent);
  }

  /// Records the current pending draw as animated so it is not replayed on a
  /// later rebuild. Also used for local taps, where the widget enables the
  /// animation directly without going through [initAnimationEnabled].
  void markDrawAnimated() {
    _lastAnimatedEvent = _gameState.lastEvent.value;
  }

  void drawCard() {
    _gameState.action(DrawModifierCardCommand(name, gameState: _gameState));
  }

  void openModifierMenu(BuildContext context) {
    openDialog(context, ModifierDeckMenu(name: deck.name));
  }

  void openZoom(BuildContext context) {
    if (deck.discardPileIsNotEmpty) {
      openDialog(
          context, ModifierCardZoom(name: name, card: deck.discardPileTop));
    }
  }
}
