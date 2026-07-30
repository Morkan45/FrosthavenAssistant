// ignore_for_file: avoid_print, no-magic-number

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/MainList/main_list.dart';
import 'package:frosthaven_assistant/Resource/commands/change_stat_commands/change_health_command.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';
import 'performance_fixtures.dart';

void main() {
  late String baselineState;

  setUpAll(() async {
    await setUpGame();
    baselineState = getIt<GameState>().toString();
  });

  setUp(() async {
    final gameState = getIt<GameState>();
    await gameState.flushPersistence();
    expect(gameState.loadFromData(baselineState), isTrue);
    gameState.resetCommandHistory();

    final settings = getIt<Settings>();
    settings.userScalingMainList.value = 1;
    settings.userScalingBars.value = 1;
    settings.fitMainListToWidth.value = true;
    settings.mainListColumns.value = 0;
  });

  group('state performance budgets', () {
    for (final fixture in performanceFixtures) {
      test('${fixture.name} snapshot and action latency', () async {
        final gameState = getIt<GameState>();
        fixture.populate(gameState);

        for (var index = 0; index < 5; index++) {
          gameState.toString();
        }
        final serializationSamples = _measureSync(
          iterations: 30,
          operation: gameState.toString,
        );
        final serialized = gameState.toString();
        final snapshotBytes = utf8.encode(serialized).length;

        for (var index = 0; index < 5; index++) {
          _changeBlinkbladeHealth(gameState, index);
        }
        await gameState.flushPersistence();

        final actionSamples = _measureSync(
          iterations: 30,
          operation: () =>
              _changeBlinkbladeHealth(gameState, gameState.commandIndex.value),
        );
        await gameState.flushPersistence();

        final serializationP95 = _percentile(serializationSamples, 0.95);
        final actionP95 = _percentile(actionSamples, 0.95);
        print(
          'PERF ${fixture.name}: snapshot=$snapshotBytes bytes, '
          'serialization_p95=${serializationP95.inMicroseconds} us, '
          'action_p95=${actionP95.inMicroseconds} us',
        );

        expect(snapshotBytes, lessThan(fixture.budget.maxSnapshotBytes));
        expect(serializationP95, lessThan(fixture.budget.maxSerializationP95));
        expect(actionP95, lessThan(fixture.budget.maxActionP95));
      });
    }
  });

  group('main-list rebuild budgets', () {
    for (final fixture in performanceFixtures) {
      testWidgets('${fixture.name} 2560x1440 rebuild latency', (tester) async {
        final originalOnError = FlutterError.onError;
        FlutterError.onError = ignoreOverflowErrors(originalOnError);
        addTearDown(() async {
          FlutterError.onError = originalOnError;
          await tester.binding.setSurfaceSize(null);
        });

        final gameState = getIt<GameState>();
        fixture.populate(gameState);
        await tester.binding.setSurfaceSize(const Size(2560, 1440));
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.windows),
            home: const Scaffold(body: MainList()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        for (var index = 0; index < 3; index++) {
          gameState.updateAllUI();
          await tester.pump();
        }

        final rebuildSamples = <Duration>[];
        for (var index = 0; index < 15; index++) {
          gameState.updateAllUI();
          final stopwatch = Stopwatch()..start();
          await tester.pump();
          stopwatch.stop();
          rebuildSamples.add(stopwatch.elapsed);
        }

        final rebuildP95 = _percentile(rebuildSamples, 0.95);
        print(
          'PERF ${fixture.name}: '
          'main_list_rebuild_p95=${rebuildP95.inMicroseconds} us',
        );
        expect(rebuildP95, lessThan(fixture.budget.maxMainListRebuildP95));
      });
    }
  });
}

void _changeBlinkbladeHealth(GameState gameState, int index) {
  gameState.action(
    ChangeHealthCommand(
      index.isEven ? -1 : 1,
      'Blinkblade',
      null,
      gameState: gameState,
    ),
  );
}

List<Duration> _measureSync({
  required int iterations,
  required void Function() operation,
}) {
  final samples = <Duration>[];
  for (var index = 0; index < iterations; index++) {
    final stopwatch = Stopwatch()..start();
    operation();
    stopwatch.stop();
    samples.add(stopwatch.elapsed);
  }
  return samples;
}

Duration _percentile(List<Duration> samples, double percentile) {
  final sorted = [...samples]..sort();
  final index = ((sorted.length - 1) * percentile).ceil();
  return sorted[index];
}
