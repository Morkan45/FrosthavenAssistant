import 'package:animated_text_kit/animated_text_kit.dart';
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

  testWidgets('dimming mutes tickers already running on the board',
      (WidgetTester tester) async {
    // Consulting isDimmed at the shimmer call sites is not enough on its own:
    // dimming does not rebuild the board, so an animation that was already
    // running would keep repainting at the panel's full rate behind the scrim
    // and cost more than the dim saves.
    //
    // Asserted through TickerMode rather than through frame counts on purpose.
    // AnimatedTextKit's repeat loop has pauses in which no frame is scheduled,
    // so a momentary hasScheduledFrame == false proves nothing about whether
    // the animation is still live.
    getIt<Settings>().powerMode.value = PowerMode.dimWhenIdle;

    late BuildContext boardContext;
    await tester.pumpWidget(MaterialApp(
      home: IdleDimmer(
        child: Scaffold(
          body: Builder(builder: (context) {
            boardContext = context;
            return AnimatedTextKit(
              repeatForever: true,
              animatedTexts: [
                ColorizeAnimatedText(
                  'Enhanced: 1',
                  textStyle: const TextStyle(fontSize: 10),
                  colors: const [Colors.white, Colors.blueGrey],
                ),
              ],
            );
          }),
        ),
      ),
    ));

    expect(TickerMode.valuesOf(boardContext).enabled, isTrue,
        reason: 'precondition: the board animates normally while awake');

    await tester.pump(kIdleDimDelay + const Duration(seconds: 1));
    expect(isDimmed.value, isTrue);
    expect(TickerMode.valuesOf(boardContext).enabled, isFalse,
        reason: 'every ticker under the scrim must be muted, including ones '
            'that were already running when the dim started');

    // Muting is not the same as breaking it — waking must bring it back.
    await tester.tap(find.byType(MaterialApp));
    await tester.pumpAndSettle();
    expect(isDimmed.value, isFalse);
    expect(TickerMode.valuesOf(boardContext).enabled, isTrue);
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
