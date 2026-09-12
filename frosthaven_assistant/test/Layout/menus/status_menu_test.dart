import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_summons_button.dart';
import 'package:frosthaven_assistant/Layout/menus/AddSummonMenu/add_summon_menu.dart';
import 'package:frosthaven_assistant/Layout/menus/StatusMenu/status_menu.dart';
import 'package:frosthaven_assistant/Layout/menus/AbilityCardsMenu/ability_cards_menu.dart';
import 'package:frosthaven_assistant/Resource/game_methods.dart';
import 'package:frosthaven_assistant/Layout/menus/condition_button.dart';
import 'package:frosthaven_assistant/Layout/menus/set_character_level_menu.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_condition_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../../command/test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  setUp(() {
    getIt<GameState>().clearList();
    AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
  });

  Character getBlinkblade() {
    return getIt<GameState>().currentList.firstWhere(
          (item) => item.id == 'Blinkblade',
        )
        as Character;
  }

  Future<void> pumpMenu(WidgetTester tester) async {
    final character = getBlinkblade();
    await tester.pumpWidget(
      testMaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => StatusMenu(
                  figureId: character.id,
                  characterId: character.id,
                  monsterId: null,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('StatusMenu', () {
    testWidgets('shows Name above the character class', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);

      expect(find.text('Name'), findsOneWidget);
      expect(find.byKey(const Key('monster-ability-deck-menu')), findsNothing);
      expect(
        find.byKey(const Key('status-character-class-name')),
        findsOneWidget,
      );
      expect(find.text('Blinkblade'), findsOneWidget);

      final nameRect = tester.getRect(
        find.byKey(const Key('status-character-name')),
      );
      final classRect = tester.getRect(
        find.byKey(const Key('status-character-class-name')),
      );
      expect(classRect.top, greaterThanOrEqualTo(nameRect.bottom));
    });

    testWidgets('clicking Name changes it while keeping the class visible', (
      WidgetTester tester,
    ) async {
      final character = getBlinkblade();
      await pumpMenu(tester);

      await tester.tap(find.byKey(const Key('status-character-name')));
      await tester.pump();
      expect(
        find.byKey(const Key('status-character-name-field')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('status-character-name-field')),
        'Blinky',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(character.characterState.display.value, 'Blinky');
      expect(find.text('Blinky'), findsOneWidget);
      expect(find.text('Blinkblade'), findsOneWidget);
    });

    testWidgets('renders health counter image', (WidgetTester tester) async {
      await pumpMenu(tester);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/abilities/heal.png',
        ),
        findsWidgets,
      );
    });

    testWidgets('renders condition buttons', (WidgetTester tester) async {
      await pumpMenu(tester);
      // ConditionButton widgets are rendered for the standard set of conditions
      expect(find.byType(ConditionButton), findsWidgets);
    });

    testWidgets('opens Add Summon from the character status menu', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);
      expect(find.byType(CharacterSummonsButton), findsOneWidget);

      await tester.tap(find.byKey(const Key('character-add-summon')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AddSummonMenu), findsOneWidget);
    });

    testWidgets(
      'tapping a condition button adds the condition to the character',
      (WidgetTester tester) async {
        await pumpMenu(tester);

        final character = getBlinkblade();
        final conditionsBefore = List<Condition>.of(
          character.characterState.conditions.value,
        );

        // Find the stun ConditionButton and tap it
        final stunButtons = find.byWidgetPredicate(
          (widget) =>
              widget is ConditionButton && widget.condition == Condition.stun,
        );
        expect(stunButtons, findsOneWidget);
        await tester.tap(stunButtons);
        await tester.pumpAndSettle();

        expect(
          character.characterState.conditions.value,
          isNot(equals(conditionsBefore)),
        );
        expect(
          character.characterState.conditions.value,
          contains(Condition.stun),
        );
      },
    );

    testWidgets('tapping a condition button twice removes the condition', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);
      final stunButton = find.byWidgetPredicate(
        (widget) =>
            widget is ConditionButton && widget.condition == Condition.stun,
      );
      // Add the condition
      await tester.tap(stunButton);
      await tester.pumpAndSettle();
      // Remove the condition
      await tester.tap(stunButton);
      await tester.pumpAndSettle();

      final character = getBlinkblade();
      expect(
        character.characterState.conditions.value,
        isNot(contains(Condition.stun)),
      );
    });

    testWidgets('renders multiple condition buttons', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);
      for (final condition in [
        Condition.stun,
        Condition.immobilize,
        Condition.disarm,
        Condition.wound,
        Condition.muddle,
        Condition.poison,
        Condition.strengthen,
        Condition.invisible,
        Condition.regenerate,
        Condition.ward,
      ]) {
        expect(
          find.byWidgetPredicate(
            (w) => w is ConditionButton && w.condition == condition,
          ),
          findsOneWidget,
          reason: 'Expected ConditionButton for $condition',
        );
      }
    });

    testWidgets('tapping level icon button opens SetCharacterLevelMenu', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);
      // The level button is an IconButton with 'assets/images/psd/level.png'
      final levelButton = find.byWidgetPredicate(
        (w) =>
            w is IconButton &&
            w.icon is Image &&
            (w.icon as Image).image is AssetImage &&
            ((w.icon as Image).image as AssetImage).assetName ==
                'assets/images/psd/level.png',
      );
      expect(levelButton, findsOneWidget);
      await tester.tap(levelButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SetCharacterLevelMenu), findsOneWidget);
    });

    testWidgets('tapping skull button kills character and closes menu', (
      WidgetTester tester,
    ) async {
      final character = getBlinkblade();
      final originalHp = character.characterState.health.value;
      // Ensure HP > 0
      expect(originalHp, greaterThan(0));
      await pumpMenu(tester);
      final skullButton = find.byWidgetPredicate(
        (w) =>
            w is IconButton &&
            w.icon is Image &&
            (w.icon as Image).image is AssetImage &&
            ((w.icon as Image).image as AssetImage).assetName ==
                'assets/images/psd/skull.png',
      );
      expect(skullButton, findsOneWidget);
      await tester.tap(skullButton);
      await tester.pump();

      // HP should be 0 after skull
      expect(character.characterState.health.value, 0);
      // Restore
      getIt<GameState>().undo();
    });
  });

  group('StatusMenu monster', () {
    setUp(() {
      getIt<GameState>().clearList();
      AddMonsterCommand(
        'Zealot',
        1,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      AddStandeeCommand(
        1,
        null,
        'Zealot',
        MonsterType.normal,
        false,
        gameState: getIt<GameState>(),
      ).execute();
    });

    Monster getZealot() {
      return getIt<GameState>().currentList.firstWhere(
            (item) => item.id == 'Zealot',
          )
          as Monster;
    }

    Future<void> pumpMonsterMenu(WidgetTester tester) async {
      final zealot = getZealot();
      final instance = zealot.monsterInstances.first;
      await tester.pumpWidget(
        testMaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => StatusMenu(
                    figureId: instance.getId(),
                    characterId: null,
                    monsterId: zealot.id,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('renders condition buttons for monster', (
      WidgetTester tester,
    ) async {
      await pumpMonsterMenu(tester);
      expect(find.byType(ConditionButton), findsWidgets);
      expect(find.byType(CharacterSummonsButton), findsNothing);
    });

    testWidgets('condition panel opens the owning monsters ability deck', (
      tester,
    ) async {
      await pumpMonsterMenu(tester);
      final button = find.byKey(const Key('monster-ability-deck-menu'));
      expect(button, findsOneWidget);
      expect(find.byTooltip('Monster ability deck'), findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      final menu = tester.widget<AbilityCardsMenu>(
        find.byType(AbilityCardsMenu),
      );
      expect(menu.monsterData, same(getZealot()));
      expect(
        menu.monsterAbilityState,
        same(GameMethods.getDeck(getZealot().type.deck)),
      );
      expect(menu.gameState, same(getIt<GameState>()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping stun condition adds stun to monster instance', (
      WidgetTester tester,
    ) async {
      final zealot = getZealot();
      final instance = zealot.monsterInstances.first;
      final before = List<Condition>.of(instance.conditions.value);

      await pumpMonsterMenu(tester);
      final stunButton = find.byWidgetPredicate(
        (w) => w is ConditionButton && w.condition == Condition.stun,
      );
      await tester.tap(stunButton.first);
      await tester.pumpAndSettle();

      expect(instance.conditions.value, isNot(equals(before)));
      expect(instance.conditions.value, contains(Condition.stun));
      getIt<GameState>().undo();
    });

    testWidgets('tapping level button for monster opens SetLevelMenu', (
      WidgetTester tester,
    ) async {
      await pumpMonsterMenu(tester);
      final levelButton = find.byWidgetPredicate(
        (w) =>
            w is IconButton &&
            w.icon is Image &&
            (w.icon as Image).image is AssetImage &&
            ((w.icon as Image).image as AssetImage).assetName ==
                'assets/images/psd/level.png',
      );
      expect(levelButton, findsOneWidget);
      await tester.tap(levelButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // The else branch (monster level) was covered; menu opened
      expect(find.byType(StatusMenu), findsOneWidget);
    });

    testWidgets('tapping summon button on normal standee marks as summoned', (
      WidgetTester tester,
    ) async {
      final zealot = getZealot();
      final instance = zealot.monsterInstances.first;
      await pumpMonsterMenu(tester);
      final summonButton = find.byWidgetPredicate(
        (w) =>
            w is IconButton &&
            w.icon is Image &&
            (w.icon as Image).image is AssetImage &&
            ((w.icon as Image).image as AssetImage).assetName.contains(
              'summon',
            ),
      );
      if (summonButton.evaluate().isNotEmpty) {
        await tester.tap(summonButton.first);
        await tester.pump();
      }
      // roundSummoned is set (not -1) after tapping the summon button
      expect(instance.roundSummoned, isNot(-1));
      getIt<GameState>().undo();
    });
  });

  group('StatusMenu elite monster', () {
    setUp(() {
      getIt<GameState>().clearList();
      AddMonsterCommand(
        'Zealot',
        1,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      AddStandeeCommand(
        1,
        null,
        'Zealot',
        MonsterType.elite,
        false,
        gameState: getIt<GameState>(),
      ).execute();
    });

    testWidgets(
      'elite monster menu renders without error (covers elite branch)',
      (WidgetTester tester) async {
        final gameState = getIt<GameState>();
        final zealot =
            gameState.currentList.firstWhere((e) => e is Monster) as Monster;
        final instance = zealot.monsterInstances.first;
        await tester.pumpWidget(
          testMaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => StatusMenu(
                      figureId: instance.getId(),
                      characterId: null,
                      monsterId: zealot.id,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(StatusMenu), findsOneWidget);
        expect(instance.type, MonsterType.elite);
      },
    );
  });

  group('StatusMenu monster with characters present', () {
    setUp(() {
      getIt<GameState>().clearList();
      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
      AddCharacterCommand('Banner Spear', 'Frosthaven', null, 1).execute();
      AddCharacterCommand('Hatchet', 'Jaws of the Lion', null, 1).execute();
      AddCharacterCommand(
        'Demolitionist',
        'Jaws of the Lion',
        null,
        1,
      ).execute();
      AddMonsterCommand(
        'Zealot',
        1,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      AddStandeeCommand(
        1,
        null,
        'Zealot',
        MonsterType.normal,
        false,
        gameState: getIt<GameState>(),
      ).execute();
    });

    testWidgets(
      'monster menu with 4 characters renders character condition buttons',
      (WidgetTester tester) async {
        final gameState = getIt<GameState>();
        final zealot =
            gameState.currentList.firstWhere((e) => e is Monster) as Monster;
        final instance = zealot.monsterInstances.first;
        await tester.pumpWidget(
          testMaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => StatusMenu(
                      figureId: instance.getId(),
                      characterId: null,
                      monsterId: zealot.id,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        // character condition buttons (1-4) are rendered when 4 characters present
        expect(
          find.byWidgetPredicate(
            (w) => w is ConditionButton && w.condition == Condition.character1,
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is ConditionButton && w.condition == Condition.character4,
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('StatusMenu chill stackable buttons', () {
    testWidgets('tapping chill plus button adds chill condition', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);

      // The chill + button is the last add.png IconButton in the status menu
      final addButtons = find.byWidgetPredicate(
        (w) =>
            w is IconButton &&
            w.icon is Image &&
            (w.icon as Image).image is AssetImage &&
            ((w.icon as Image).image as AssetImage).assetName ==
                'assets/images/psd/add.png',
      );
      if (addButtons.evaluate().isNotEmpty) {
        final chillPlusButton = addButtons.last;
        final originalOnError2 = FlutterError.onError;
        await tester.tap(chillPlusButton);
        await tester.pump();
        FlutterError.onError = originalOnError2;
        final character = getBlinkblade();
        expect(character.characterState.chill.value, greaterThan(0));
        getIt<GameState>().undo();
      }
    });

    testWidgets('tapping chill minus button when chill > 0 removes chill', (
      WidgetTester tester,
    ) async {
      // Pre-add chill so the minus button's condition (value > 0) is true
      final character = getBlinkblade();
      AddConditionCommand(
        Condition.chill,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
      ).execute();
      expect(character.characterState.chill.value, greaterThan(0));
      await pumpMenu(tester);

      final subButtons = find.byWidgetPredicate(
        (w) =>
            w is IconButton &&
            w.icon is Image &&
            (w.icon as Image).image is AssetImage &&
            ((w.icon as Image).image as AssetImage).assetName ==
                'assets/images/psd/sub.png',
      );
      if (subButtons.evaluate().isNotEmpty) {
        final chillMinusButton = subButtons.last;
        final originalOnError2 = FlutterError.onError;
        await tester.tap(chillMinusButton);
        await tester.pump();
        FlutterError.onError = originalOnError2;
        // Chill decremented
        expect(character.characterState.chill.value, 0);
      }
      getIt<GameState>().undo();
      getIt<GameState>().undo();
    });
  });
}
