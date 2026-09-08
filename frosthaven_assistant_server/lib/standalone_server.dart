import 'dart:io';

import 'package:frosthaven_assistant_server/connection_health.dart';
import 'package:frosthaven_assistant_server/game_server.dart';
import 'package:frosthaven_assistant_server/message_framer.dart';
import 'package:frosthaven_assistant_server/server_state.dart';

class StandaloneServer extends GameServer {
  final List<Socket> _clientConnections = List.empty(growable: true);
  final ServerState _state = ServerState();
  final Map<Socket, ConnectionHealth> _connectionHealth = {};
  int pingCount = 0;
  bool _pinging =
      false; //to not restart this ping sub process, if one is running

  static const String _noEventJson = '{"type":"none"}';

  /// Exposed for host diagnostics and regression tests. Both collections must
  /// shrink together when a connection is removed.
  int get activeConnectionCount => _clientConnections.length;
  int get retainedConnectionHealthCount => _connectionHealth.length;

  String _lastSavedState() {
    return _state.currentState;
  }

  @override
  void addClientConnection(Socket client) {
    print("Add client connection ${safeGetClientAddress(client)}");
    if (_clientConnections.contains(client)) return;
    _connectionHealth[client] = ConnectionHealth();
    _clientConnections.add(client);
  }

  @override
  String currentStateMessage(String commandDescription) {
    return GameServer.encodeStateEnvelope(
      index: _state.commandIndex,
      description: commandDescription,
      eventJson: _noEventJson,
      state: _lastSavedState(),
    );
  }

  @override
  Future<String> getConnectToIP() async {
    for (var interface in await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    )) {
      for (var address in interface.addresses) {
        if (!address.isLoopback && !address.isLinkLocal) return address.address;
      }
    }
    return "0.0.0.0";
  }

  @override
  void redoState() {
    String message = _state.redoState();
    if (message.isNotEmpty) {
      send(message);
    }
  }

  @override
  void rollbackState(int index) {
    final message = _state.rollbackState(index);
    if (message.isNotEmpty) send(message);
  }

  @override
  void removeAllClientConnections() {
    print("Remove all Client Connections");
    for (final client in List<Socket>.of(_clientConnections)) {
      _removeConnection(client);
    }
  }

  @override
  void removeClientConnection(Socket client) {
    print("Remove client connection ${safeGetClientAddress(client)}");
    _removeConnection(client);
  }

  /// Closes and forgets a socket once. It is safe for `onDone`, a failed
  /// broadcast and stopServer to race over the same connection.
  void _removeConnection(Socket client) {
    final wasTracked = _clientConnections.remove(client);
    final health = _connectionHealth.remove(client);
    if (!wasTracked && health == null) return;
    print(
      "Close Connection ${safeGetClientAddress(client)} $health",
    );
    try {
      client.close();
    } catch (exception) {
      print("Client already closed");
    }
  }

  @override
  void resetState() {
    _state.resetState();
    _pinging = false;
  }

  @override
  void sendInitResponse(Socket client) {
    String commandDescription = "";
    if (_state.commandIndex >= 0 &&
        _state.commandIndex >= _state.firstRetainedIndex) {
      commandDescription = _state.currentDescription;
    }
    print(
      'Server sends init response at index ${_state.commandIndex}: $commandDescription',
    );
    sendToOnly(
      GameServer.encodeStateEnvelope(
        index: _state.commandIndex,
        description: commandDescription,
        eventJson: _noEventJson,
        state: _lastSavedState(),
      ),
      client,
    );
  }

  @override
  void send(String data) {
    final message = MessageFramer.encode(data);
    for (final client in List<Socket>.of(_clientConnections)) {
      _writeToClient(client, message);
    }
  }

  @override
  void sendToOnly(String data, Socket client) {
    final message = MessageFramer.encode(data);
    _writeToClient(client, message);
  }

  @override
  void sendToOthers(String data, Socket client) {
    final message = MessageFramer.encode(data);
    for (final clientConnection in List<Socket>.of(_clientConnections)) {
      try {
        if (client.remoteAddress != clientConnection.remoteAddress ||
            clientConnection.remotePort != client.remotePort) {
          _writeToClient(clientConnection, message);
        }
      } catch (exception) {
        print("Attempted to access properties on a closed client $exception");
      }
    }
  }

  void _writeToClient(Socket client, List<int> message) {
    try {
      _connectionHealth[client]?.logMessageSent();
      client.add(message);
    } catch (error) {
      print(error);
      _removeConnection(client);
    }
  }

  @override
  void setNetworkMessage(String data) {
    print(data);
  }

  @override
  void undoState() {
    String message = _state.undoState();
    if (message.isNotEmpty) {
      send(message);
    } else {
      setNetworkMessage("Unable to undo command");
    }
  }

  @override
  void updateStateFromMessage(StateUpdateMessage message, Socket client) {
    if (message.index > _state.commandIndex + 1) {
      //invalid: index too high. send correction to clients
      String commandDescription = "";
      commandDescription = _state.currentDescription;
      send(
        GameServer.encodeStateEnvelope(
          index: _state.commandIndex,
          description: commandDescription,
          eventJson: _noEventJson,
          state: _lastSavedState(),
        ),
      );
    } else if (message.index == _state.commandIndex + 1) {
      _state.acceptUpdate(message.index, message.description, message.data);
      sendToOthers(
        GameServer.encodeStateEnvelope(
          index: _state.commandIndex,
          description: _state.currentDescription,
          eventJson: message.eventJson,
          state: _lastSavedState(),
        ),
        client,
      );
    } else {
      print(
        'Got same or lower index. ignoring: received index: ${message.indexString} current index ${_state.commandIndex}',
      );

      //overwrite client state with current server state.
      final idx = _state.commandIndex;
      final mismatchDesc = _state.currentDescription;
      sendToOnly(
        "Mismatch:${GameServer.encodeStateEnvelope(index: idx, description: mismatchDesc, eventJson: _noEventJson, state: _lastSavedState())}",
        client,
      );
      //ignore if same index from server
    }
  }

  @override
  void sendPing() {
    if (serverSocket != null && serverEnabled && !_pinging) {
      _pinging = true;
      Future.delayed(const Duration(seconds: 5), () {
        if (serverSocket == null || !serverEnabled) {
          _pinging = false;
          return;
        }
        send("ping");
        for (final client in List<Socket>.of(_clientConnections)) {
          _connectionHealth[client]?.logPing();
        }
        pingCount++;
        if (pingCount % 30 == 0) {
          printHealthReport();
        }
        _pinging = false;
        sendPing();
      });
    }
  }

  @override
  void handlePongMessage(Socket client) {
    super.handlePongMessage(client);
    _connectionHealth[client]?.logPong();
  }

  @override
  void processMessages(String message, Socket client) {
    _connectionHealth[client]?.logMessageReceived();
    super.processMessages(message, client);
  }

  void printHealthReport() {
    print("=======================================");
    print("|           HEALTH REPORT             |");
    print("=======================================");
    print("ACTIVE CONNNECTIONS: ${_clientConnections.length}");
    for (Socket client in _clientConnections) {
      print(
        "Client ${safeGetClientAddress(client)} ${_connectionHealth[client]}",
      );
    }
    print("");
    print("TOTAL CONNECTIONS: ${_connectionHealth.keys.length}");
    print("HEALTH DATA: ");
    for (ConnectionHealth data in _connectionHealth.values) {
      print(data);
    }
  }

  @override
  String safeGetClientAddress(Socket client) {
    try {
      return "Client ${client.remoteAddress}:${client.remotePort}";
    } catch (exception) {
      return "Closed client: ";
    }
  }
}
