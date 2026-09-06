// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/ModifierCardWidget/modifier_card_front.dart';
import 'package:frosthaven_assistant/Layout/ModifierCardWidget/modifier_card_rear.dart';
import 'package:frosthaven_assistant/Layout/ModifierDeckWidget/modifier_deck_widget.dart';
import 'package:frosthaven_assistant/Layout/ModifierDeckWidget/modifier_slide_animation_widget.dart';
import 'package:frosthaven_assistant/Layout/menus/ModifierDeckMenu/modifier_deck_menu.dart';
import 'package:frosthaven_assistant/Layout/menus/modifier_card_zoom.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/commands/amd_reveal_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/draw_modifier_card_command.dart';
import 'package:frosthaven_assistant/Resource/game_methods.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  setUp(() {
    getIt<GameState>().clearList();
  });

  // '' resolves to the monster modifier deck in GameMethods.getModifierDeck
  const monsterDeckName = '';

  Future<void> pumpWidget(WidgetTester tester, String name) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: Center(child: ModifierDeckWidget(name: name)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('ModifierDeckWidget monster deck', () {
    testWidgets('renders SizedBox with expected dimensions', (
      WidgetTester tester,
    ) async {
      await pumpWidget(tester, monsterDeckName);
      expect(find.byType(SizedBox), findsAtLeast(1));
    });

    testWidgets('renders InkWell for draw pile tap', (
      WidgetTester tester,
    ) async {
      await pumpWidget(tester, monsterDeckName);
      expect(find.byType(InkWell), findsAtLeast(1));
    });

    testWidgets('renders card count text', (WidgetTester tester) async {
      final deck = GameMethods.getModifierDeck(
        monsterDeckName,
        getIt<GameState>(),
      );
      await pumpWidget(tester, monsterDeckName);
      expect(find.text(deck.drawPileSize.toString()), findsAtLeast(1));
    });

    testWidgets('tapping draw pile draws a modifier card', (
      WidgetTester tester,
    ) async {
      final gameState = getIt<GameState>();
      final deck = GameMethods.getModifierDeck(monsterDeckName, gameState);
      final before = deck.discardPileSize;

      await pumpWidget(tester, monsterDeckName);
      // Tap the first InkWell (the draw pile)
      await tester.tap(find.byType(InkWell).first);
      // flush 0ms timers from TranslationAnimatedWidget.initState, then advance
      // past the 1200ms card animation duration
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));

      expect(deck.discardPileSize, before + 1);
      // restore
      gameState.undo();
    });

    testWidgets('shows "Shuffle & Draw" when draw pile is empty', (
      WidgetTester tester,
    ) async {
      final gameState = getIt<GameState>();
      final deck = GameMethods.getModifierDeck(monsterDeckName, gameState);
      // Drain the draw pile
      while (deck.drawPileIsNotEmpty) {
        gameState.action(
          DrawModifierCardCommand(
            monsterDeckName,
            gameState: getIt<GameState>(),
          ),
        );
      }

      await pumpWidget(tester, monsterDeckName);
      expect(find.text('Shuffle\n& Draw'), findsOneWidget);

      // restore
      while (gameState.commandIndex.value >= 0) {
        gameState.undo();
      }
    });

    testWidgets('tapping discard pile opens ModifierDeckMenu', (
      WidgetTester tester,
    ) async {
      final gameState = getIt<GameState>();
      // Draw a card so discard pile has something
      gameState.action(
        DrawModifierCardCommand(monsterDeckName, gameState: getIt<GameState>()),
      );

      await pumpWidget(tester, monsterDeckName);
      // The discard pile InkWell is the second one (draw pile is first)
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsAtLeast(2));
      await tester.tap(inkWells.last);
      await tester.pumpAndSettle();
      expect(find.byType(ModifierDeckMenu), findsOneWidget);

      gameState.undo();
    });

    testWidgets(
      'long press on discard pile opens ModifierCardZoom when not empty',
      (WidgetTester tester) async {
        final gameState = getIt<GameState>();
        gameState.action(
          DrawModifierCardCommand(
            monsterDeckName,
            gameState: getIt<GameState>(),
          ),
        );

        await pumpWidget(tester, monsterDeckName);
        final inkWells = find.byType(InkWell);
        await tester.longPress(inkWells.last);
        await tester.pumpAndSettle();
        expect(find.byType(ModifierCardZoom), findsOneWidget);

        gameState.undo();
      },
    );

    testWidgets('renders Row with draw and discard sections', (
      WidgetTester tester,
    ) async {
      await pumpWidget(tester, monsterDeckName);
      expect(find.byType(Row), findsAtLeast(1));
    });

    testWidgets(
      'does not replay the draw animation on an unrelated (scaling) rebuild',
      (WidgetTester tester) async {
        final gameState = getIt<GameState>();
        final settings = getIt<Settings>();
        final scalingBefore = settings.userScalingBars.value;

        // Two draws so the discard pile has >1 card, which renders the slide
        // animation whenever animations are enabled — our observable.
        gameState.action(
          DrawModifierCardCommand(monsterDeckName, gameState: gameState),
        );
        gameState.action(
          DrawModifierCardCommand(monsterDeckName, gameState: gameState),
        );

        await pumpWidget(tester, monsterDeckName);
        // The pending draw animates on first build.
        expect(find.byType(ModifierSlideAnimationWidget), findsOneWidget);

        // Let the 1200ms animation finish (onComplete clears the flag).
        await tester.pump(const Duration(milliseconds: 1300));

        // Drag the scaling slider: a rebuild that is NOT a new draw. The draw
        // event still lingers in lastEvent, so the pre-fix code replayed here.
        settings.userScalingBars.value = scalingBefore + 0.1;
        await tester.pump();

        expect(find.byType(ModifierSlideAnimationWidget), findsNothing);
        settings.userScalingBars.value = scalingBefore;
        gameState.undo();
        gameState.undo();
      },
    );

    testWidgets('card count text updates after drawing a card', (
      WidgetTester tester,
    ) async {
      final gameState = getIt<GameState>();
      final deck = GameMethods.getModifierDeck(monsterDeckName, gameState);
      final countBefore = deck.drawPileSize;

      await pumpWidget(tester, monsterDeckName);
      expect(find.text(countBefore.toString()), findsAtLeast(1));

      gameState.action(
        DrawModifierCardCommand(monsterDeckName, gameState: gameState),
      );
      await tester.pump();

      expect(find.text((countBefore - 1).toString()), findsAtLeast(1));
      gameState.undo();
    });
  });

  group('ModifierDeckWidget character deck', () {
    setUp(() {
      getIt<GameState>().clearList();
      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
    });

    testWidgets('renders without error for character deck', (
      WidgetTester tester,
    ) async {
      await pumpWidget(tester, 'Blinkblade');
      expect(find.byType(ModifierDeckWidget), findsOneWidget);
    });

    testWidgets('renders card count for character deck', (
      WidgetTester tester,
    ) async {
      final deck = GameMethods.getModifierDeck(
        'Blinkblade',
        getIt<GameState>(),
      );
      await pumpWidget(tester, 'Blinkblade');
      expect(find.text(deck.drawPileSize.toString()), findsAtLeast(1));
    });

    testWidgets('tapping draw pile draws a card from character deck', (
      WidgetTester tester,
    ) async {
      final gameState = getIt<GameState>();
      final deck = GameMethods.getModifierDeck('Blinkblade', gameState);
      final before = deck.discardPileSize;

      await pumpWidget(tester, 'Blinkblade');
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1300));

      expect(deck.discardPileSize, before + 1);
      gameState.undo();
    });
  });

  group('ModifierDeckWidget revealedCount', () {
    testWidgets('draw pile top card shows backside when revealedCount is 0', (
      WidgetTester tester,
    ) async {
      final gameState = getIt<GameState>();
      final deck = GameMethods.getModifierDeck(monsterDeckName, gameState);
      expect(deck.revealedCount.value, 0);

      await pumpWidget(tester, monsterDeckName);

      expect(find.byType(ModifierCardRear), findsOneWidget);
    });

    testWidgets('draw pile top card shows frontside when revealedCount > 0', (
      WidgetTester tester,
    ) async {
      final gameState = getIt<GameState>();
      gameState.action(
        AMDRevealCommand(
          amount: 1,
          name: monsterDeckName,
          gameState: gameState,
        ),
      );

      await pumpWidget(tester, monsterDeckName);

      expect(find.byType(ModifierCardFront), findsOneWidget);

      gameState.undo();
    });

    testWidgets(
      'widget updates reactively when revealedCount changes from 0 to 1',
      (WidgetTester tester) async {
        final gameState = getIt<GameState>();
        final deck = GameMethods.getModifierDeck(monsterDeckName, gameState);
        expect(deck.revealedCount.value, 0);

        await pumpWidget(tester, monsterDeckName);
        expect(find.byType(ModifierCardRear), findsOneWidget);
        gameState.action(
          AMDRevealCommand(
            amount: 1,
            name: monsterDeckName,
            gameState: gameState,
          ),
        );
        await tester.pump();

        expect(find.byType(ModifierCardFront), findsOneWidget);

        gameState.undo();
      },
    );

    testWidgets(
      'widget updates reactively when revealedCount changes from 1 to 0',
      (WidgetTester tester) async {
        final gameState = getIt<GameState>();
        gameState.action(
          AMDRevealCommand(
            amount: 1,
            name: monsterDeckName,
            gameState: gameState,
          ),
        );

        await pumpWidget(tester, monsterDeckName);
        expect(find.byType(ModifierCardFront), findsOneWidget);
        gameState.action(
          AMDRevealCommand(
            amount: 0,
            name: monsterDeckName,
            gameState: gameState,
          ),
        );
        await tester.pump();

        expect(find.byType(ModifierCardRear), findsOneWidget);

        gameState.undo();
        gameState.undo();
      },
    );
  });
}
