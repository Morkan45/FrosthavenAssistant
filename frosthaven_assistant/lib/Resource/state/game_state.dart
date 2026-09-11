import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/stat_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Model/character_class.dart';
import '../../Model/monster.dart';
import '../../Model/monster_ability.dart';
import '../../Model/room.dart';
import '../../Model/scenario.dart';
import '../../services/network/communication.dart';
import '../../services/network/network.dart';
import '../../services/latest_value_queue.dart';
import '../../services/persistence_status.dart';
import '../../services/service_locator.dart';
import '../action_handler.dart';
import '../action_history.dart';
import '../card_stack.dart';
import '../commands/add_standee_command.dart';
import '../enums.dart';
import '../game_data.dart';
import '../game_event.dart';
import '../game_methods.dart';

part "../character_methods.dart";
part "../deck_methods.dart";
part "../element_methods.dart";
part "../game_util_methods.dart";
part "../monster_methods.dart";
part "../round_methods.dart";
part "../scenario_methods.dart";
part "character.dart";
part "character_state.dart";
part "figure_state.dart";
part "game_save_state.dart";
part "list_item_data.dart";
part "loot_card_state.dart";
part "loot_deck_codec.dart";
part "loot_deck_state.dart";
part "modifier_card.dart";
part "modifier_deck.dart";
part "modifier_deck_codec.dart";
part "monster.dart";
part "note_row.dart";
part "monster_ability_state.dart";
part "monster_instance.dart";
part "sanctuary_deck.dart";

// ignore_for_file: library_private_types_in_public_api

enum ReceivedTransitionKind {
  newStep,
  authoritativeCorrection,
  mismatchCorrection,
}

class GameState {
  late final ActionHandler _actionHandler;
  late final LatestValueQueue<String> _persistenceQueue;
  bool _diskLoadFailed = false;

  //state
  final _currentCampaign = ValueNotifier<String>("Jaws of the Lion");
  final _round = ValueNotifier<int>(1);
  final _totalRounds = ValueNotifier<int>(1);
  final _roundState = ValueNotifier<RoundState>(RoundState.chooseInitiative);
  final _level = ValueNotifier<int>(1);
  final _solo = ValueNotifier<bool>(false);
  final _autoScenarioLevel = ValueNotifier<bool>(false);
  final _allyDeckInOGGloom = ValueNotifier<bool>(true);
  final _difficulty = ValueNotifier<int>(1);
  final _scenario = ValueNotifier<String>("");
  final _toastMessage = ValueNotifier<String>("");
  final _showAllyDeck = ValueNotifier<bool>(false);
  final pendingAutoAddDialog = ValueNotifier<List<RoomMonsterData>?>(null);

  List<String> _scenarioSectionsAdded = [];
  List<SpecialRule> _scenarioSpecialRules = [];
  final _scenarioSectionsVersion = ValueNotifier<int>(0);
  List<ListItemData> _currentList = []; //has both monsters and characters
  final _currentListNotifier = ValueNotifier<BuiltList<ListItemData>>(
    BuiltList.of([]),
  );
  final List<MonsterAbilityState> _currentAbilityDecks =
      <MonsterAbilityState>[];
  final Map<Elements, ValueNotifier<ElementState>> _elementState = HashMap();
  Set<String> _unlockedClasses = {};
  final _unlockedClassesVersion = ValueNotifier<int>(0);

  LootDeck _lootDeck = LootDeck.empty(); //loot deck for current scenario
  final ModifierDeck _modifierDeck = ModifierDeck("");
  final ModifierDeck _modifierDeckAllies = ModifierDeck("allies");
  SanctuaryDeck _sanctuaryDeck = SanctuaryDeck();

  ValueListenable<String> get currentCampaign => _currentCampaign;
  ValueListenable<int> get round => _round;
  ValueListenable<int> get totalRounds => _totalRounds;
  ValueListenable<RoundState> get roundState => _roundState;
  ValueListenable<int> get level => _level;
  ValueListenable<bool> get solo => _solo;
  ValueListenable<bool> get autoScenarioLevel => _autoScenarioLevel;
  ValueListenable<bool> get allyDeckInOGGloom => _allyDeckInOGGloom;
  ValueListenable<int> get difficulty => _difficulty;
  ValueListenable<String> get toastMessage => _toastMessage;
  ValueListenable<String> get scenario => _scenario;
  ValueListenable<bool> get showAllyDeck => _showAllyDeck;
  ValueListenable<int> get scenarioSectionsVersion => _scenarioSectionsVersion;

  BuiltList<String> get scenarioSectionsAdded =>
      BuiltList.of(_scenarioSectionsAdded);
  BuiltList<SpecialRule> get scenarioSpecialRules =>
      BuiltList.of(_scenarioSpecialRules);
  BuiltList<ListItemData> get currentList => BuiltList.of(_currentList);
  ValueListenable<BuiltList<ListItemData>> get currentListNotifier =>
      _currentListNotifier;
  BuiltList<MonsterAbilityState> get currentAbilityDecks =>
      BuiltList.of(_currentAbilityDecks);
  BuiltMap<Elements, ElementState> get elementState =>
      BuiltMap.of(_elementState.map((k, v) => MapEntry(k, v.value)));

  ValueListenable<ElementState> elementStateFor(Elements element) =>
      _elementState[element]!;
  BuiltSet<String> get unlockedClasses => BuiltSet.of(_unlockedClasses);
  ValueListenable<int> get unlockedClassesVersion => _unlockedClassesVersion;

  LootDeck get lootDeck => _lootDeck; //todo: still mutable
  ModifierDeck get modifierDeck => _modifierDeck; //todo: still mutable
  ModifierDeck get modifierDeckAllies =>
      _modifierDeckAllies; //todo: still mutable
  SanctuaryDeck get sanctuaryDeck => _sanctuaryDeck;

  GameState({
    required Communication communication,
    Settings? settings,
    Network? network,
    Future<void> Function(String state)? stateWriter,
  }) {
    _persistenceQueue = LatestValueQueue(stateWriter ?? _writeGameStateToDisk);
    _actionHandler = ActionHandler(
      gameState: this,
      communication: communication,
      settings: settings,
      network: network,
    );
  }

  // ActionHandler delegation — public API preserved for all callers
  void action(Command command) => _actionHandler.action(command);
  void undo() => _actionHandler.undo();
  void redo() => _actionHandler.redo();
  void updateAllUI() => _actionHandler.updateAllUI();
  Command getCurrent() => _actionHandler.getCurrent();
  void resetCommandHistory() => _actionHandler.resetCommandHistory();
  void clearLocalCommands() => _actionHandler.clearLocalCommands();
  void insertReceivedDescription(int index, String description) =>
      _actionHandler.insertReceivedDescription(index, description);
  void synchronizeReceivedDescription(int index, String description) =>
      _actionHandler.synchronizeReceivedDescription(index, description);
  void addSaveState(GameSaveState state) => _actionHandler.addSaveState(state);
  bool applyReceivedTransition({
    required String state,
    required int index,
    required String description,
    required GameEvent event,
    required ReceivedTransitionKind kind,
  }) => _actionHandler.applyReceivedTransition(
    state: state,
    index: index,
    description: description,
    event: event,
    kind: kind,
  );

  ValueNotifier<int> get commandIndex => _actionHandler.commandIndex;
  ValueListenable<int> get transitionRevision =>
      _actionHandler.transitionRevision;
  ValueNotifier<GameEvent> get lastEvent => _actionHandler.lastEvent;
  ListUpdateNotifier get updateList => _actionHandler.updateList;
  int get maxUndo => _actionHandler.maxUndo;
  int get maxHistoryEntries => _actionHandler.maxHistoryEntries;
  int get retainedSnapshotCount => _actionHandler.retainedSnapshotCount;
  bool get canUndo => _actionHandler.canUndo;
  bool get canRedo => _actionHandler.canRedo;
  List<HistoryEntry> get historyEntries => _actionHandler.historyEntries;
  HistoryEntry? historyEntryAt(int index) =>
      _actionHandler.historyEntryAt(index);
  Command? commandAt(int index) => _actionHandler.commandAt(index);
  String? descriptionAt(int index) => _actionHandler.descriptionAt(index);
  GameSaveState? snapshotAt(int index) => _actionHandler.snapshotAt(index);
  GameSaveState? get currentSnapshot => _actionHandler.currentSnapshot;
  bool rollbackToHistoryIndex(int index) =>
      _actionHandler.rollbackToHistoryIndex(index);

  void init() {
    _elementState[Elements.fire] = ValueNotifier(ElementState.inert);
    _elementState[Elements.ice] = ValueNotifier(ElementState.inert);
    _elementState[Elements.air] = ValueNotifier(ElementState.inert);
    _elementState[Elements.earth] = ValueNotifier(ElementState.inert);
    _elementState[Elements.light] = ValueNotifier(ElementState.inert);
    _elementState[Elements.dark] = ValueNotifier(ElementState.inert);
  }

  void setCampaign(_StateModifier _, String value) {
    _currentCampaign.value = value;
  }

  void setRoundState(_StateModifier _, RoundState value) {
    _roundState.value = value;
  }

  void setLevel(_StateModifier _, int value) {
    _level.value = value;
  }

  void setSolo(_StateModifier _, bool value) {
    _solo.value = value;
  }

  void setAutoScenarioLevel(_StateModifier _, bool value) {
    _autoScenarioLevel.value = value;
  }

  void setAllyDeckInOGGloom(_StateModifier _, bool value) {
    _allyDeckInOGGloom.value = value;
  }

  void setDifficulty(_StateModifier _, int value) {
    _difficulty.value = value;
  }

  void setScenario(_StateModifier _, String value) {
    _scenario.value = value;
  }

  void setToastMessage(_StateModifier _, String value) {
    _toastMessage.value = value;
  }

  Map<String, dynamic> toJson() {
    final Map<String, int> elements = {};
    for (final key in _elementState.keys) {
      final state = _elementState[key];
      if (state != null) {
        elements[key.index.toString()] = state.value.index;
      }
    }
    return {
      'level': _level.value,
      'solo': _solo.value,
      'autoScenarioLevel': _autoScenarioLevel.value,
      'difficulty': _difficulty.value,
      'roundState': _roundState.value.index,
      'round': _round.value,
      'totalRounds': _totalRounds.value,
      'scenario': _scenario.value,
      'toastMessage': _toastMessage.value,
      'scenarioSpecialRules': _scenarioSpecialRules
          .map((r) => r.toJson())
          .toList(),
      'scenarioSectionsAdded': _scenarioSectionsAdded,
      'currentCampaign': _currentCampaign.value,
      'currentList': _currentList.map((item) => item.toJson()).toList(),
      'currentAbilityDecks': _currentAbilityDecks
          .map((d) => d.toJson())
          .toList(),
      'sanctuaryDeck': _sanctuaryDeck.toJson(),
      'modifierDeck': _modifierDeck.toJson(),
      'modifierDeckAllies': _modifierDeckAllies.toJson(),
      'lootDeck': _lootDeck.toJson(),
      'unlockedClasses': unlockedClasses.toList(),
      'showAllyDeck': showAllyDeck.value,
      'allyDeckInOGGloom': allyDeckInOGGloom.value,
      'elementState': elements,
    };
  }

  @override
  String toString() => json.encode(toJson());

  GameSaveState save() {
    final state = GameSaveState();
    state.save(this);
    unawaited(state.saveToDisk(this));
    addSaveState(state);
    return state;
  }

  Future<void> saveAndFlush() async {
    save();
    await flushPersistence();
  }

  Future<void> flushPersistence() => _diskLoadFailed
      ? Future<void>.error(StateError('The saved game could not be loaded.'))
      : _persistenceQueue.flush();

  ValueListenable<PersistenceStatus> get persistenceStatus =>
      _persistenceQueue.status;

  Future<void> retryPersistence() => _persistenceQueue.retryLatest();

  Future<void> _persistState(String state) {
    if (_diskLoadFailed) {
      final failure = Future<void>.error(
        StateError('The unreadable saved game must be reset before saving.'),
      );
      failure.ignore();
      return failure;
    }
    return _persistenceQueue.schedule(state);
  }

  Future<void> _writeGameStateToDisk(String state) async {
    const sharedPrefsKey = 'gameState';
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(sharedPrefsKey, state)) {
      throw StateError('Unable to write saved game.');
    }
  }

  Future<bool> load() async {
    GameSaveState state = GameSaveState();
    bool loaded;
    try {
      loaded = await state.loadFromDisk(this);
      if (!loaded) throw const FormatException('The saved game is unreadable.');
      _diskLoadFailed = false;
    } catch (_) {
      _diskLoadFailed = true;
      rethrow;
    }
    addSaveState(
      state,
    ); //init state: means game save state is one larger than command list
    return loaded;
  }

  /// Only called after an explicit reset choice on the startup error screen.
  Future<void> resetSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.remove('gameState')) {
      throw StateError('Unable to reset saved game.');
    }
    _diskLoadFailed = false;
  }

  bool loadFromData(String data) {
    GameSaveState state = GameSaveState();
    return state.loadFromData(data, this);
  }

  /// Fires `_currentListNotifier` with the current list and also increments
  /// `updateList` so that all existing subscribers remain notified.
  void _notifyCurrentList() {
    _reflowNoteRows();
    _currentListNotifier.value = BuiltList.of(_currentList);
    updateList.notify();
  }

  /// Keeps every linked [NoteRow] positioned directly after its target row (and
  /// after any earlier notes on the same target), so connected notes stay glued
  /// to their anchor through drag-reordering and the per-round initiative sort.
  /// Figures and unlinked notes keep their relative order. A note whose target
  /// is not currently present is left where it is (and re-glues if the target
  /// returns, e.g. mid network sync). No-op — and no reallocation — when there
  /// are no linked notes, which is the common case.
  void _reflowNoteRows() {
    bool hasLinkedNote = false;
    for (final item in _currentList) {
      if (item is NoteRow && item.linkedId.value.isNotEmpty) {
        hasLinkedNote = true;
        break;
      }
    }
    if (!hasLinkedNote) return;

    final Set<String> figureIds = {};
    for (final item in _currentList) {
      if (item is! NoteRow) figureIds.add(item.id);
    }

    final Map<String, List<NoteRow>> notesByTarget = {};
    final List<ListItemData> anchors = [];
    for (final item in _currentList) {
      if (item is NoteRow &&
          item.linkedId.value.isNotEmpty &&
          figureIds.contains(item.linkedId.value)) {
        notesByTarget.putIfAbsent(item.linkedId.value, () => []).add(item);
      } else {
        anchors.add(item);
      }
    }
    if (notesByTarget.isEmpty) return;

    final List<ListItemData> result = [];
    for (final item in anchors) {
      result.add(item);
      final notes = notesByTarget.remove(item.id);
      if (notes != null) result.addAll(notes);
    }
    _currentList = result;
  }

  /// Fires `monsterInstancesNotifier` / `summonListNotifier` on every item in
  /// the current list. Used by [updateAllUI] (redo / network sync).
  void notifyAllMonsterInstances() {
    for (final item in _currentList) {
      if (item is Monster) {
        item._notifyMonsterInstances();
      } else if (item is Character) {
        item.characterState._notifySummonList();
      }
    }
  }

  /// Clears the current list. only for use in tests. temp. should use load from data instead
  void clearList() {
    _currentList.clear();
    _notifyCurrentList();
  }
}

abstract class Command {
  //private class so only this class and it's children is allowed to change state
  _StateModifier stateAccess = _StateModifier();
  void execute();
  void onUndo() {}
  String describe();

  /// The [GameEvent] this command produces. Defaults to [NoEvent].
  /// Override in commands that drive UI animations.
  GameEvent get event => const NoEvent();
}

class _StateModifier {}
