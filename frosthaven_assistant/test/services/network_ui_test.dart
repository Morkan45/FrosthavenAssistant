import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/services/network/communication.dart';
import 'package:frosthaven_assistant/services/network/connection.dart';
import 'package:frosthaven_assistant/services/network/network.dart';
import 'package:frosthaven_assistant/services/network/network_ui.dart';
import 'package:frosthaven_assistant/services/network/server.dart';

import '../unit_helpers.dart';

Network networkForTest() {
  final (gameState, settings) = makeGameAndSettings();
  final connection = Connection();
  return Network(
    server: Server(
      gameState: gameState,
      settings: settings,
      connection: connection,
      communication: Communication(connection: connection),
    ),
  );
}

void main() {
  testWidgets('latest network message replaces a pending toast', (
    tester,
  ) async {
    final network = networkForTest();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NetworkUI(network: network)),
      ),
    );

    network.networkMessage.value = 'first';
    await tester.pump();
    network.networkMessage.value = 'second';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(network.networkMessage.value, isEmpty);
  });

  testWidgets('disposing the UI cancels its pending message callback', (
    tester,
  ) async {
    final network = networkForTest();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NetworkUI(network: network)),
      ),
    );
    network.networkMessage.value = 'pending';
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 200));

    expect(network.networkMessage.value, 'pending');
  });
}
