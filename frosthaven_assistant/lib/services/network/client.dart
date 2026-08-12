import 'dart:async';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:frosthaven_assistant/services/network/communication.dart';
import 'package:frosthaven_assistant/services/network/network.dart';
import 'package:frosthaven_assistant_server/game_server.dart';
import 'package:frosthaven_assistant_server/message_framer.dart';

import '../../Resource/game_event.dart';
import '../../Resource/settings.dart';
import '../../Resource/state/game_state.dart';
import '../../l10n/app_localizations.dart';
import '../service_locator.dart';
import 'connection.dart';

class Client {
  bool _serverResponsive = true;

  // Consecutive ping windows the server has failed to answer. A single missed
  // pong is usually just a transient network hiccup, so tolerate a few before
  // treating the server as gone — dropping on the first miss disconnected
  // players too eagerly on flaky wifi.
  int _missedPongs = 0;
  static const int _maxMissedPongs = 2;

  bool _connectCancelled = false;
  final GameState _gameState;
  final Communication _communication;
  final Connection _connection;
  final Network _network;
  final Settings _settings;
  int _session = 0;

  bool get hasActiveConnection => _connection.established();

  AppLocalizations get _l10n {
    final code = _settings.locale.value;
    try {
      return lookupAppLocalizations(Locale(code));
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  Client({
    GameState? gameState,
    Communication? communication,
    Connection? connection,
    Network? network,
    Settings? settings,
  }) : _gameState = gameState ?? getIt<GameState>(),
       _communication = communication ?? getIt<Communication>(),
       _connection = connection ?? getIt<Connection>(),
       _network = network ?? getIt<Network>(),
       _settings = settings ?? getIt<Settings>();

  void _setNetworkMessage(String msg, {bool isError = false}) {
    _network.networkMessageIsError.value = isError;
    _network.networkMessage.value = msg;
  }

  Future<void> connect(String address) async {
    if (_connection.established() &&
        _settings.client.value == ClientState.connected) {
      return;
    }
    final session = ++_session;
    _serverResponsive = true;
    _missedPongs = 0;
    _connectCancelled = false;
    _pingGeneration++;
    // Bumping the generation retires any chain from a previous connection, so
    // the old chain can no longer stand in for this one — clear the re-entrancy
    // guard too, or a reconnect that happens without an intervening _cleanup()
    // would end up with no ping chain at all.
    _pinging = false;
    try {
      int port = int.parse(_settings.lastKnownPort);
      debugPrint("port nr: ${port.toString()}");
      final socket = await _connection.connect(address, port);
      if (session != _session) {
        socket.destroy();
        return;
      }
      runZonedGuarded(
        () {
          _settings.client.value = ClientState.connected;
          String info = _l10n.clientConnectedTo(
            '${socket.remoteAddress.address}:${socket.remotePort}',
          );
          debugPrint(info);
          _gameState.resetCommandHistory();
          _setNetworkMessage(info);
          if (Platform.isAndroid || Platform.isIOS) {
            _settings.connectClientOnStartup = true;
          }
          _settings.saveToDisk();
          _send("init protocolVersion:${GameServer.protocolVersion}");
          _sendPing(session);
          _listen(socket, session);
        },
        (error, stack) {
          debugPrint('Client zone error: $error\n$stack');
          _setNetworkMessage(
            _l10n.clientError(error.toString()),
            isError: true,
          );
        },
      );
    } catch (error) {
      if (session != _session) return;
      if (_connectCancelled) {
        debugPrint("client connect cancelled by user");
        _setNetworkMessage(_l10n.connectionCancelled);
      } else {
        debugPrint("client error: $error");
        _setNetworkMessage(_l10n.clientError(error.toString()), isError: true);
      }
      _settings.client.value = ClientState.disconnected;
      _settings.connectClientOnStartup = false;
      _settings.saveToDisk();
      _connectCancelled = false;
    }
  }

  /// Aborts an in-progress connection attempt started via [connect]. The
  /// pending attempt then fails fast and is reported as cancelled rather than
  /// as an error.
  void cancelConnect() {
    _connectCancelled = true;
    _connection.cancelConnect();
  }

  bool _pinging =
      false; //to not restart this ping sub process, if one is running

  /// Bumped whenever a connection starts or ends. A scheduled ping captures the
  /// value it was created under and drops out if it no longer matches, so a
  /// pending [Future.delayed] left over from a previous connection cannot
  /// attach itself to the next one.
  ///
  /// Without this, resuming from background produces two concurrent ping chains
  /// on one socket: the thawed chain from the old connection plus the one
  /// started by reconnect-on-resume. Beyond the doubled traffic, the two race
  /// on [_serverResponsive] — one clears it, the other's pong sets it — which
  /// makes the unresponsive-server watchdog unable to fire correctly at all.
  int _pingGeneration = 0;

  void _sendPing(int session) {
    if (_connection.established() &&
        _settings.client.value == ClientState.connected &&
        session == _session &&
        !_pinging) {
      _pinging = true;
      final int generation = _pingGeneration;
      Future.delayed(const Duration(seconds: 12), () {
        if (session != _session || generation != _pingGeneration) {
          return; //belongs to a connection that has since been replaced
        }
        _pinging = false;
        // Skip the ping while backgrounded: waking the radio every 12s is
        // disproportionately expensive on battery, and the watchdog below
        // would otherwise fire on a socket the OS has frozen and force a
        // spurious "server unresponsive" disconnect. Reschedule regardless so
        // the chain is still alive when the app comes back to the foreground.
        if (_network.appInBackground) {
          _serverResponsive = true;
          _sendPing(session);
          return;
        }
        if (_serverResponsive) {
          _missedPongs = 0;
        } else {
          _missedPongs++;
          if (_missedPongs >= _maxMissedPongs) {
            disconnect(_l10n.serverUnresponsive);
            return;
          }
        }
        _communication.sendToAll("ping");
        _serverResponsive = false; //set back to true when get response
        _sendPing(session);
      });
    }
  }

  void _listen(Socket socket, int session) {
    // listen for responses from the server
    try {
      final framer = MessageFramer();
      socket.listen(
        (data) {
          if (session != _session) return;
          try {
            for (final message in framer.add(data)) {
              _serverResponsive = true;
              _handleContent(message);
            }
          } on FormatException catch (error) {
            _onListenError(error, session);
            disconnect(_l10n.clientError(error.toString()));
          }
        },
        onError: (Object error) => _onListenError(error, session),
        onDone: () => _onListenDone(socket, session),
      );
    } catch (error) {
      debugPrint(error.toString());
      //_socket?.destroy();
      _setNetworkMessage(
        _l10n.clientListenError(error.toString()),
        isError: true,
      );
      //_cleanup();
    }
  }

  void _onListenDone(Socket socket, int session) {
    if (session != _session) return;
    debugPrint('Lost connection to server.');
    if (_serverResponsive) {
      _setNetworkMessage(
        '${_network.networkMessage.value} ${_l10n.lostConnectionToServer}',
        isError: true,
      );
    }
    _connection.remove(socket);
    _cleanup(session);
  }

  void _onListenError(Object error, int session) {
    if (session != _session) return;
    debugPrint('Client error: ${error.toString()}');
    _setNetworkMessage(_l10n.clientError(error.toString()), isError: true);
  }

  void _handleContent(String message) {
    if (message.startsWith("Mismatch:")) {
      message = message.substring("Mismatch:".length);
      _setNetworkMessage(_l10n.stateMismatch);
    }

    final StateEnvelope? envelope = StateEnvelope.tryDecode(message);
    if (envelope != null) {
      final GameEvent event = GameEvent.fromJsonString(envelope.eventJson);
      debugPrint(
        'Client Receive Data, index: ${envelope.index}, event:${event.runtimeType}',
      );
      if (!_gameState.loadFromData(envelope.state)) {
        disconnect('Error: server sent an invalid game state.');
        return;
      }
      _gameState.synchronizeReceivedDescription(
        envelope.index,
        envelope.description,
      );
      // Set event before commandIndex fires so VLB callbacks see it.
      _gameState.lastEvent.value = event;
      _gameState.commandIndex.value = envelope.index;
      _gameState.updateAllUI();
      Future.delayed(
        const Duration(milliseconds: 100),
        () => _gameState.save(),
      );
    } else if (message.startsWith("Error")) {
      _setNetworkMessage(message, isError: true);
      disconnect(message);
    } else if (message.startsWith("ping")) {
      _send("pong");
    } else if (message.startsWith("pong")) {
      _serverResponsive = true;
      _missedPongs = 0;
    }
  }

  void _send(String data) {
    _communication.sendToAll(data);
  }

  void disconnect(String? message) {
    final session = ++_session;
    message ??= _l10n.clientDisconnected;
    if (_connection.established()) {
      debugPrint(message);
      _setNetworkMessage(message, isError: true);
      _connection.removeAll();
      _settings.connectClientOnStartup = false;
      _settings.saveToDisk();
      _cleanup(session);
    } else {
      _cleanup(session);
    }
  }

  void _cleanup(int session) {
    if (session != _session) return;
    _settings.client.value = ClientState.disconnected;
    _gameState.resetCommandHistory();
    _pinging = false;
    _pingGeneration++;
    _missedPongs = 0;

    if (_network.appInBackground) {
      _network.clientDisconnectedWhileInBackground = true;
    }
    _serverResponsive = true;
  }
}
