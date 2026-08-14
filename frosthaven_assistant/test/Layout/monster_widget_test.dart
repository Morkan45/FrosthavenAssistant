// ignore_for_file: avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/MonsterAbilityCardWidget/monster_ability_card_widget.dart';
import 'package:frosthaven_assistant/Layout/MonsterBox/monster_box.dart';
import 'package:frosthaven_assistant/Layout/MonsterBox/monster_health_slider_controller.dart';
import 'package:frosthaven_assistant/Layout/MonsterStatCardWidget/monster_stat_card_widget.dart';
import 'package:frosthaven_assistant/Layout/MonsterWidget/monster_widget.dart';
import 'package:frosthaven_assistant/Layout/menus/StatusMenu/status_menu.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
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
    final originalOnError = FlutterError.onError;
    addTearDown(() => FlutterError.onError = originalOnError);
    FlutterError.onError = ignoreOverflowErrors(FlutterError.onError);
    await tester.pumpWidget(
      testMaterialApp(
        home: Scaffold(body: MonsterWidget(data: monster)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    FlutterError.onError = originalOnError;
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

    testWidgets('tapping a standee opens the vertical health slider', (
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
      await tester.tap(find.byType(MonsterBox));
      await tester.pump();

      expect(
        find.byKey(Key('monster-health-slider-$figureId')),
        findsOneWidget,
      );
      expect(find.byType(StatusMenu), findsNothing);
    });

    testWidgets('vertical slider uses deliberate travel and is undoable', (
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
      final initialHealth = standee.health.value;
      state.resetCommandHistory();
      state.save();

      await pumpWidget(tester);
      final target = find.byKey(Key('monster-health-target-$figureId'));
      await tester.tap(target);
      await tester.pump();

      final slider = find.byKey(Key('monster-health-slider-drag-$figureId'));
      final scale = getScaleByReference(tester.element(slider));
      final step = MonsterHealthSliderController.dragExtentPerHealth * scale;

      // Less than the explicit threshold does not change one hit point.
      await tester.drag(slider, Offset(0, step * 0.75));
      await tester.pump();
      expect(standee.health.value, initialHealth);

      await tester.tap(target);
      await tester.pump();
      await tester.drag(
        find.byKey(Key('monster-health-slider-drag-$figureId')),
        Offset(0, step * 1.25),
      );
      await tester.pump();

      expect(standee.health.value, initialHealth - 1);
      await tester.pumpWidget(testMaterialApp(home: const SizedBox.shrink()));
      state.undo();
      final restoredMonster = state.currentList.single as Monster;
      expect(
        restoredMonster.monsterInstances.single.health.value,
        initialHealth,
      );
    });

    testWidgets('health slider retains access to the full status menu', (
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
      await tester.tap(find.byType(MonsterBox));
      await tester.pump();
      await tester.tap(find.byKey(Key('monster-health-details-$figureId')));
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

      await pumpWidget(tester);
      await tester.tap(find.byType(MonsterBox));
      await tester.pumpWidget(testMaterialApp(home: const SizedBox.shrink()));

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
