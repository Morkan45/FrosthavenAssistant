import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:frosthaven_assistant_server/message_framer.dart';
export 'package:frosthaven_assistant_server/state_envelope.dart';

import '../service_locator.dart';
import 'connection.dart';

class Communication {
  final Connection _connection;

  Communication({Connection? connection})
    : _connection = connection ?? getIt<Connection>();

  // TODO: Need to test this somehow, or refactor altogether.
  // If testing, then better to verify assigned functions are being called on specific actions, rather than verify mock socket assignments.
  void listen(
    Function(Uint8List) onData,
    Function? onError,
    Function()? onDone,
  ) {
    final sockets = _connection.getAll();
    for (final socket in sockets) {
      socket.listen(onData, onError: onError, onDone: onDone);
    }
  }

  void sendToAllExcept(Socket client, String data) {
    // Snapshot the list: _writeToSocket may remove a dead socket from
    // _connection, which would corrupt iteration over the live internal list.
    final sockets = List.of(_connection.getAll());
    for (final socket in sockets) {
      // Compare both address AND port: multiple clients from the same host
      // (e.g. all on loopback in tests, or same-device multi-window) share the
      // same remoteAddress but have distinct remotePort values.
      // Accessing remoteAddress/remotePort throws SocketException if the socket
      // was closed between the snapshot and this iteration — treat it as dead.
      bool isOther;
      try {
        isOther =
            socket.remoteAddress != client.remoteAddress ||
            socket.remotePort != client.remotePort;
      } on SocketException catch (e) {
        log('Removing dead socket in sendToAllExcept: $e');
        _connection.remove(socket);
        continue;
      } on OSError catch (e) {
        log('Removing dead socket in sendToAllExcept (OSError): $e');
        _connection.remove(socket);
        continue;
      }
      if (isOther) sendTo(socket, data);
    }
  }

  void sendTo(Socket? socket, String data) {
    assert(
      socket != null,
      'sendTo called with a null socket — message dropped',
    );
    if (socket == null) {
      debugPrint('Communication.sendTo: null socket, message dropped: "$data"');
      return;
    }
    _writeToSocket(socket, _composeMessageFrom(data));
  }

  void sendToAll(String data) {
    final message = _composeMessageFrom(data);
    // Snapshot: _writeToSocket may remove a dead socket from _connection mid-loop.
    final sockets = List.of(_connection.getAll());
    for (final socket in sockets) {
      _writeToSocket(socket, message);
    }
  }

  void _writeToSocket(Socket socket, List<int> message) {
    try {
      socket.add(message);
    } on SocketException catch (e) {
      // EPIPE (errno 32) and similar write errors mean the remote end closed
      // before we noticed. Remove the dead socket so future sends skip it.
      log('Write failed, removing dead socket: $e');
      _connection.remove(socket);
    } on OSError catch (e) {
      // Same as above but surfaced as OSError on iOS/macOS.
      log('Write failed, removing dead socket (OSError): $e');
      _connection.remove(socket);
    }
  }

  String dataFrom(List<int> message) {
    try {
      final decoded = MessageFramer().add(message);
      return decoded.length == 1 ? decoded.single : '';
    } on FormatException {
      return '';
    }
  }

  bool isValid(List<int> message) => dataFrom(message).isNotEmpty;

  List<int> _composeMessageFrom(String data) => MessageFramer.encode(data);
}
