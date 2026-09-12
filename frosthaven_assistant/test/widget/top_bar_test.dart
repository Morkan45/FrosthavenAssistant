import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/element_button.dart';
import 'package:frosthaven_assistant/Layout/menus/action_log_menu.dart';
import 'package:frosthaven_assistant/Layout/top_bar.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';

// ignore_for_file: no-magic-number

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  setUp(() {
    getIt<GameState>().clearList();
    final settings = getIt<Settings>();
    settings.userScalingBars.value = 1.6;
    settings.userScalingMainList.value = 1;
    settings.noCalculation.value = false;
  });

  Future<void> pumpTopBar(WidgetTester tester, {Size? size}) async {
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          drawer: const Drawer(child: Text('Drawer content')),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Builder(builder: (context) => const TopBar()),
          ),
          body: const SizedBox(),
        ),
      ),
    );
    await tester.pump();
  }

  group('TopBar', () {
    testWidgets('renders title text', (WidgetTester tester) async {
      await pumpTopBar(tester);
      expect(find.textContaining('X-haven'), findsOneWidget);
    });

    testWidgets('renders 6 ElementButtons', (WidgetTester tester) async {
      await pumpTopBar(tester);
      expect(find.byType(ElementButton), findsNWidgets(6));
    });

    testWidgets('renders menu icon', (WidgetTester tester) async {
      await pumpTopBar(tester);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byTooltip('Open main menu'), findsOneWidget);
    });

    testWidgets('main menu opens from keyboard activation', (
      WidgetTester tester,
    ) async {
      await pumpTopBar(tester);
      final detector = tester.widget<FocusableActionDetector>(
        find.byKey(const Key('top-bar-main-menu-focus')),
      );
      detector.focusNode!.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(
        tester.state<ScaffoldState>(find.byType(Scaffold)).isDrawerOpen,
        isTrue,
      );
    });

    testWidgets('element controls expose localized tooltips', (
      WidgetTester tester,
    ) async {
      await pumpTopBar(tester);

      for (final label in ['Fire', 'Ice', 'Air', 'Earth', 'Light', 'Dark']) {
        expect(find.byTooltip(label), findsOneWidget);
      }
    });

    testWidgets('wide desktop exposes compact infrequent actions', (
      WidgetTester tester,
    ) async {
      await pumpTopBar(tester, size: const Size(1280, 720));

      final actions = find.byKey(const Key('desktop-actions-menu'));
      expect(actions, findsOneWidget);
      expect(find.byTooltip('More actions'), findsOneWidget);
      await tester.tap(actions);
      await tester.pumpAndSettle();

      expect(find.text('View Action Log'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Fullscreen'), findsOneWidget);

      await tester.tap(find.text('View Action Log'));
      await tester.pumpAndSettle();
      expect(find.byType(ActionLogMenu), findsOneWidget);
    });

    testWidgets(
      'toolbar zoom shares the scale setting and disables at bounds',
      (tester) async {
        final settings = getIt<Settings>();
        await pumpTopBar(tester, size: const Size(1280, 720));
        await tester.tap(find.byKey(const Key('top-bar-zoom-in')));
        await tester.pump();
        expect(settings.userScalingMainList.value, 1.1);
        await tester.tap(find.byKey(const Key('top-bar-zoom-out')));
        await tester.pump();
        expect(settings.userScalingMainList.value, 1);
        settings.userScalingMainList.value = 3;
        await tester.pump();
        expect(
          tester
              .widget<IconButton>(find.byKey(const Key('top-bar-zoom-in')))
              .onPressed,
          isNull,
        );
        settings.userScalingMainList.value = 0.2;
        await tester.pump();
        expect(
          tester
              .widget<IconButton>(find.byKey(const Key('top-bar-zoom-out')))
              .onPressed,
          isNull,
        );
      },
    );

    testWidgets(
      'original-value toggle tracks settings and describes next action',
      (tester) async {
        final settings = getIt<Settings>();
        await pumpTopBar(tester, size: const Size(1280, 720));
        final toggle = find.byKey(const Key('top-bar-original-values'));
        await tester.tap(toggle);
        await tester.pump();
        expect(settings.noCalculation.value, isTrue);
        expect(
          find.byTooltip('Show calculated monster ability values'),
          findsOneWidget,
        );
        expect(tester.widget<IconButton>(toggle).isSelected, isTrue);
        settings.noCalculation.value = false;
        await tester.pump();
        expect(
          find.byTooltip('Show original monster ability values'),
          findsOneWidget,
        );
        expect(tester.widget<IconButton>(toggle).isSelected, isFalse);
      },
    );

    testWidgets('more actions is centered with a scaled gap before fire', (
      tester,
    ) async {
      await pumpTopBar(tester, size: const Size(1920, 1080));
      for (final scale in [1.0, 1.6, 3.0]) {
        getIt<Settings>().userScalingBars.value = scale;
        await tester.pump();
        final target = tester.getRect(
          find.byKey(const Key('top-bar-more-actions-target')),
        );
        final icon = tester.getRect(find.byIcon(Icons.more_vert));
        final fire = tester.getRect(find.byKey(const ValueKey('element-fire')));
        expect(icon.center.dx, closeTo(target.center.dx, 0.01));
        expect(icon.center.dy, closeTo(target.center.dy, 0.01));
        expect(
          fire.left - target.right,
          greaterThanOrEqualTo(8 * scale - 0.01),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('infused elements fit while the toolbar shrinks', (
      tester,
    ) async {
      await pumpTopBar(tester, size: const Size(1280, 720));
      await tester.tap(find.byKey(const ValueKey('element-fire')));
      await tester.pumpAndSettle();
      expect(getIt<GameState>().elementState[Elements.fire], ElementState.full);
      getIt<Settings>().userScalingBars.value = 1;
      tester.view.physicalSize = const Size(360, 800);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      getIt<GameState>().undo();
    });

    testWidgets('narrow toolbar keeps display actions available in overflow', (
      tester,
    ) async {
      getIt<Settings>().userScalingBars.value = 1;
      await pumpTopBar(tester, size: const Size(360, 800));
      expect(find.byKey(const Key('top-bar-zoom-in')), findsNothing);
      await tester.tap(find.byKey(const Key('desktop-actions-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zoom in (Ctrl++)'));
      await tester.pumpAndSettle();
      expect(getIt<Settings>().userScalingMainList.value, 1.1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping fire element changes element state', (
      WidgetTester tester,
    ) async {
      final gameState = getIt<GameState>();
      // Ensure fire starts inert
      expect(gameState.elementState[Elements.fire], ElementState.inert);

      await pumpTopBar(tester);
      final fireButton = find.byWidgetPredicate(
        (w) => w is ElementButton && w.element == Elements.fire,
      );
      await tester.tap(fireButton);
      await tester.pump();

      // After one tap, fire should be imbued (full or half)
      expect(gameState.elementState[Elements.fire], isNot(ElementState.inert));
      gameState.undo();
    });

    testWidgets('long pressing fire element imbues it to half', (
      WidgetTester tester,
    ) async {
      final gameState = getIt<GameState>();
      await pumpTopBar(tester);
      final fireButton = find.byWidgetPredicate(
        (w) => w is ElementButton && w.element == Elements.fire,
      );
      await tester.longPress(fireButton);
      await tester.pump();

      expect(gameState.elementState[Elements.fire], ElementState.half);
      gameState.undo();
    });

    testWidgets('tapping ice element changes element state', (
      WidgetTester tester,
    ) async {
      final gameState = getIt<GameState>();
      await pumpTopBar(tester);
      final iceButton = find.byWidgetPredicate(
        (w) => w is ElementButton && w.element == Elements.ice,
      );
      await tester.tap(iceButton);
      await tester.pump();

      expect(gameState.elementState[Elements.ice], isNot(ElementState.inert));
      gameState.undo();
    });

    testWidgets('tapping inert element imbues it (sets to full)', (
      WidgetTester tester,
    ) async {
      final gameState = getIt<GameState>();
      await pumpTopBar(tester);
      final earthButton = find.byWidgetPredicate(
        (w) => w is ElementButton && w.element == Elements.earth,
      );
      // Tap inert → imbues to full (half=false)
      await tester.tap(earthButton);
      await tester.pump();
      expect(gameState.elementState[Elements.earth], ElementState.full);

      // Tap again (full → use → inert)
      await tester.tap(earthButton);
      await tester.pump();
      expect(gameState.elementState[Elements.earth], ElementState.inert);
      gameState.undo();
      gameState.undo();
    });
  });
}
