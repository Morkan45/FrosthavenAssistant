import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';

import '../services/network/communication.dart';
import '../services/network/network.dart';
import '../services/service_locator.dart';
import 'action_history.dart';
import 'game_event.dart';
import 'state/game_state.dart';

/// A bare ChangeNotifier that exposes [notify] so callers outside this class
/// can fire listeners without needing a meaningful value.
class ListUpdateNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class ActionHandler {
  final commandIndex = ValueNotifier<int>(-1);
  final ActionHistory _history = ActionHistory();

  List<HistoryEntry> get historyEntries => _history.entries;
  HistoryEntry? historyEntryAt(int index) => _history.entryAt(index);
  Command? commandAt(int index) => _history.commandAt(index);
  String? descriptionAt(int index) => _history.descriptionAt(index);
  GameSaveState? snapshotAt(int index) => _history.snapshotAt(index);
  GameSaveState? get currentSnapshot => _history.snapshotAt(commandIndex.value);
  int get retainedSnapshotCount => _history.retainedSnapshotCount;
  int get maxHistoryEntries => _history.maxEntries;
  bool get canUndo => snapshotAt(commandIndex.value - 1) != null;
  bool get canRedo => snapshotAt(commandIndex.value + 1) != null;

  /// Resets all command/description/save-state history to a clean slate,
  /// keeping only the most recent save state as the baseline.
  void resetCommandHistory() {
    final baseline = _history.latestSnapshotAtOrBefore(commandIndex.value);
    _history.reset(baseline);
    lastEvent.value = const NoEvent();
    commandIndex.value = -1;
  }

  /// Clears only the local commands list (used when connecting to a server).
  void clearLocalCommands() {
    _history.clearCommands();
  }

  /// Starts a new accepted network branch at [index].
  void insertReceivedDescription(int index, String description) {
    if (index != commandIndex.value + 1) {
      throw RangeError.value(index, 'index', 'must be the next command index');
    }
    _history.append(index: index, description: description);
  }

  void synchronizeReceivedDescription(int index, String description) {
    _history.synchronizeDescription(index, description);
  }

  /// Appends a save-state snapshot. Called by [GameState.save] and [GameState.load].
  void addSaveState(GameSaveState state) {
    _history.attachSnapshot(commandIndex.value, state);
  }

  /// The event produced by the most recent state transition.
  ///
  /// Set before [commandIndex] fires so that [commandIndex] VLB callbacks
  /// can read the correct event during their rebuild.
  final lastEvent = ValueNotifier<GameEvent>(const NoEvent());

  int get maxUndo => _history.maxSnapshots - 1;

  final updateList = ListUpdateNotifier();

  final GameState _gameState;
  final Communication _communication;
  final Settings? _settingsOverride;
  final Network? _networkOverride;

  ActionHandler({
    required GameState gameState,
    required Communication communication,
    Settings? settings,
    Network? network,
  }) : _gameState = gameState,
       _communication = communication,
       _settingsOverride = settings,
       _networkOverride = network;

  Settings get _settings => _settingsOverride ?? getIt<Settings>();
  Network get _network => _networkOverride ?? getIt<Network>();

  void updateAllUI() {
    updateList.notify();
    _gameState.notifyAllMonsterInstances();
  }

  Command getCurrent() {
    final cmd = commandAt(commandIndex.value);
    if (cmd == null) {
      throw StateError('No command at index ${commandIndex.value}');
    }
    return cmd;
  }

  void undo() {
    final isServer = _settings.server.value;
    final isClient = _settings.client.value == ClientState.connected;
    if (isClient) {
      _communication.sendToAll("undo");
      return;
    }

    final undoneIndex = commandIndex.value;
    final targetIndex = undoneIndex - 1;
    if (!_restoreTo(targetIndex, updateAllUi: isServer)) return;

    if (!isServer) {
      commandAt(undoneIndex)?.onUndo();
    } else {
      _sendServerState('undo');
    }
  }

  void redo() {
    final isServer = _settings.server.value;
    final isClient = _settings.client.value == ClientState.connected;
    if (isClient) {
      _communication.sendToAll("redo");
      return;
    }

    if (!_restoreTo(commandIndex.value + 1, updateAllUi: true)) return;
    if (isServer) {
      _sendServerState('redo');
    }
  }

  bool rollbackToHistoryIndex(int targetIndex) {
    if (targetIndex < -1 || targetIndex >= commandIndex.value) return false;
    if (_settings.client.value == ClientState.connected) {
      _communication.sendToAll('rollback:$targetIndex');
      return true;
    }

    if (!_restoreTo(targetIndex, updateAllUi: true)) return false;
    if (_settings.server.value) {
      _sendServerState('rollback');
    }
    return true;
  }

  bool _restoreTo(int targetIndex, {required bool updateAllUi}) {
    final saveState = snapshotAt(targetIndex);
    if (saveState == null || !saveState.load(_gameState)) return false;

    unawaited(saveState.saveToDisk(_gameState));
    lastEvent.value = const NoEvent();
    commandIndex.value = targetIndex;
    if (updateAllUi) updateAllUI();
    return true;
  }

  void _sendServerState(String operation) {
    final snapshot = currentSnapshot;
    if (snapshot == null) return;
    final index = commandIndex.value;
    final description = descriptionAt(index) ?? '';
    log(
      'server sends $operation result, index: $index, description:$description',
    );
    _network.server.send(
      StateEnvelope(
        index: index,
        description: description,
        eventJson: const NoEvent().toJsonString(),
        state: snapshot.getState(),
      ).encode(),
    );
  }

  void action(Command command) {
    bool isServer = _settings.server.value;
    bool isClient = _settings.client.value == ClientState.connected;

    command.execute();
    final description = command.describe();
    final event = command.event;
    final nextIndex = commandIndex.value + 1;
    _history.append(
      index: nextIndex,
      description: description,
      command: command,
    );

    // Set event before commandIndex fires so VLB callbacks see the correct value.
    lastEvent.value = event;
    commandIndex.value = nextIndex;

    final savedState = _gameState.save(); //save after each action

    //send last game state if connected
    final eventJson = event.toJsonString();
    if (isServer) {
      log(
        'server sends, index: ${commandIndex.value}, description:$description',
      );
      _network.server.send(
        StateEnvelope(
          index: commandIndex.value,
          description: description,
          eventJson: eventJson,
          state: savedState.getState(),
        ).encode(),
      );
    } else if (isClient) {
      log(
        'client sends, index: ${commandIndex.value}, description:$description',
      );
      _communication.sendToAll(
        StateEnvelope(
          index: commandIndex.value,
          description: description,
          eventJson: eventJson,
          state: savedState.getState(),
        ).encode(),
      );
    }
  }
}
