import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:frosthaven_assistant_server/message_framer.dart';
import 'package:frosthaven_assistant_server/state_envelope.dart';

class StateUpdateMessage {
  String indexString = "";
  String description = "";
  String eventJson = '{"type":"none"}';
  String data = "";
  int index = 0;
}

abstract class GameServer {
  /// Wire-protocol version. Increment this ONLY when the message format itself
  /// changes (e.g. envelope fields added/removed). Game-data additions (new
  /// classes, campaigns) must NOT bump this number.
  static const int protocolVersion = 3;

  // Sockets rejected for version mismatch.  Checked in onDone so that
  // "Client left." does not overwrite the rejection message.
  final Set<Socket> _rejectedClients = {};
  final Set<Socket> _initializedClients = {};

  ServerSocket? _serverSocket;
  // ignore: unnecessary_getters_setters, subclasses depend on this override point.
  ServerSocket? get serverSocket {
    return _serverSocket;
  }

  set serverSocket(ServerSocket? value) {
    _serverSocket = value;
  }

  bool _serverEnabled = false;
  // ignore: unnecessary_getters_setters, app and standalone servers override this state.
  bool get serverEnabled {
    return _serverEnabled;
  }

  set serverEnabled(bool value) {
    _serverEnabled = value;
  }

  void resetState();
  void undoState();
  void redoState();
  void rollbackState(int index);
  void updateStateFromMessage(StateUpdateMessage message, Socket client);

  void setNetworkMessage(String data);
  void send(String data);
  String currentStateMessage(String commandDescription);
  Future<String> getConnectToIP();

  void sendPing();
  void addClientConnection(Socket client);
  void removeClientConnection(Socket client);
  void removeAllClientConnections();
  void sendToOnly(String data, Socket client);
  void sendToOthers(String data, Socket client);
  void sendInitResponse(Socket client);

  /// Encodes a state message as a JSON envelope.
  ///
  /// [eventJson] must be a valid JSON string (e.g. `'{"type":"none"}'`).
  static String encodeStateEnvelope({
    required int index,
    required String description,
    required String eventJson,
    required String state,
  }) {
    return StateEnvelope(
      index: index,
      description: description,
      eventJson: eventJson,
      state: state,
    ).encode();
  }

  /// Tries to decode [content] as a JSON envelope.
  /// Returns `null` if it is not in the new format.
  static StateUpdateMessage? tryDecodeStateEnvelope(String content) {
    final envelope = StateEnvelope.tryDecode(content);
    if (envelope == null) return null;
    try {
      final result = StateUpdateMessage();
      result.index = envelope.index;
      result.indexString = result.index.toString();
      result.description = envelope.description;
      result.eventJson = envelope.eventJson;
      result.data = envelope.state;
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> startServerInternal(String ip, int port) async {
    try {
      serverSocket = await ServerSocket.bind(ip, port);
      serverEnabled = true;
      final ServerSocket server = serverSocket!;
      String connectTo = await getConnectToIP();
      String info =
          'Server Online: IP: $connectTo, Port: ${server.port.toString()}';
      log(info);
      setNetworkMessage(info);
      resetState();
      send(currentStateMessage(""));
      var subscriptions = server.listen(
        (Socket client) {
          handleConnection(client);
        },
        onError: (e) {
          log('Server error: $e');
          setNetworkMessage('Server error: ${e.toString()}');
        },
      );
      sendPing();
      await subscriptions.asFuture();
    } catch (error) {
      log('Server error: $error');
      setNetworkMessage('Server error: ${error.toString()}');
    }
  }

  void stopServer(String? error) {
    if (serverSocket != null) {
      log('Server Offline');
      if (error != null) {
        setNetworkMessage(error);
      } else {
        setNetworkMessage('Server Offline');
      }

      serverSocket!.close().catchError((error) {
        log(error.toString());
        return error;
      });

      removeAllClientConnections();
    }
    serverEnabled = false;
    resetState();
  }

  void logHandleConnection(Socket client) {
    String info = 'Connection from ${safeGetClientAddress(client)}';
    log(info);
    setNetworkMessage(info);
  }

  void handleConnection(Socket client) {
    try {
      client.setOption(SocketOption.tcpNoDelay, true);
    } on SocketException catch (e) {
      // Client disconnected between accept() and handleConnection — socket is
      // already invalid. Destroy it and skip setup.
      log('Client disconnected before setup (errno 22): $e');
      client.destroy();
      return;
    } on OSError catch (e) {
      // Same as above but surfaced as OSError on iOS/macOS.
      log('Client disconnected before setup (OSError): $e');
      client.destroy();
      return;
    }
    client.encoding = utf8;

    logHandleConnection(client);

    addClientConnection(client);

    // Per-connection leftover buffer — avoids the shared-field bug where
    // messages from different clients could corrupt each other's partial frames.
    final framer = MessageFramer();

    // listen for events from the client
    try {
      client.listen(
        // handle data from the client
        (Uint8List data) {
          try {
            for (final message in framer.add(data)) {
              processMessages(message, client);
            }
          } on FormatException catch (e) {
            log('Invalid frame from client: $e');
            sendToOnly('Error: malformed network message.', client);
            _rejectedClients.add(client);
            removeClientConnection(client);
          }
        },
        // handle errors
        onError: (error) {
          // errno 103 (ECONNABORTED): the OS killed this client's socket
          // (app backgrounded, screen locked, network switch). Treat it the
          // same as a clean disconnect — remove only this client and keep the
          // server running for everyone else.
          final int? errno = error is SocketException
              ? error.osError?.errorCode
              : error is OSError
                  ? error.errorCode
                  : null;
          if (errno == 103) {
            log(
              'Client aborted connection (errno 103): ${safeGetClientAddress(client)}',
            );
            removeClientConnection(client);
            _initializedClients.remove(client);
            setNetworkMessage('Client left.');
          } else {
            log(error.toString());
            setNetworkMessage(error.toString());
          }
        },
        // handle the client closing the connection
        onDone: () {
          if (serverEnabled) {
            removeClientConnection(client);
            _initializedClients.remove(client);
            if (_rejectedClients.remove(client)) {
              log('Rejected old-version client disconnected');
            } else {
              log('Client left');
              setNetworkMessage('Client left.');
            }
          }
        },
      );
    } catch (error) {
      log(error.toString());
      setNetworkMessage(error.toString());
    }
  }

  /// Dispatches a single fully-decoded, unframed message content to the
  /// appropriate handler. Byte framing is done by
  /// [handleConnection] before calling this method.
  void processMessages(String message, Socket client) {
    if (message.startsWith("init")) {
      handleInitMessage(message, client);
      return;
    }
    if (!_initializedClients.contains(client)) {
      sendToOnly(
        'Error: initialize the connection before sending commands.',
        client,
      );
      _rejectedClients.add(client);
      removeClientConnection(client);
      return;
    }
    if (message.startsWith("{")) {
      handleIndexMessage(message, client);
    } else if (message.startsWith("undo")) {
      handleUndoMessage();
    } else if (message.startsWith("redo")) {
      handleRedoMessage();
    } else if (message.startsWith("rollback:")) {
      final index = int.tryParse(message.substring('rollback:'.length));
      if (index != null) handleRollbackMessage(index);
    } else if (message.startsWith("pong")) {
      handlePongMessage(client);
    } else if (message.startsWith("ping")) {
      handlePingMessage(client);
    }
  }

  void handleIndexMessage(String message, Socket client) {
    final StateUpdateMessage? parsed = tryDecodeStateEnvelope(message);
    if (parsed == null) {
      log(
        'Received malformed state message from ${safeGetClientAddress(client)}, ignoring.',
      );
      return;
    }
    updateStateFromMessage(parsed, client);
  }

  void handleInitMessage(String message, Socket client) {
    // Old clients (≤v1.13.7) send "init version:NNNN" — give a friendly
    // rejection rather than a confusing "malformed" error, then close the socket.
    if (message.contains("version:") && !message.contains("protocolVersion:")) {
      setNetworkMessage(
        "Old client attempted to connect. Please update the app.",
      );
      sendToOnly(
        "Error: Your app is outdated. Please update to connect.",
        client,
      );
      _rejectedClients.add(client);
      removeClientConnection(client);
      return;
    }
    List<String> initMessageParts = message.split("protocolVersion:");
    if (initMessageParts.length < 2) {
      sendToOnly(
        "Error: malformed init message (missing protocolVersion field).",
        client,
      );
      _rejectedClients.add(client);
      removeClientConnection(client);
      return;
    }
    final int? version = int.tryParse(initMessageParts[1]);
    if (version == null) {
      sendToOnly(
        "Error: malformed init message (non-integer protocolVersion).",
        client,
      );
      _rejectedClients.add(client);
      removeClientConnection(client);
      return;
    }
    if (version != protocolVersion) {
      setNetworkMessage(
        "Protocol version mismatch. Client $version, server $protocolVersion. Please update.",
      );
      sendToOnly(
        "Error: Protocol version mismatch. Client $version, server $protocolVersion. Please update.",
        client,
      );
      _rejectedClients.add(client);
      removeClientConnection(client);
    } else {
      _initializedClients.add(client);
      sendInitResponse(client);
    }
  }

  void handleUndoMessage() {
    log('Server Receive undo command');
    undoState();
  }

  void handleRedoMessage() {
    log('Server Receive redo command');
    redoState();
  }

  void handleRollbackMessage(int index) {
    log('Server Receive rollback command to index $index');
    rollbackState(index);
  }

  void handlePongMessage(Socket client) {
    log('pong from ${safeGetClientAddress(client)}');
  }

  void handlePingMessage(Socket client) {
    log('ping from ${safeGetClientAddress(client)}');
    sendToOnly("pong", client);
  }

  String safeGetClientAddress(Socket client) {
    try {
      return "${client.remoteAddress}:${client.remotePort}";
    } catch (exception) {
      log("Encountered error accessing client");
      log(exception.toString());
      // There might be a chance that is is for a different
      // reason, but this is the most common reason I've
      // seen so far
      return "Closed socket";
    }
  }
}
