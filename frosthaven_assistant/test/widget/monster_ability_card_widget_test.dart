import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/MonsterAbilityCardWidget/monster_ability_card_widget.dart';
import 'package:frosthaven_assistant/Layout/MonsterAbilityCardWidget/monster_ability_card_front.dart';
import 'package:frosthaven_assistant/Model/monster_ability.dart';
import 'package:frosthaven_assistant/Layout/menus/AbilityCardsMenu/ability_cards_menu.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/commands/draw_command.dart';
import 'package:frosthaven_assistant/Resource/commands/next_round_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/game_data.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  setUp(() {
    getIt<GameState>().clearList();
    getIt<Settings>().noCalculation.value = false;
    AddMonsterCommand(
      'Zealot',
      1,
      false,
      gameState: getIt<GameState>(),
    ).execute();
  });

  Monster getZealot() {
    return getIt<GameState>().currentList.firstWhere((e) => e.id == 'Zealot')
        as Monster;
  }

  Future<void> pumpWidget(WidgetTester tester, Monster monster) async {
    await tester.pumpWidget(
      testMaterialApp(
        home: Scaffold(body: MonsterAbilityCardWidget(data: monster)),
      ),
    );
    await tester.pump();
  }

  group('MonsterAbilityCardWidget', () {
    testWidgets(
      'original values redraw immediately without changing the card or game',
      (tester) async {
        final settings = getIt<Settings>();
        final state = getIt<GameState>();
        final monster = getZealot();
        AddStandeeCommand(
          1,
          null,
          monster.id,
          MonsterType.normal,
          false,
          gameState: state,
        ).execute();
        const card = MonsterAbilityCardModel(
          'Test ability',
          999,
          false,
          50,
          ['%attack% +1', '%move% -1'],
          'Zealot',
          [],
        );
        await tester.pumpWidget(
          testMaterialApp(
            home: Scaffold(
              body: MonsterAbilityCardFront(
                card: card,
                data: monster,
                scale: 2,
                calculateAll: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        String renderedText() => tester
            .widgetList<RichText>(find.byType(RichText))
            .map((widget) => widget.text.toPlainText())
            .join('|');
        final calculated = renderedText();
        final gameBefore = state.toString();
        settings.noCalculation.value = true;
        await tester.pumpAndSettle();
        expect(renderedText(), isNot(calculated));
        expect(renderedText(), contains('+1'));
        expect(renderedText(), contains('-1'));
        expect(state.toString(), gameBefore);
        expect(
          tester
              .widget<MonsterAbilityCardFront>(
                find.byType(MonsterAbilityCardFront),
              )
              .card,
          same(card),
        );
        settings.noCalculation.value = false;
        await tester.pumpAndSettle();
        expect(renderedText(), calculated);
      },
    );
    testWidgets('renders without error in chooseInitiative state', (
      WidgetTester tester,
    ) async {
      final monster = getZealot();
      await pumpWidget(tester, monster);
      expect(find.byType(MonsterAbilityCardWidget), findsOneWidget);
    });

    testWidgets('renders rear card when not in playTurns state', (
      WidgetTester tester,
    ) async {
      final monster = getZealot();
      await pumpWidget(tester, monster);
      // In chooseInitiative state, the rear card should be shown
      expect(find.byType(Image), findsAtLeast(1));
    });

    testWidgets('tapping card calls the supplied turn action without a menu', (
      WidgetTester tester,
    ) async {
      final monster = getZealot();
      var turns = 0;
      await tester.pumpWidget(
        testMaterialApp(
          home: Scaffold(
            body: MonsterAbilityCardWidget(data: monster, onTap: () => turns++),
          ),
        ),
      );
      await tester.pump();

      final originalOnError2 = FlutterError.onError;
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      FlutterError.onError = originalOnError2;

      expect(turns, 1);
      expect(find.byType(AbilityCardsMenu), findsNothing);
    });

    testWidgets('widget uses AnimatedSwitcher for card transition', (
      WidgetTester tester,
    ) async {
      final monster = getZealot();
      await pumpWidget(tester, monster);
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    testWidgets('renders front card in playTurns state when active', (
      WidgetTester tester,
    ) async {
      final gameState = getIt<GameState>();
      AddStandeeCommand(
        1,
        null,
        'Zealot',
        MonsterType.normal,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      final monster = getZealot();

      // Enter playTurns by drawing
      DrawCommand(gameState: getIt<GameState>()).execute();
      expect(gameState.roundState.value, RoundState.playTurns);
      await tester.pumpWidget(
        testMaterialApp(
          home: Scaffold(body: MonsterAbilityCardWidget(data: monster)),
        ),
      );
      await tester.pump();

      expect(find.byType(MonsterAbilityCardWidget), findsOneWidget);

      // Cleanup: advance past the 600ms AnimatedSwitcher timer from NextRoundCommand
      final originalOnError2 = FlutterError.onError;
      NextRoundCommand(
        gameState: getIt<GameState>(),
        gameData: getIt<GameData>(),
        settings: getIt<Settings>(),
      ).execute();
      await tester.pump(const Duration(milliseconds: 700));
      FlutterError.onError = originalOnError2;
    });

    testWidgets('card without a turn action stays inactive on repeated taps', (
      WidgetTester tester,
    ) async {
      final monster = getZealot();
      await pumpWidget(tester, monster);
      await tester.tap(find.byType(InkWell).first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byType(InkWell).first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(MonsterAbilityCardWidget), findsOneWidget);
      expect(find.byType(AbilityCardsMenu), findsNothing);
    });
  });
}
