// ignore_for_file: missing-test-assertion

import 'dart:async';
import 'dart:io';

import 'package:fluent_assertions/fluent_assertions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/network/client.dart';
import 'package:frosthaven_assistant/services/network/communication.dart';
import 'package:frosthaven_assistant/services/network/connection.dart';
import 'package:frosthaven_assistant/services/network/network.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'client_test.mocks.dart';
import 'communication_test.mocks.dart' show MockSocket;

Client _sut = Client();
final _getIt = GetIt.instance;
const _address = '127.0.0.1';

@GenerateNiceMocks([
  MockSpec<Communication>(),
  MockSpec<Connection>(),
  MockSpec<Network>(),
  MockSpec<Settings>(),
  MockSpec<ValueNotifier<String>>(as: Symbol('MockValueNotifierString')),
  MockSpec<ValueNotifier<ClientState>>(
    as: Symbol('MockValueNotifierClientState'),
  ),
])
final _connection = MockConnection();
final _gameState = GameState(communication: _communication);
final _communication = MockCommunication();
final _network = MockNetwork();
final _settings = MockSettings();
final _valueNotifierString = MockValueNotifierString();
final _valueNotifierClientState = MockValueNotifierClientState();

List<String> _log = [];

void main() {
  setUpAll(() {
    when(_settings.lastKnownPort).thenReturn('0000');
    when(_settings.locale).thenReturn(ValueNotifier<String>('en'));
    when(_network.networkMessage).thenReturn(ValueNotifier<String>(''));
    when(_network.networkMessageIsError).thenReturn(ValueNotifier<bool>(false));
    _getIt.registerFactory<Connection>(() => _connection);
    _getIt.registerFactory<GameState>(() => _gameState);
    _getIt.registerFactory<Communication>(() => _communication);
    _getIt.registerFactory<Network>(() => _network);
    _getIt.registerFactory<Settings>(() => _settings);
  });

  test(
    'connect creates client connection with server',
    _overridePrint(() {
      // arrange
      when(_network.networkMessage).thenReturn(_valueNotifierString);
      when(_settings.client).thenReturn(_valueNotifierClientState);

      // act
      _sut.connect(_address);

      // assert
      _log.any((element) => element.contains('port nr: 0')).shouldBeTrue();
    }),
  );

  test(
    'a stale connection attempt cannot replace the active session',
    () async {
      final connection = MockConnection();
      final communication = MockCommunication();
      final network = MockNetwork();
      final settings = Settings()..lastKnownPort = '4567';
      final socket1 = MockSocket();
      final socket2 = MockSocket();
      final first = Completer<Socket>();
      final second = Completer<Socket>();
      var attempt = 0;

      when(network.networkMessage).thenReturn(ValueNotifier<String>(''));
      when(
        network.networkMessageIsError,
      ).thenReturn(ValueNotifier<bool>(false));
      when(connection.established()).thenReturn(false);
      when(connection.connect(any, any)).thenAnswer((_) {
        attempt++;
        return attempt == 1 ? first.future : second.future;
      });
      when(socket2.remoteAddress).thenReturn(InternetAddress.loopbackIPv4);
      when(socket2.remotePort).thenReturn(4567);

      final gameState = GameState(
        communication: communication,
        settings: settings,
        network: network,
      );
      final client = Client(
        gameState: gameState,
        communication: communication,
        connection: connection,
        network: network,
        settings: settings,
      );

      final firstConnect = client.connect(_address);
      final secondConnect = client.connect(_address);
      second.complete(socket2);
      await secondConnect;
      first.complete(socket1);
      await firstConnect;

      verify(socket1.destroy()).called(1);
      verifyNever(socket2.destroy());
      expect(settings.client.value, ClientState.connected);
    },
  );
}

void Function() _overridePrint(void Function() testFn) => () {
  var spec = ZoneSpecification(
    print: (_, _, _, String msg) {
      _log.add(msg);
    },
  );
  return Zone.current.fork(specification: spec).run<void>(testFn);
};
