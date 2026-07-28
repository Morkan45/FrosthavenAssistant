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

  String _lastSavedState() {
    return _state.gameSaveStates.isNotEmpty
        ? _state.gameSaveStates.last.getState()
        : "{}";
  }

  @override
  void addClientConnection(Socket client) {
    print("Add client connection ${safeGetClientAddress(client)}");
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
  void removeAllClientConnections() {
    print("Remove all Client Connections");
    for (var client in _clientConnections) {
      print(
        "Close Connection ${safeGetClientAddress(client)} ${_connectionHealth[client]}",
      );
      try {
        client.close();
      } catch (exception) {
        print("Client already closed");
      }
    }
    _clientConnections.clear();
  }

  @override
  void removeClientConnection(Socket client) {
    print("Remove client connection ${safeGetClientAddress(client)}");
    print(
      "Close Connection ${safeGetClientAddress(client)} ${_connectionHealth[client]}",
    );
    try {
      client.close();
    } catch (exception) {
      print("Client already closed");
    }
    _clientConnections.remove(client);
  }

  @override
  void resetState() {
    _state.commandIndex = -1;
    _state.commands.clear();
    _state.commandDescriptions.clear();
    if (_state.gameSaveStates.isNotEmpty) {
      _state.gameSaveStates.removeRange(0, _state.gameSaveStates.length - 1);
    }
    _pinging = false;
  }

  @override
  void sendInitResponse(Socket client) {
    String commandDescription = "";
    if (_state.commandIndex > 0 &&
        _state.commandDescriptions.length > _state.commandIndex) {
      commandDescription = _state.commandDescriptions[_state.commandIndex];
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
    for (Socket client in _clientConnections) {
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
    for (Socket clientConnection in _clientConnections) {
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
    if (message.index > _state.commandDescriptions.length) {
      //invalid: index too high. send correction to clients
      String commandDescription = "";
      if (_state.commandDescriptions.isNotEmpty) {
        commandDescription = _state.commandDescriptions.last;
      }
      send(
        GameServer.encodeStateEnvelope(
          index: _state.commandIndex,
          description: commandDescription,
          eventJson: _noEventJson,
          state: _lastSavedState(),
        ),
      );
    } else if (message.index > _state.commandIndex) {
      _state.acceptUpdate(message.index, message.description, message.data);
      sendToOthers(
        GameServer.encodeStateEnvelope(
          index: _state.commandIndex,
          description: _state.commandDescriptions.last,
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
      final mismatchDesc = (idx >= 0 && idx < _state.commandDescriptions.length)
          ? _state.commandDescriptions[idx]
          : '';
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
        for (Socket client in _clientConnections) {
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
