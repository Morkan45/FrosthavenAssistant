import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_widget.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_widget_internal.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/objective_immunities.dart';
import 'package:frosthaven_assistant/Layout/counter_button.dart';
import 'package:frosthaven_assistant/Layout/menus/StatusMenu/status_menu.dart';
import 'package:frosthaven_assistant/Layout/menus/condition_button.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/draw_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';

void main() {
  setUpAll(setUpGame);

  late GameState state;
  late Character objective;

  setUp(() {
    state = getIt<GameState>()..clearList();
    final settings = getIt<Settings>();
    settings.fitMainListToWidth.value = true;
    settings.mainListColumns.value = 1;
    settings.enableHeathWheel.value = false;
    settings.showAmdDeck.value = true;
    settings.showCharacterAMD.value = true;
    AddCharacterCommand('Objective', 'na', 'Raven Nest a', 1).execute();
    objective = state.currentList.single as Character;
    final access = DrawCommand(gameState: state).stateAccess;
    objective.characterState.setMaxHealth(access, 72);
    objective.characterState.setHealth(access, 72);
    state.save();
    state.resetCommandHistory();
  });

  Future<void> pumpObjective(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      testMaterialApp(
        home: Scaffold(body: CharacterWidget(characterId: objective.id)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('objective HP buttons support limits, revival, and undo', (
    tester,
  ) async {
    await pumpObjective(tester);
    final decrease = find.byKey(const Key('character-health-decrease'));
    final increase = find.byKey(const Key('character-health-increase'));
    IconButton button(Finder finder) => tester.widget<IconButton>(
      find.descendant(of: finder, matching: find.byType(IconButton)),
    );

    expect(button(increase).onPressed, isNull);
    await tester.tap(decrease);
    await tester.pump();
    expect(objective.characterState.health.value, 71);
    expect(find.text('-1'), findsOneWidget);
    expect(find.byType(StatusMenu), findsNothing);
    await tester.tap(increase);
    await tester.pump();
    expect(objective.characterState.health.value, 72);
    state.undo();
    await tester.pump();
    expect(objective.characterState.health.value, 71);
    state.redo();
    await tester.pump();
    expect(objective.characterState.health.value, 72);

    objective.characterState.setHealth(
      DrawCommand(gameState: state).stateAccess,
      1,
    );
    await tester.pump();
    await tester.tap(decrease);
    await tester.pumpAndSettle();
    expect(objective.characterState.health.value, 0);
    expect(button(decrease).onPressed, isNull);
    expect(button(increase).onPressed, isNotNull);
    await tester.tap(increase);
    await tester.pump();
    expect(objective.characterState.health.value, 1);
    expect(find.byType(StatusMenu), findsNothing);
  });

  testWidgets('immunity indicator and controls fit narrow and wide bars', (
    tester,
  ) async {
    await pumpObjective(tester);
    for (final width in [412.0, 914.0, 1920.0]) {
      tester.view.physicalSize = Size(width, 915);
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byType(CharacterWidgetInternal));
      final immunity = tester.getRect(find.byType(ObjectiveImmunities));
      final decrease = tester.getRect(
        find.byKey(const Key('character-health-decrease')),
      );
      final increase = tester.getRect(
        find.byKey(const Key('character-health-increase')),
      );
      final details = tester.getRect(
        find.byKey(const Key('character-details-column')),
      );
      expect(find.text('All conditions'), findsOneWidget);
      expect(immunity.left, closeTo(details.right, 0.01));
      expect(immunity.right, lessThanOrEqualTo(decrease.left));
      expect(immunity.top, greaterThanOrEqualTo(bar.top));
      expect(immunity.bottom, lessThanOrEqualTo(bar.bottom));
      expect(increase.right, lessThanOrEqualTo(bar.right));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('objective status menu disables harmful and helpful conditions', (
    tester,
  ) async {
    await pumpObjective(tester);
    await tester.tap(find.text('Raven Nest a'));
    await tester.pumpAndSettle();
    expect(find.byType(StatusMenu), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CounterButton &&
            (widget.image.endsWith('/bless.png') ||
                widget.image.endsWith('/curse.png')),
      ),
      findsNothing,
    );
    for (final condition in [
      Condition.stun,
      Condition.poison,
      Condition.bane,
      Condition.brittle,
      Condition.strengthen,
      Condition.invisible,
      Condition.regenerate,
      Condition.ward,
    ]) {
      final conditionButton = find.byWidgetPredicate(
        (widget) => widget is ConditionButton && widget.condition == condition,
      );
      final button = tester.widget<IconButton>(
        find.descendant(of: conditionButton, matching: find.byType(IconButton)),
      );
      expect(button.onPressed, isNull, reason: condition.name);
    }
    expect(objective.characterState.conditions.value, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
