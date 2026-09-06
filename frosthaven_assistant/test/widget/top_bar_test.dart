import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/element_button.dart';
import 'package:frosthaven_assistant/Layout/menus/action_log_menu.dart';
import 'package:frosthaven_assistant/Layout/top_bar.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
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
