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
  MainMenuViewModel({
    GameState? gameState,
    Settings? settings,
    Client? client,
    Network? network,
  }) : _gameState = gameState ?? getIt<GameState>(),
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
  ValueListenable<bool> get roleChangePending => _network.roleChangePending;
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

  bool get showLootDeckMenu => _gameState.currentCampaign.value == "Frosthaven";

  bool get showShowAllyDeck =>
      !_gameState.showAllyDeck.value &&
      !GameMethods.shouldShowAlliesDeck() &&
      _settings.showAmdDeck.value;

  bool get showHideAllyDeck =>
      _gameState.showAllyDeck.value && _settings.showAmdDeck.value;

  bool get showClientTile => !_settings.lastKnownConnection.endsWith('?');

  bool get isConnected => _settings.client.value == ClientState.connected;

  bool get isConnecting => _settings.client.value == ClientState.connecting;

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

  /// Stopping is always allowed. Starting requires a successful local save.
  Future<void> toggleClientConnection({String? address, String? port}) async {
    if (_settings.client.value == ClientState.connected) {
      _client.disconnect(null);
      return;
    }
    await _startRoleChange(() async {
      await _gameState.saveAndFlush();
      await _saveConnectionSettings(address: address, port: port);
      _settings.client.value = ClientState.connecting;
      await _client.connect(_settings.lastKnownConnection);
    });
  }

  void cancelClientConnection() => _client.cancelConnect();

  Future<void> toggleServer({String? port}) async {
    if (_settings.server.value) {
      _network.server.stopServer(null);
      return;
    }
    await _startRoleChange(() async {
      await _gameState.saveAndFlush();
      await _saveConnectionSettings(
        port: port,
        host: "(${_network.networkInfo.wifiIPv6.value})",
      );
      _network.server.startServer();
    });
  }

  Future<void> _startRoleChange(Future<void> Function() action) async {
    if (_network.roleChangePending.value) return;
    _network.roleChangePending.value = true;
    try {
      await action();
    } finally {
      _network.roleChangePending.value = false;
    }
  }

  Future<void> _saveConnectionSettings({
    String? address,
    String? port,
    String? host,
  }) async {
    final previousAddress = _settings.lastKnownConnection;
    final previousPort = _settings.lastKnownPort;
    final previousHost = _settings.lastKnownHostIP;
    _settings.lastKnownConnection = address ?? previousAddress;
    _settings.lastKnownPort = port ?? previousPort;
    _settings.lastKnownHostIP = host ?? previousHost;
    try {
      await _settings.saveToDisk();
    } catch (_) {
      _settings.lastKnownConnection = previousAddress;
      _settings.lastKnownPort = previousPort;
      _settings.lastKnownHostIP = previousHost;
      // Replace the rejected configuration in the queue as well as in memory.
      _settings.saveToDisk();
      rethrow;
    }
  }

  Future<void> save() => _gameState.saveAndFlush();
}
