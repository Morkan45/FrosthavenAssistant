import 'dart:io';

import 'package:frosthaven_assistant_server/standalone_server.dart';
import 'package:test/test.dart';

void main() {
  test('repeated removal forgets both socket and health entry', () async {
    final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = listener.first;
    final client = await Socket.connect(listener.address, listener.port);
    final serverSide = await accepted;
    final server = StandaloneServer();

    server.addClientConnection(serverSide);
    server.addClientConnection(serverSide);
    expect(server.activeConnectionCount, 1);
    expect(server.retainedConnectionHealthCount, 1);

    server.removeClientConnection(serverSide);
    server.removeClientConnection(serverSide);
    expect(server.activeConnectionCount, 0);
    expect(server.retainedConnectionHealthCount, 0);

    await client.close();
    await listener.close();
  });

  test('remove all is idempotent and clears health entries', () async {
    final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final clients = await Future.wait([
      Socket.connect(listener.address, listener.port),
      Socket.connect(listener.address, listener.port),
    ]);
    final sockets = await listener.take(2).toList();
    final server = StandaloneServer();
    for (final socket in sockets) {
      server.addClientConnection(socket);
    }

    server.removeAllClientConnections();
    server.removeAllClientConnections();
    expect(server.activeConnectionCount, 0);
    expect(server.retainedConnectionHealthCount, 0);

    for (final client in clients) {
      await client.close();
    }
    await listener.close();
  });
}
