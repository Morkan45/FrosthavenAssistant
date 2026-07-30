import 'package:flutter/foundation.dart';
import 'package:frosthaven_assistant/Resource/commands/hide_ally_deck_command.dart';
import 'package:frosthaven_assistant/Resource/commands/show_ally_deck_command.dart';
import 'package:frosthaven_assistant/Resource/game_methods.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/network/client.dart';
import 'package:frosthaven_assistant/services/network/network.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

class MainMenuViewModel {
  MainMenuViewModel(
      {GameState? gameState,
      Settings? settings,
      Client? client,
      Network? network})
      : _gameState = gameState ?? getIt<GameState>(),
        _settings = settings ?? getIt<Settings>(),
        _client = client ?? getIt<Client>(),
        _network = network ?? getIt<Network>();

  final GameState _gameState;
  final Settings _settings;
  final Client _client;
  final Network _network;

  // Notifiers the widget subscribes to
  ValueListenable<int> get commandIndex => _gameState.commandIndex;
  ValueListenable<ClientState> get clientState => _settings.client;
  ValueListenable<bool> get serverState => _settings.server;
  ValueListenable<String> get wifiIPv6 => _network.networkInfo.wifiIPv6;

  // Derived state
  bool get undoEnabled {
    if (_settings.client.value == ClientState.connected) return true;
    return _gameState.canUndo;
  }

  bool get redoEnabled {
    if (_settings.client.value == ClientState.connected) return true;
    return _gameState.canRedo;
  }

  String? get undoDescription {
    if (_settings.client.value == ClientState.connected) return null;
    final index = _gameState.commandIndex.value;
    return _gameState.descriptionAt(index);
  }

  String? get redoDescription {
    if (_settings.client.value == ClientState.connected) return null;
    final index = _gameState.commandIndex.value;
    return _gameState.descriptionAt(index + 1);
  }

  bool get isRandomDungeon => _gameState.scenario.value == '#Random Dungeon';

  bool get showLootDeckMenu =>
      _gameState.currentCampaign.value == "Frosthaven";

  bool get showShowAllyDeck =>
      !_gameState.showAllyDeck.value &&
      !GameMethods.shouldShowAlliesDeck() &&
      _settings.showAmdDeck.value;

  bool get showHideAllyDeck =>
      _gameState.showAllyDeck.value && _settings.showAmdDeck.value;

  bool get showClientTile =>
      !_settings.lastKnownConnection.endsWith('?');

  bool get isConnected =>
      _settings.client.value == ClientState.connected;

  bool get isConnecting =>
      _settings.client.value == ClientState.connecting;

  String get lastKnownConnection => _settings.lastKnownConnection;

  bool get isServer => _settings.server.value;

  // Actions
  void undo() => _gameState.undo();
  void redo() => _gameState.redo();

  void showAllyDeck() {
    _gameState.action(ShowAllyDeckCommand());
    _gameState.updateAllUI();
  }

  void hideAllyDeck() {
    _gameState.action(HideAllyDeckCommand());
    _gameState.updateAllUI();
  }

  Future<void> toggleClientConnection() async {
    await _gameState.flushPersistence();
    if (_settings.client.value != ClientState.connected) {
      _settings.client.value = ClientState.connecting;
      await _client.connect(_settings.lastKnownConnection);
      await _settings.saveToDisk();
    } else {
      _client.disconnect(null);
    }
  }

  void cancelClientConnection() => _client.cancelConnect();

  Future<void> toggleServer() async {
    await _gameState.flushPersistence();
    _settings.lastKnownHostIP =
        "(${_network.networkInfo.wifiIPv6.value})";
    await _settings.saveToDisk();
    if (!_settings.server.value) {
      _network.server.startServer();
    } else {
      _network.server.stopServer(null);
    }
  }

  Future<void> save() => _gameState.saveAndFlush();
}
