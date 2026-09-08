import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/view_models/main_menu_view_model.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/network/client.dart';
import 'package:frosthaven_assistant/services/network/network.dart';
import 'package:frosthaven_assistant/services/network/network_info.dart';
import 'package:frosthaven_assistant/services/network/server.dart';

class _Game extends Fake implements GameState {
  bool fails = false;
  int saves = 0;
  @override
  Future<void> saveAndFlush() async {
    saves++;
    if (fails) throw StateError('Disk full');
  }
}

class _Client extends Fake implements Client {
  int starts = 0;
  int stops = 0;
  @override
  Future<void> connect(String address) async {
    starts++;
  }

  @override
  void disconnect(String? message, {bool preserveHistory = false}) {
    stops++;
  }
}

class _Server extends Fake implements Server {
  int starts = 0;
  int stops = 0;
  @override
  void startServer() {
    starts++;
  }

  @override
  void stopServer(String? message) {
    stops++;
  }
}

class _Info extends Fake implements NetworkInformation {
  @override
  final wifiIPv6 = ValueNotifier<String>('192.168.1.2');
}

class _Network extends Fake implements Network {
  @override
  final _Server server = _Server();
  @override
  final _Info networkInfo = _Info();
  @override
  final roleChangePending = ValueNotifier<bool>(false);
}

void main() {
  for (final host in [false, true]) {
    test(
      '${host ? 'host' : 'client'} starts only after settings are durable',
      () async {
        final persisted = Completer<void>();
        final game = _Game();
        final settings = Settings(writer: (_) => persisted.future);
        final client = _Client();
        final network = _Network();
        final vm = MainMenuViewModel(
          gameState: game,
          settings: settings,
          client: client,
          network: network,
        );
        final started = host
            ? vm.toggleServer(port: '5555')
            : vm.toggleClientConnection(address: 'new', port: '5555');
        await Future<void>.delayed(Duration.zero);
        expect(game.saves, 1);
        expect(client.starts + network.server.starts, 0);
        persisted.complete();
        await started;
        expect(client.starts + network.server.starts, 1);
        expect(settings.lastKnownPort, '5555');
      },
    );
    test(
      '${host ? 'host' : 'client'} ignores a second start while saving',
      () async {
        final persisted = Completer<void>();
        final game = _Game();
        final settings = Settings(writer: (_) => persisted.future);
        final client = _Client();
        final network = _Network();
        final first = MainMenuViewModel(
          gameState: game,
          settings: settings,
          client: client,
          network: network,
        );
        final second = MainMenuViewModel(
          gameState: game,
          settings: settings,
          client: client,
          network: network,
        );
        final firstStart = host
            ? first.toggleServer(port: '5555')
            : first.toggleClientConnection(address: 'new', port: '5555');
        await Future<void>.delayed(Duration.zero);
        await (host
            ? second.toggleServer(port: '5555')
            : second.toggleClientConnection(address: 'new', port: '5555'));
        expect(game.saves, 1);
        persisted.complete();
        await firstStart;
        expect(client.starts + network.server.starts, 1);
      },
    );
    test(
      '${host ? 'host' : 'client'} start is blocked by game save failure',
      () async {
        final game = _Game()..fails = true;
        var settingsWrites = 0;
        final settings = Settings(
          writer: (_) async {
            settingsWrites++;
          },
        );
        final client = _Client();
        final network = _Network();
        final vm = MainMenuViewModel(
          gameState: game,
          settings: settings,
          client: client,
          network: network,
        );
        await expectLater(
          host
              ? vm.toggleServer(port: '5555')
              : vm.toggleClientConnection(address: 'new', port: '5555'),
          throwsStateError,
        );
        expect(settingsWrites, 0);
        expect(settings.lastKnownPort, '4567');
        expect(settings.client.value, ClientState.disconnected);
        expect(client.starts + network.server.starts, 0);
      },
    );

    test(
      '${host ? 'host' : 'client'} start restores settings on storage failure',
      () async {
        final game = _Game();
        final settings = Settings(
          writer: (_) async {
            throw StateError('Disk full');
          },
        );
        final client = _Client();
        final network = _Network();
        final vm = MainMenuViewModel(
          gameState: game,
          settings: settings,
          client: client,
          network: network,
        );
        await expectLater(
          host
              ? vm.toggleServer(port: '5555')
              : vm.toggleClientConnection(address: 'new', port: '5555'),
          throwsStateError,
        );
        expect(settings.lastKnownPort, '4567');
        expect(settings.lastKnownConnection, '192.168.1.???');
        expect(settings.lastKnownHostIP, '');
        expect(settings.client.value, ClientState.disconnected);
        expect(client.starts + network.server.starts, 0);
      },
    );

    test(
      '${host ? 'host' : 'client'} can stop despite unavailable storage',
      () async {
        final game = _Game()..fails = true;
        final settings = Settings(
          writer: (_) async {
            throw StateError('Disk full');
          },
        );
        final client = _Client();
        final network = _Network();
        settings.server.value = host;
        settings.client.value = host
            ? ClientState.disconnected
            : ClientState.connected;
        final vm = MainMenuViewModel(
          gameState: game,
          settings: settings,
          client: client,
          network: network,
        );
        await (host ? vm.toggleServer() : vm.toggleClientConnection());
        expect(client.stops + network.server.stops, 1);
        expect(game.saves, 0);
      },
    );
  }
}
