import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/idle_dimmer.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/ui_utils.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  late PowerMode original;

  setUp(() {
    original = getIt<Settings>().powerMode.value;
    isDimmed.value = false;
  });

  tearDown(() {
    getIt<Settings>().powerMode.value = original;
    isDimmed.value = false;
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: IdleDimmer(child: Scaffold(body: Text('board'))),
    ));
  }

  bool scrimVisible(WidgetTester tester) =>
      tester.any(find.byKey(kIdleDimScrimKey));

  testWidgets('does not dim in normal mode, however long it idles',
      (WidgetTester tester) async {
    getIt<Settings>().powerMode.value = PowerMode.normal;
    await pump(tester);

    await tester.pump(kIdleDimDelay * 3);
    expect(scrimVisible(tester), isFalse);
    expect(isDimmed.value, isFalse);
  });

  testWidgets('does not dim in reduce-power mode — the system handles it',
      (WidgetTester tester) async {
    getIt<Settings>().powerMode.value = PowerMode.reducePower;
    await pump(tester);

    await tester.pump(kIdleDimDelay * 3);
    expect(scrimVisible(tester), isFalse);
    expect(isDimmed.value, isFalse);
  });

  testWidgets('dims after the idle delay in dim-when-idle mode',
      (WidgetTester tester) async {
    getIt<Settings>().powerMode.value = PowerMode.dimWhenIdle;
    await pump(tester);

    // Just short of the delay: still awake.
    await tester.pump(kIdleDimDelay - const Duration(seconds: 1));
    expect(scrimVisible(tester), isFalse);
    expect(isDimmed.value, isFalse);

    await tester.pump(const Duration(seconds: 2));
    expect(scrimVisible(tester), isTrue);
    expect(isDimmed.value, isTrue);

    // The fade must finish and stop scheduling frames. A dim tier that left an
    // animation running would burn more power than the dimming saves —
    // pumpAndSettle throws if frames never stop.
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a tap wakes it and does not reach the board underneath',
      (WidgetTester tester) async {
    getIt<Settings>().powerMode.value = PowerMode.dimWhenIdle;
    int boardTaps = 0;
    await tester.pumpWidget(MaterialApp(
      home: IdleDimmer(
        child: Scaffold(
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => boardTaps++,
            child: const SizedBox.expand(child: Text('board')),
          ),
        ),
      ),
    ));

    await tester.pump(kIdleDimDelay + const Duration(seconds: 1));
    expect(isDimmed.value, isTrue);

    await tester.tap(find.byType(MaterialApp));
    await tester.pumpAndSettle();

    expect(isDimmed.value, isFalse, reason: 'the tap should wake the app');
    expect(boardTaps, 0,
        reason: 'the waking tap must be absorbed by the scrim — otherwise '
            'waking the screen also changes game state');
  });

  testWidgets('input before the delay restarts the countdown',
      (WidgetTester tester) async {
    getIt<Settings>().powerMode.value = PowerMode.dimWhenIdle;
    await pump(tester);

    await tester.pump(kIdleDimDelay - const Duration(seconds: 2));
    await tester.tap(find.text('board'));
    await tester.pump();

    // Past the original deadline, but the timer restarted on that tap.
    await tester.pump(const Duration(seconds: 4));
    expect(isDimmed.value, isFalse);

    await tester.pump(kIdleDimDelay);
    expect(isDimmed.value, isTrue);
  });

  testWidgets('switching away from dim-when-idle wakes immediately',
      (WidgetTester tester) async {
    getIt<Settings>().powerMode.value = PowerMode.dimWhenIdle;
    await pump(tester);
    await tester.pump(kIdleDimDelay + const Duration(seconds: 1));
    expect(isDimmed.value, isTrue);

    getIt<Settings>().powerMode.value = PowerMode.normal;
    await tester.pumpAndSettle();

    expect(isDimmed.value, isFalse);
    expect(scrimVisible(tester), isFalse);
  });
}
