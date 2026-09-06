// ignore_for_file: avoid-late-keyword

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/MonsterAbilityCardWidget/monster_ability_card_widget.dart';
import 'package:frosthaven_assistant/Layout/MonsterBox/monster_health_slider_controller.dart';
import 'package:frosthaven_assistant/Layout/MonsterStatCardWidget/monster_stat_card_widget.dart';
import 'package:frosthaven_assistant/Layout/MonsterWidget/monster_widget.dart';
import 'package:frosthaven_assistant/Layout/menus/StatusMenu/status_menu.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/commands/change_stat_commands/change_health_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/scaling.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  late Monster monster;

  setUp(() {
    getIt<GameState>().clearList();
    AddMonsterCommand(
      'Zealot',
      1,
      false,
      gameState: getIt<GameState>(),
    ).execute();
    monster =
        getIt<GameState>().currentList.firstWhere((e) => e is Monster)
            as Monster;
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      testMaterialApp(
        home: Scaffold(body: MonsterWidget(data: monster)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('MonsterWidget', () {
    testWidgets('renders monster type display name', (
      WidgetTester tester,
    ) async {
      await pumpWidget(tester);
      expect(find.textContaining(monster.type.display), findsAtLeast(1));
    });

    testWidgets('renders MonsterAbilityCardWidget', (
      WidgetTester tester,
    ) async {
      await pumpWidget(tester);
      expect(find.byType(MonsterAbilityCardWidget), findsOneWidget);
    });

    testWidgets('renders MonsterStatCardWidget', (WidgetTester tester) async {
      await pumpWidget(tester);
      expect(find.byType(MonsterStatCardWidget), findsOneWidget);
    });

    testWidgets('renders without error when monster has no standees', (
      WidgetTester tester,
    ) async {
      await pumpWidget(tester);
      // No standees, but widget should still render without exception
      expect(find.byType(MonsterWidget), findsOneWidget);
    });

    testWidgets('renders Wrap for monster box grid', (
      WidgetTester tester,
    ) async {
      await pumpWidget(tester);
      expect(find.byType(Wrap), findsAtLeast(1));
    });

    testWidgets('pressing monster HP immediately opens the relative slider', (
      WidgetTester tester,
    ) async {
      AddStandeeCommand(
        1,
        null,
        monster.id,
        MonsterType.normal,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      final figureId = monster.monsterInstances.single.getId();

      await pumpWidget(tester);
      final target = find.byKey(Key('monster-health-target-$figureId'));
      final gesture = await tester.startGesture(
        tester.getCenter(target),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();

      expect(
        find.byKey(Key('monster-health-slider-$figureId')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('monster-health-delta-$figureId-0')),
        findsOneWidget,
      );
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('-1'), findsOneWidget);
      expect(find.byType(StatusMenu), findsNothing);

      await gesture.up();
      await tester.pump();
      expect(find.byKey(Key('monster-health-slider-$figureId')), findsNothing);
    });

    testWidgets('dragging HP upward selects a positive undoable change', (
      WidgetTester tester,
    ) async {
      final state = getIt<GameState>();
      AddStandeeCommand(
        1,
        null,
        monster.id,
        MonsterType.normal,
        false,
        gameState: state,
      ).execute();
      final standee = monster.monsterInstances.single;
      final figureId = standee.getId();
      ChangeHealthCommand(-2, figureId, monster.id, gameState: state).execute();
      final initialHealth = standee.health.value;
      state.resetCommandHistory();
      state.save();

      await pumpWidget(tester);
      final target = find.byKey(Key('monster-health-target-$figureId'));
      final scale = getScaleByReference(tester.element(target));
      final step = MonsterHealthSliderController.dragExtentPerHealth * scale;
      final gesture = await tester.startGesture(
        tester.getCenter(target),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();

      // Less than the explicit threshold does not change one hit point.
      await gesture.moveBy(Offset(0, -step * 0.75));
      await tester.pump();
      expect(standee.health.value, initialHealth);
      final zero = tester.widget<Text>(
        find.byKey(Key('monster-health-delta-$figureId-0')),
      );
      expect(zero.style?.color, Colors.redAccent);

      await gesture.moveBy(Offset(0, -step * 0.5));
      await tester.pump();
      final positiveOne = tester.widget<Text>(
        find.byKey(Key('monster-health-delta-$figureId-1')),
      );
      expect(positiveOne.data, '+1');
      expect(positiveOne.style?.color, Colors.redAccent);
      expect(standee.health.value, initialHealth);

      await gesture.up();
      await tester.pump();

      expect(standee.health.value, initialHealth + 1);
      expect(find.byKey(Key('monster-health-slider-$figureId')), findsNothing);
      await tester.pumpWidget(testMaterialApp(home: const SizedBox.shrink()));
      state.undo();
      final restoredMonster = state.currentList.single as Monster;
      expect(
        restoredMonster.monsterInstances.single.health.value,
        initialHealth,
      );
    });

    testWidgets('dragging HP downward selects a negative change', (
      WidgetTester tester,
    ) async {
      AddStandeeCommand(
        1,
        null,
        monster.id,
        MonsterType.normal,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      final standee = monster.monsterInstances.single;
      final figureId = standee.getId();
      final initialHealth = standee.health.value;

      await pumpWidget(tester);
      final target = find.byKey(Key('monster-health-target-$figureId'));
      final scale = getScaleByReference(tester.element(target));
      final step = MonsterHealthSliderController.dragExtentPerHealth * scale;
      final gesture = await tester.startGesture(
        tester.getCenter(target),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveBy(Offset(0, step * 1.25));
      await tester.pump();

      final negativeOne = tester.widget<Text>(
        find.byKey(Key('monster-health-delta-$figureId--1')),
      );
      expect(negativeOne.data, '-1');
      final selectedValues = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(Key('monster-health-slider-$figureId')),
              matching: find.byType(Text),
            ),
          )
          .where((text) => text.style?.color == Colors.redAccent)
          .map((text) => text.data)
          .toList();
      expect(selectedValues, ['-1']);
      expect(standee.health.value, initialHealth);

      await gesture.up();
      await tester.pump();
      expect(standee.health.value, initialHealth - 1);
    });

    testWidgets('tapping the standee number opens the full status menu', (
      WidgetTester tester,
    ) async {
      AddStandeeCommand(
        1,
        null,
        monster.id,
        MonsterType.normal,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      final figureId = monster.monsterInstances.single.getId();

      await pumpWidget(tester);
      await tester.tap(find.byKey(Key('monster-status-target-$figureId')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(Key('monster-health-slider-$figureId')), findsNothing);
      expect(find.byType(StatusMenu), findsOneWidget);
    });

    testWidgets('same-frame removal safely disposes an inserted overlay', (
      WidgetTester tester,
    ) async {
      AddStandeeCommand(
        1,
        null,
        monster.id,
        MonsterType.normal,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      final figureId = monster.monsterInstances.single.getId();

      await pumpWidget(tester);
      final target = find.byKey(Key('monster-health-target-$figureId'));
      final gesture = await tester.startGesture(
        tester.getCenter(target),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpWidget(testMaterialApp(home: const SizedBox.shrink()));
      await gesture.cancel();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Column as root layout', (WidgetTester tester) async {
      await pumpWidget(tester);
      expect(find.byType(Column), findsAtLeast(1));
    });

    testWidgets('tapping image in playTurns state wraps image in InkWell', (
      WidgetTester tester,
    ) async {
      // Add a standee so the monster has instances
      AddStandeeCommand(
        1,
        null,
        monster.id,
        MonsterType.normal,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      (getIt<GameState>().roundState as ValueNotifier<RoundState>).value =
          RoundState.playTurns;

      await pumpWidget(tester);

      // InkWell wrapping the image is present during playTurns when instances exist
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsAtLeast(1));

      // restore
      getIt<GameState>().clearList();
      AddMonsterCommand(
        'Zealot',
        1,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      monster =
          getIt<GameState>().currentList.firstWhere((e) => e is Monster)
              as Monster;
      (getIt<GameState>().roundState as ValueNotifier<RoundState>).value =
          RoundState.chooseInitiative;
    });

    testWidgets('monster image is shown via AssetImage', (
      WidgetTester tester,
    ) async {
      await pumpWidget(tester);
      expect(find.byType(Image), findsAtLeast(1));
    });

    testWidgets('renders ColorFiltered widget for active state', (
      WidgetTester tester,
    ) async {
      await pumpWidget(tester);
      expect(find.byType(ColorFiltered), findsAtLeast(1));
    });
  });
}
