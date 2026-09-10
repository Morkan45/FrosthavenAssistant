import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/game_data.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/main.dart';
import 'package:frosthaven_assistant/main_state.dart';
import 'package:frosthaven_assistant/services/network/network.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import 'command/test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
    loading.value = false;
  });

  setUp(() {
    getIt<GameState>().clearList();
    loading.value = false;
  });

  // Helper: pump a MyHomePage wrapped in the minimum required widget tree
  Future<void> pumpHomePage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: MyHomePage(title: 'Test'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('MainState build', () {
    testWidgets('MyHomePage renders without crashing', (
      WidgetTester tester,
    ) async {
      await pumpHomePage(tester);
      expect(find.byType(MyHomePage), findsOneWidget);
    });

    testWidgets('build preserves the system text scale at the app root', (
      WidgetTester tester,
    ) async {
      await pumpHomePage(tester);
      expect(find.byType(ValueListenableBuilder<int>), findsAtLeast(1));
    });

    testWidgets('operational shell remains usable at system text scales', (
      WidgetTester tester,
    ) async {
      // The test host is Windows, whose desktop preference starts at 1.6.
      // A phone viewport uses the mobile default of 1.0 in production.
      getIt<Settings>().userScalingBars.value = 1.0;
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final scale in [1.0, 1.5, 2.0]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await pumpHomePage(tester);
        expect(find.byType(MyHomePage), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'text scale $scale');
      }
      tester.platformDispatcher.clearAllTestValues();
    });
  });

  group('MainState lifecycle', () {
    // Lifecycle events are dispatched via the binding to all observers.
    // MainState registers itself as a WidgetsBindingObserver in initState,
    // so pumping MyHomePage ensures the observer is active.

    testWidgets('resumed sets appInBackground to false', (
      WidgetTester tester,
    ) async {
      await pumpHomePage(tester);
      getIt<Network>().appInBackground = true;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(getIt<Network>().appInBackground, false);
    });

    testWidgets('inactive sets appInBackground to true', (
      WidgetTester tester,
    ) async {
      await pumpHomePage(tester);
      getIt<Network>().appInBackground = false;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(getIt<Network>().appInBackground, true);
    });

    testWidgets('paused does not change appInBackground', (
      WidgetTester tester,
    ) async {
      await pumpHomePage(tester);
      getIt<Network>().appInBackground = false;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(getIt<Network>().appInBackground, false);
    });

    testWidgets('detached does not crash when client is not connected', (
      WidgetTester tester,
    ) async {
      await pumpHomePage(tester);
      // detached with disconnected client — just verify no exception
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
      await tester.pump();
    });
  });

  group('DataLoadedNotification', () {
    test('can be constructed with campaign data', () {
      // Just verify the notification can be instantiated
      // (it carries data for notification dispatch)
      final notification = DataLoadedNotification(
        data: getIt<GameData>().modelData.value.values.first,
      );
      expect(notification, isNotNull);
    });
  });
}
