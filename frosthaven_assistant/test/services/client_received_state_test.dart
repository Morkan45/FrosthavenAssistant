import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/network/client.dart';
import 'package:frosthaven_assistant/services/network/communication.dart';
import 'package:frosthaven_assistant/services/network/network.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';
import 'package:frosthaven_assistant_server/message_framer.dart';
import 'package:mockito/mockito.dart';

import '../command/test_helpers.dart';
import 'client_test.mocks.dart';

// Delivers framed bytes synchronously, so a test cannot accidentally fix a
// delayed snapshot by waiting for the socket or advancing the fake clock.
class _InputSocket extends Fake implements Socket {
  final input = StreamController<Uint8List>(sync: true);

  @override
  InternetAddress get remoteAddress => InternetAddress.loopbackIPv4;
  @override
  int get remotePort => 4567;
  @override
  void destroy() {}

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => input.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  void deliver(String message) => input.add(MessageFramer.encode(message));
}

void main() {
  late String baseline;
  late GameState state;

  setUpAll(() async {
    await setUpGame();
    state = getIt<GameState>();
    AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
    baseline = state.toString();
  });

  setUp(() {
    expect(state.loadFromData(baseline), isTrue);
    state.resetCommandHistory();
    state.save();
  });

  String snapshot(int level) {
    final data = jsonDecode(baseline) as Map<String, dynamic>;
    data['level'] = level;
    return jsonEncode(data);
  }

  String envelope(int index, String data) => StateEnvelope(
    index: index,
    description: 'remote $index',
    eventJson: '{"type":"none"}',
    state: data,
  ).encode();

  void withConnectedClient(
    void Function(FakeAsync, Client, _InputSocket) verifyState,
  ) {
    final connection = MockConnection();
    final communication = MockCommunication();
    final network = MockNetwork();
    final settings = getIt<Settings>()..lastKnownPort = '4567';
    final socket = _InputSocket();
    when(connection.established()).thenReturn(false); // no ping timer needed
    when(connection.connect(any, any)).thenAnswer((_) async => socket);
    when(network.networkMessage).thenReturn(ValueNotifier<String>(''));
    when(network.networkMessageIsError).thenReturn(ValueNotifier<bool>(false));
    when(network.appInBackground).thenReturn(false);
    final client = Client(
      gameState: state,
      communication: communication,
      connection: connection,
      network: network,
      settings: settings,
    );

    fakeAsync((async) {
      client.connect('127.0.0.1');
      async.flushMicrotasks();
      expect(settings.client.value, ClientState.connected);
      verifyState(async, client, socket);
      client.disconnect('test completed');
      socket.input.close();
      async.flushMicrotasks();
    });
  }

  test('two envelopes in one clock tick retain two distinct snapshots', () {
    withConnectedClient((async, client, socket) {
      final first = snapshot(2);
      final second = snapshot(3);
      socket.deliver(envelope(0, first));
      socket.deliver(envelope(1, second));

      expect(async.elapsed, Duration.zero);
      expect(state.commandIndex.value, 1);
      expect(state.snapshotAt(0)?.getState(), first);
      expect(state.snapshotAt(1)?.getState(), second);
      expect(state.historyEntryAt(0)?.snapshot, isNotNull);
      expect(state.historyEntryAt(1)?.snapshot, isNotNull);
    });
  });

  test('disconnect leaves no delayed snapshot that can overwrite a reset', () {
    withConnectedClient((async, client, socket) {
      socket.deliver(envelope(0, snapshot(2)));
      client.disconnect('reset');
      final resetSnapshot = state.currentSnapshot;
      expect(state.loadFromData(snapshot(5)), isTrue);

      async.elapse(const Duration(milliseconds: 150));

      expect(state.commandIndex.value, -1);
      expect(state.currentSnapshot, same(resetSnapshot));
      expect(state.currentSnapshot?.getState(), snapshot(2));
    });
  });

  test('late invalid state preserves model identity and accepted history', () {
    withConnectedClient((async, client, socket) {
      socket.deliver(envelope(0, snapshot(2)));
      final figure = state.currentList.first;
      final before = state.toString();
      final acceptedSnapshot = state.currentSnapshot;
      final invalid = jsonDecode(snapshot(5)) as Map<String, dynamic>;
      invalid['currentList'] = [];
      invalid['elementState'] = 'not an element map';

      socket.deliver(envelope(1, jsonEncode(invalid)));

      expect(state.toString(), before);
      expect(state.currentList.first, same(figure));
      expect(state.commandIndex.value, 0);
      expect(state.currentSnapshot, same(acceptedSnapshot));
      expect(state.descriptionAt(0), 'remote 0');
      expect(state.snapshotAt(1), isNull);
    });
  });

  test('host rollback retains redo but mismatch discards the stale future', () {
    withConnectedClient((async, client, socket) {
      socket.deliver(envelope(0, snapshot(2)));
      socket.deliver(envelope(1, snapshot(3)));
      socket.deliver(envelope(0, snapshot(2)));
      expect(state.snapshotAt(1)?.getState(), snapshot(3));
      expect(state.canRedo, isTrue);

      socket.deliver('Mismatch:${envelope(0, snapshot(4))}');
      expect(state.currentSnapshot?.getState(), snapshot(4));
      expect(state.snapshotAt(1), isNull);
      expect(state.descriptionAt(1), isNull);
      expect(state.canRedo, isFalse);

      socket.deliver(envelope(1, snapshot(5)));
      expect(state.snapshotAt(0)?.getState(), snapshot(4));
      expect(state.snapshotAt(1)?.getState(), snapshot(5));
    });
  });
}
