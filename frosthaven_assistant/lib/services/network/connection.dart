import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:format/format.dart';

class Connection {
  static const Duration _lookupTimeout = Duration(seconds: 5);
  static const Duration _connectTimeout = Duration(seconds: 10);

  final _sockets = <Socket>[];

  // The in-progress connection attempt, if any. Kept so that an attempt which
  // hangs (e.g. wrong IP, server down) can be aborted by the user instead of
  // running indefinitely.
  ConnectionTask<Socket>? _pendingConnectionTask;

  List<Socket> getAll() {
    return _sockets;
  }

  Future<Socket> connect(String address, int port) async {
    final resolvedAddresses = await _resolveAddress(address);
    // startConnect returns a cancelable task rather than awaiting the socket
    // directly, so an in-progress attempt can be aborted via cancelConnect().
    final task = await Socket.startConnect(resolvedAddresses.first, port);
    _pendingConnectionTask = task;
    try {
      final socket = await task.socket.timeout(
        _connectTimeout,
        onTimeout: () {
          task.cancel();
          throw TimeoutException(
              'Connection attempt timed out', _connectTimeout);
        },
      );
      add(socket);

      return socket;
    } finally {
      _pendingConnectionTask = null;
    }
  }

  /// Aborts an in-progress [connect] attempt, if one is pending. Safe to call
  /// when nothing is connecting. The pending [connect] future then completes
  /// with an error once the underlying socket attempt is torn down.
  void cancelConnect() {
    _pendingConnectionTask?.cancel();
    _pendingConnectionTask = null;
  }

  void add(Socket socket) {
    _cleanUpClosedConnections();
    if (!_isClosed(socket)) {
      final existingConnections = _find(socket);
      _destroy(existingConnections);
      socket.setOption(SocketOption.tcpNoDelay, true);
      socket.encoding = utf8;
      _sockets.add(socket);
    }
  }

  void removeAll() {
    _destroy(_sockets);
  }

  void remove(Socket socket) {
    _cleanUpClosedConnections();
    if (!_isClosed(socket)) {
      final toDisconnect = _find(socket);
      _destroy(toDisconnect);
    }
  }

  bool established() {
    return _sockets.isNotEmpty;
  }

  Future<List<InternetAddress>> _resolveAddress(String address) async {
    List<InternetAddress> resolvedAddresses =
        await InternetAddress.lookup(address).timeout(_lookupTimeout);
    if (resolvedAddresses.isEmpty) {
      throw Exception("Unable to resolve host");
    }

    return resolvedAddresses;
  }

  /// Returns all live sockets that match [socket] by remote address and port.
  ///
  /// Closed sockets are silently skipped — accessing `remoteAddress` on a
  /// remotely-closed socket throws [SocketException].  Results are eagerly
  /// materialised into a [List] so that [_destroy] can safely mutate
  /// [_sockets] while iterating the returned collection.
  List<Socket> _find(Socket socket) {
    if (_isClosed(socket)) return const [];
    return _sockets.where((x) {
      if (_isClosed(x)) return false;
      try {
        return x.remoteAddress == socket.remoteAddress &&
            x.remotePort == socket.remotePort;
      } on SocketException catch (_) {
        return false;
      } on OSError catch (_) {
        return false;
      }
    }).toList();
  }

  void _destroy(Iterable<Socket> sockets) {
    // Copy to a list first: callers like removeAll() pass _sockets directly,
    // so mutating it inside the loop would cause concurrent-modification errors.
    for (final socket in List.of(sockets)) {
      socket.destroy();
      _sockets.remove(socket);
    }
  }

  // Check if socket was remotely closed, thus address and port are not accessible
  bool _isClosed(Socket socket) {
    try {
      socket.remoteAddress;
      socket.remotePort;
      return false;
    } on SocketException catch (_) {
      return true;
    } catch (e) {
      // Close the socket, as something is completely wrong with it
      log('Unexpected exception in determining socket closure: \'{}\''
          .format(e.toString()));

      return true;
    }
  }

  void _cleanUpClosedConnections() {
    final toDisconnect = _sockets.where((x) => _isClosed(x));
    while (toDisconnect.isNotEmpty) {
      final socket = toDisconnect.first;
      socket.destroy();
      _sockets.remove(socket);
    }
  }
}
