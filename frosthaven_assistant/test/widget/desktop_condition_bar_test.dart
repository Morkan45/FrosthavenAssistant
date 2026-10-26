import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_widget.dart';
import 'package:frosthaven_assistant/Layout/MonsterBox/monster_box.dart';
import 'package:frosthaven_assistant/Layout/desktop_condition_bar.dart';
import 'package:frosthaven_assistant/Layout/desktop_condition_scope.dart';
import 'package:frosthaven_assistant/Layout/main_scaffold.dart';
import 'package:frosthaven_assistant/Layout/menus/StatusMenu/status_menu.dart';
import 'package:frosthaven_assistant/Layout/view_models/desktop_conditions_view_model.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/draw_command.dart';
import 'package:frosthaven_assistant/Resource/commands/turn_done_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';

void main() {
  setUpAll(setUpGame);

  late GameState state;

  setUp(() {
    state = getIt<GameState>()..clearList();
    loading.value = false;
    RoundMethods.setRoundState(
      DrawCommand(gameState: state).stateAccess,
      RoundState.chooseInitiative,
      gameState: state,
    );
    final settings = getIt<Settings>();
    settings.userScalingBars.value = 1.6;
    settings.statusEffectScale.value = 2.0;
    settings.userScalingMainList.value = 1;
    settings.fitMainListToWidth.value = false;
    settings.mainListColumns.value = 0;
    settings.showCustomContent.value = true;
    settings.enableHeathWheel.value = false;
    AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
    AddCharacterCommand('Banner Spear', 'Frosthaven', null, 1).execute();
    AddMonsterCommand('Zealot', 1, false, gameState: state).execute();
    AddStandeeCommand(
      1,
      null,
      'Zealot',
      MonsterType.normal,
      false,
      gameState: state,
    ).execute();
    AddStandeeCommand(
      2,
      null,
      'Zealot',
      MonsterType.elite,
      false,
      gameState: state,
    ).execute();
    state.save();
    state.resetCommandHistory();
  });

  Future<void> pumpBoard(
    WidgetTester tester, {
    TargetPlatform platform = TargetPlatform.windows,
    Size size = const Size(1280, 720),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      testMaterialApp(
        home: Theme(
          data: ThemeData(platform: platform),
          child: const MainScaffold(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Character character(String id) =>
      state.currentList.whereType<Character>().firstWhere((c) => c.id == id);

  void startTurn(String id) {
    RoundMethods.setRoundState(
      DrawCommand(gameState: state).stateAccess,
      RoundState.playTurns,
      gameState: state,
    );
    state.action(TurnDoneCommand(id, gameState: state));
  }

  DesktopConditionsViewModel controls(WidgetTester tester) =>
      DesktopConditionScope.maybeOf(
        tester.element(find.byType(DesktopConditionBar)),
      )!;

  Finder source(Condition condition) =>
      find.byKey(ValueKey('condition-source-${condition.name}'));

  Finder target(String figureId, String ownerId) =>
      find.byKey(ValueKey('condition-target-$ownerId-$figureId'));

  Future<void> dragEffect(
    WidgetTester tester,
    Condition condition,
    Offset destination,
  ) async {
    await tester.ensureVisible(source(condition));
    await tester.pumpAndSettle();
    final origin = tester.getCenter(source(condition));
    final gesture = await tester.startGesture(
      origin,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(origin + const Offset(0, 12));
    await tester.pump();
    await gesture.moveTo(destination);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<TestPointer> startMouseDrag(
    WidgetTester tester,
    Condition condition,
    Offset destination,
  ) async {
    final pointer = TestPointer(31, PointerDeviceKind.mouse);
    await tester.ensureVisible(source(condition));
    await tester.pumpAndSettle();
    final origin = tester.getCenter(source(condition));
    await tester.sendEventToBinding(pointer.down(origin));
    await tester.sendEventToBinding(pointer.move(origin + const Offset(0, 24)));
    await tester.pump();
    await tester.sendEventToBinding(pointer.move(destination));
    await tester.pump();
    return pointer;
  }

  Future<void> buttons(
    WidgetTester tester,
    TestPointer pointer,
    int pressed,
  ) async {
    await tester.sendEventToBinding(
      pointer.move(pointer.location!, buttons: pressed),
    );
    await tester.pumpAndSettle();
  }

  Future<void> stickyClick(WidgetTester tester, TestPointer pointer) async {
    await buttons(tester, pointer, kPrimaryButton | kSecondaryButton);
    await buttons(tester, pointer, kSecondaryButton);
  }

  testWidgets('effects share the top bar and clicks follow the current turn', (
    tester,
  ) async {
    await pumpBoard(tester);
    expect(find.byType(DesktopConditionBar), findsOneWidget);
    expect(find.byType(Draggable<Condition>), findsNWidgets(13));
    expect(find.byKey(const Key('condition-character-picker')), findsNothing);
    expect(controls(tester).activeItem, isNull);
    final index = state.commandIndex.value;
    await tester.tap(source(Condition.stun));
    expect(state.commandIndex.value, index);
    startTurn('Blinkblade');
    await tester.pumpAndSettle();
    await tester.tap(source(Condition.stun));
    await tester.pumpAndSettle();
    expect(character('Blinkblade').characterState.conditions.value, [
      Condition.stun,
    ]);
    expect(
      tester.widget<IconButton>(source(Condition.stun)).isSelected,
      isTrue,
    );
    startTurn('Zealot');
    await tester.pumpAndSettle();
    expect(controls(tester).activeName, 'Zealot');
    await tester.tap(source(Condition.poison));
    await tester.pumpAndSettle();
    for (final standee
        in state.currentList.whereType<Monster>().single.monsterInstances) {
      expect(standee.conditions.value, [Condition.poison]);
    }
    final removalIndex = state.commandIndex.value;
    await tester.tap(source(Condition.poison));
    await tester.pumpAndSettle();
    expect(state.commandIndex.value, removalIndex + 1);
    for (final standee
        in state.currentList.whereType<Monster>().single.monsterInstances) {
      expect(standee.conditions.value, isEmpty);
    }
    state.undo();
    await tester.pumpAndSettle();
    for (final standee
        in state.currentList.whereType<Monster>().single.monsterInstances) {
      expect(standee.conditions.value, [Condition.poison]);
    }
    expect(character('Banner Spear').characterState.conditions.value, isEmpty);
    expect(
      tester.getCenter(source(Condition.poison)).dy,
      tester.getCenter(find.byKey(const Key('element-fire'))).dy,
    );
    expect(tester.getTopLeft(find.byType(MainScaffoldBody)).dy, 64);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'clicking an applied effect removes it and follows undo and redo',
    (tester) async {
      startTurn('Banner Spear');
      await pumpBoard(tester);
      await tester.tap(source(Condition.poison));
      await tester.pumpAndSettle();
      final index = state.commandIndex.value;
      await tester.tap(source(Condition.poison));
      await tester.pumpAndSettle();
      expect(state.commandIndex.value, index + 1);
      expect(
        character('Banner Spear').characterState.conditions.value,
        isEmpty,
      );
      expect(
        tester.widget<IconButton>(source(Condition.poison)).isSelected,
        isFalse,
      );
      state.undo();
      await tester.pumpAndSettle();
      expect(
        tester.widget<IconButton>(source(Condition.poison)).isSelected,
        isTrue,
      );
      state.redo();
      await tester.pumpAndSettle();
      expect(
        tester.widget<IconButton>(source(Condition.poison)).isSelected,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'mouse drags apply only to the dropped character without a selection',
    (tester) async {
      await pumpBoard(tester);
      await dragEffect(
        tester,
        Condition.wound,
        tester.getCenter(target('Banner Spear', 'Banner Spear')),
      );
      final bannerSpear = state.currentList.whereType<Character>().firstWhere(
        (c) => c.id == 'Banner Spear',
      );
      final blinkblade = state.currentList.whereType<Character>().firstWhere(
        (c) => c.id == 'Blinkblade',
      );
      expect(bannerSpear.characterState.conditions.value, [Condition.wound]);
      expect(blinkblade.characterState.conditions.value, isEmpty);
      expect(controls(tester).activeItem, isNull);
      expect(find.byType(StatusMenu), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mouse drags apply to one monster standee and leave other figures alone',
    (tester) async {
      await pumpBoard(tester);
      startTurn('Blinkblade');
      await tester.pump();
      final monster = state.currentList.whereType<Monster>().single;
      final standee = monster.monsterInstances.last;
      await dragEffect(
        tester,
        Condition.poison,
        tester.getCenter(target(standee.getId(), monster.id)),
      );
      expect(standee.conditions.value, [Condition.poison]);
      expect(monster.monsterInstances.first.conditions.value, isEmpty);
      expect(character('Blinkblade').characterState.conditions.value, isEmpty);
      expect(find.byType(StatusMenu), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('summons receive dropped effects independently of their owner', (
    tester,
  ) async {
    AddStandeeCommand(
      1,
      SummonData(1, 'Test Summon', 10, 2, 2, 0, 'BAN reinforcements'),
      'Blinkblade',
      MonsterType.summon,
      true,
      gameState: state,
    ).execute();
    await pumpBoard(tester);
    final character = state.currentList.whereType<Character>().firstWhere(
      (character) => character.id == 'Blinkblade',
    );
    final summon = character.characterState.summonList.single;
    await dragEffect(
      tester,
      Condition.strengthen,
      tester.getCenter(target(summon.getId(), character.id)),
    );
    expect(summon.conditions.value, [Condition.strengthen]);
    expect(character.characterState.conditions.value, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling a drag outside figures does not add an action', (
    tester,
  ) async {
    await pumpBoard(tester);
    final initialIndex = state.commandIndex.value;
    await dragEffect(tester, Condition.stun, const Offset(900, 550));
    expect(state.commandIndex.value, initialIndex);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'right-held sticky drag applies to several targets and ends without a final drop',
    (tester) async {
      await pumpBoard(tester);
      final monster = state.currentList.whereType<Monster>().single;
      final first = monster.monsterInstances.first;
      final untouched = monster.monsterInstances.last;
      final pointer = await startMouseDrag(
        tester,
        Condition.poison,
        tester.getCenter(target('Blinkblade', 'Blinkblade')),
      );
      final initialIndex = state.commandIndex.value;
      await stickyClick(tester, pointer);
      expect(controls(tester).isStickyDrag, isTrue);
      expect(find.byKey(const Key('sticky-condition-drag')), findsOneWidget);
      expect(state.commandIndex.value, initialIndex + 1);
      await stickyClick(tester, pointer);
      expect(state.commandIndex.value, initialIndex + 1);

      await tester.sendEventToBinding(
        pointer.move(tester.getCenter(target('Banner Spear', 'Banner Spear'))),
      );
      await tester.pump();
      expect(state.commandIndex.value, initialIndex + 1);
      await stickyClick(tester, pointer);
      await tester.sendEventToBinding(
        pointer.move(tester.getCenter(target(first.getId(), monster.id))),
      );
      await tester.pump();
      await stickyClick(tester, pointer);
      expect(first.conditions.value, [Condition.poison]);
      for (final character in state.currentList.whereType<Character>()) {
        expect(character.characterState.conditions.value, [Condition.poison]);
      }
      expect(state.commandIndex.value, initialIndex + 3);
      expect(find.byType(StatusMenu), findsNothing);

      await tester.sendEventToBinding(
        pointer.move(tester.getCenter(target(untouched.getId(), monster.id))),
      );
      await tester.pump();
      await tester.sendEventToBinding(pointer.up());
      await tester.pumpAndSettle();
      expect(untouched.conditions.value, isEmpty);
      expect(state.commandIndex.value, initialIndex + 3);
      expect(controls(tester).draggedCondition, isNull);
      expect(find.byKey(const Key('sticky-condition-drag')), findsNothing);
      state.undo();
      await tester.pumpAndSettle();
      expect(
        state.currentList
            .whereType<Monster>()
            .single
            .monsterInstances
            .firstWhere((standee) => standee.getId() == first.getId())
            .conditions
            .value,
        isEmpty,
      );
      expect(controls(tester).activeItem, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sticky clicks never duplicate an effect or apply again on right release',
    (tester) async {
      await pumpBoard(tester);
      final character = state.currentList.whereType<Character>().first;
      final pointer = await startMouseDrag(
        tester,
        Condition.wound,
        tester.getCenter(target(character.id, character.id)),
      );
      await stickyClick(tester, pointer);
      expect(character.characterState.conditions.value, [Condition.wound]);
      await stickyClick(tester, pointer);
      expect(character.characterState.conditions.value, [Condition.wound]);
      final initialIndex = state.commandIndex.value;
      await tester.sendEventToBinding(pointer.up());
      await tester.pumpAndSettle();
      expect(character.characterState.conditions.value, [Condition.wound]);
      expect(state.commandIndex.value, initialIndex);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sticky drag survives immune and empty targets so the next valid click still applies',
    (tester) async {
      getIt<Settings>().fitMainListToWidth.value = true;
      getIt<Settings>().mainListColumns.value = 2;
      AddMonsterCommand('Blood Tumor', 1, false, gameState: state).execute();
      AddStandeeCommand(
        1,
        null,
        'Blood Tumor',
        MonsterType.boss,
        false,
        gameState: state,
      ).execute();
      await pumpBoard(tester);
      final boss = state.currentList.whereType<Monster>().firstWhere(
        (m) => m.id == 'Blood Tumor',
      );
      final pointer = await startMouseDrag(
        tester,
        Condition.stun,
        tester.getCenter(target(boss.monsterInstances.single.getId(), boss.id)),
      );
      final initialIndex = state.commandIndex.value;
      await stickyClick(tester, pointer);
      expect(controls(tester).isStickyDrag, isTrue);
      expect(boss.monsterInstances.single.conditions.value, isEmpty);
      expect(state.commandIndex.value, initialIndex);
      await tester.sendEventToBinding(pointer.move(const Offset(900, 550)));
      await tester.pump();
      await stickyClick(tester, pointer);
      expect(state.commandIndex.value, initialIndex);

      await tester.sendEventToBinding(
        pointer.move(tester.getCenter(target('Blinkblade', 'Blinkblade'))),
      );
      await tester.pump();
      await stickyClick(tester, pointer);
      expect(
        state.currentList
            .whereType<Character>()
            .firstWhere((c) => c.id == 'Blinkblade')
            .characterState
            .conditions
            .value,
        [Condition.stun],
      );
      await tester.sendEventToBinding(pointer.up());
      await tester.pumpAndSettle();
      expect(find.byType(StatusMenu), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'releasing right while left is still held cancels remaining sticky drops',
    (tester) async {
      await pumpBoard(tester);
      final pointer = await startMouseDrag(
        tester,
        Condition.wound,
        tester.getCenter(target('Blinkblade', 'Blinkblade')),
      );
      await stickyClick(tester, pointer);
      await tester.sendEventToBinding(
        pointer.move(tester.getCenter(target('Banner Spear', 'Banner Spear'))),
      );
      await tester.pump();
      await buttons(tester, pointer, kPrimaryButton | kSecondaryButton);
      await buttons(tester, pointer, kPrimaryButton);
      expect(controls(tester).isDragCancelled, isTrue);
      expect(find.byKey(const Key('sticky-condition-drag')), findsNothing);
      final initialIndex = state.commandIndex.value;
      await tester.sendEventToBinding(pointer.up());
      await tester.pumpAndSettle();
      expect(state.commandIndex.value, initialIndex);

      await dragEffect(
        tester,
        Condition.wound,
        tester.getCenter(target('Banner Spear', 'Banner Spear')),
      );
      expect(state.commandIndex.value, initialIndex + 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'releasing right before the first left release keeps a normal single drop',
    (tester) async {
      await pumpBoard(tester);
      final character = state.currentList.whereType<Character>().first;
      final pointer = await startMouseDrag(
        tester,
        Condition.wound,
        tester.getCenter(target(character.id, character.id)),
      );
      await buttons(tester, pointer, kPrimaryButton | kSecondaryButton);
      await buttons(tester, pointer, kPrimaryButton);
      expect(controls(tester).isStickyDrag, isFalse);
      expect(character.characterState.conditions.value, isEmpty);
      await tester.sendEventToBinding(pointer.up());
      await tester.pumpAndSettle();
      expect(character.characterState.conditions.value, [Condition.wound]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pointer cancellation ends a sticky drag without applying again',
    (tester) async {
      await pumpBoard(tester);
      final pointer = await startMouseDrag(
        tester,
        Condition.wound,
        tester.getCenter(target('Blinkblade', 'Blinkblade')),
      );
      await stickyClick(tester, pointer);
      final initialIndex = state.commandIndex.value;
      await tester.sendEventToBinding(pointer.cancel());
      await tester.pumpAndSettle();
      expect(state.commandIndex.value, initialIndex);
      expect(controls(tester).draggedCondition, isNull);
      expect(find.byKey(const Key('sticky-condition-drag')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'changing turns during a sticky drag keeps its individual target',
    (tester) async {
      await pumpBoard(tester);
      final pointer = await startMouseDrag(
        tester,
        Condition.wound,
        tester.getCenter(target('Blinkblade', 'Blinkblade')),
      );
      await stickyClick(tester, pointer);
      startTurn('Zealot');
      await tester.pumpAndSettle();
      expect(controls(tester).isStickyDrag, isTrue);
      await tester.sendEventToBinding(
        pointer.move(tester.getCenter(target('Banner Spear', 'Banner Spear'))),
      );
      await tester.pump();
      await stickyClick(tester, pointer);
      await tester.sendEventToBinding(pointer.up());
      await tester.pumpAndSettle();
      expect(character('Banner Spear').characterState.conditions.value, [
        Condition.wound,
      ]);
      for (final standee
          in state.currentList.whereType<Monster>().single.monsterInstances) {
        expect(standee.conditions.value, isEmpty);
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('right-button dragging alone does not start an effect drag', (
    tester,
  ) async {
    await pumpBoard(tester);
    final pointer = TestPointer(31, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.down(
        tester.getCenter(source(Condition.poison)),
        buttons: kSecondaryButton,
      ),
    );
    await tester.sendEventToBinding(
      pointer.move(tester.getCenter(target('Blinkblade', 'Blinkblade'))),
    );
    await tester.pump();
    final initialIndex = state.commandIndex.value;
    await tester.sendEventToBinding(pointer.up());
    await tester.pumpAndSettle();
    expect(state.commandIndex.value, initialIndex);
    expect(controls(tester).draggedCondition, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an effect already applied to the current character can still be dragged',
    (tester) async {
      await pumpBoard(tester);
      startTurn('Blinkblade');
      controls(tester).toggleActive(Condition.poison);
      await tester.pump();
      expect(
        tester.widget<IconButton>(source(Condition.poison)).onPressed,
        isNotNull,
      );

      final monster = state.currentList.whereType<Monster>().single;
      final standee = monster.monsterInstances.first;
      await dragEffect(
        tester,
        Condition.poison,
        tester.getCenter(target(standee.getId(), monster.id)),
      );
      expect(standee.conditions.value, [Condition.poison]);
      expect(character('Blinkblade').characterState.conditions.value, [
        Condition.poison,
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'drag hover highlights valid targets and rejects immune monsters',
    (tester) async {
      getIt<Settings>().fitMainListToWidth.value = true;
      getIt<Settings>().mainListColumns.value = 2;
      AddMonsterCommand('Blood Tumor', 1, false, gameState: state).execute();
      AddStandeeCommand(
        1,
        null,
        'Blood Tumor',
        MonsterType.boss,
        false,
        gameState: state,
      ).execute();
      await pumpBoard(tester);
      final boss = state.currentList.whereType<Monster>().firstWhere(
        (m) => m.id == 'Blood Tumor',
      );
      final bossTarget = target(boss.monsterInstances.single.getId(), boss.id);
      expect(bossTarget.hitTestable(), findsOneWidget);
      final origin = tester.getCenter(source(Condition.stun));
      final gesture = await tester.startGesture(
        origin,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(origin + const Offset(0, 12));
      await tester.pump();
      await gesture.moveTo(
        tester.getCenter(target('Blinkblade', 'Blinkblade')),
      );
      await tester.pump();
      BoxBorder border(Finder finder) =>
          (tester.widget<DecoratedBox>(finder).decoration as BoxDecoration)
              .border!;
      expect(
        border(target('Blinkblade', 'Blinkblade')).top.color,
        Colors.greenAccent.shade400,
      );

      await gesture.moveTo(tester.getCenter(bossTarget));
      await tester.pump();
      expect(border(bossTarget).top.color, Colors.redAccent);
      final initialIndex = state.commandIndex.value;
      await gesture.up();
      await tester.pumpAndSettle();
      expect(boss.monsterInstances.single.conditions.value, isEmpty);
      expect(state.commandIndex.value, initialIndex);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('objective hover rejects harmful and helpful condition drops', (
    tester,
  ) async {
    AddCharacterCommand('Objective', 'na', 'Raven Nest a', 1).execute();
    await pumpBoard(tester);
    final objective = character('Raven Nest a');
    final objectiveTarget = target(objective.id, objective.id);
    final initialIndex = state.commandIndex.value;
    for (final condition in [Condition.poison, Condition.ward]) {
      final pointer = await startMouseDrag(
        tester,
        condition,
        tester.getCenter(objectiveTarget),
      );
      final decoration =
          tester.widget<DecoratedBox>(objectiveTarget).decoration
              as BoxDecoration;
      expect(decoration.border!.top.color, Colors.redAccent);
      await tester.sendEventToBinding(pointer.up());
      await tester.pumpAndSettle();
      expect(objective.characterState.conditions.value, isEmpty);
      expect(state.commandIndex.value, initialIndex);
    }
    expect(find.byType(StatusMenu), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sticky drags skip objectives and continue to valid figures', (
    tester,
  ) async {
    AddCharacterCommand('Objective', 'na', 'Raven Nest a', 1).execute();
    await pumpBoard(tester);
    final objective = character('Raven Nest a');
    final initialIndex = state.commandIndex.value;
    final pointer = await startMouseDrag(
      tester,
      Condition.stun,
      tester.getCenter(target(objective.id, objective.id)),
    );
    await stickyClick(tester, pointer);
    expect(controls(tester).isStickyDrag, isTrue);
    expect(objective.characterState.conditions.value, isEmpty);
    expect(state.commandIndex.value, initialIndex);

    await tester.sendEventToBinding(
      pointer.move(tester.getCenter(target('Blinkblade', 'Blinkblade'))),
    );
    await tester.pump();
    await stickyClick(tester, pointer);
    expect(character('Blinkblade').characterState.conditions.value, [
      Condition.stun,
    ]);
    expect(objective.characterState.conditions.value, isEmpty);
    expect(state.commandIndex.value, initialIndex + 1);
    await tester.sendEventToBinding(pointer.up());
    await tester.pumpAndSettle();
    expect(find.byType(StatusMenu), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('status sizing preserves small and large app bar heights', (
    tester,
  ) async {
    await pumpBoard(tester);
    final settings = getIt<Settings>();
    for (final scale in [0.2, 1.0, 1.6, 3.0]) {
      settings.userScalingBars.value = scale;
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(MainScaffoldBody)).dy, 40 * scale);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('desktop scrollbar reveals late effects without applying them', (
    tester,
  ) async {
    await pumpBoard(tester, size: const Size(900, 720));
    final scrollbar = find.descendant(
      of: find.byType(DesktopConditionBar),
      matching: find.byType(Scrollbar),
    );
    final controller = tester.widget<Scrollbar>(scrollbar).controller!;
    final index = state.commandIndex.value;
    final rect = tester.getRect(scrollbar);
    await tester.dragFrom(
      Offset(rect.left + 20, rect.bottom - 3),
      Offset(rect.width, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    expect(source(Condition.ward).hitTestable(), findsOneWidget);
    expect(state.commandIndex.value, index);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all effects remain reachable without overlap across desktop widths',
    (tester) async {
      await pumpBoard(tester);
      for (final width in [600.0, 900.0, 1280.0, 1920.0, 2560.0]) {
        tester.view.physicalSize = Size(width, 720);
        await tester.pumpAndSettle();
        final effects = controls(tester).conditions;
        for (var i = 1; i < effects.length; i++) {
          expect(
            tester.getRect(source(effects[i])).left,
            greaterThanOrEqualTo(tester.getRect(source(effects[i - 1])).right),
          );
        }
        for (final condition in effects) {
          await tester.ensureVisible(source(condition));
          await tester.pumpAndSettle();
          expect(
            source(condition).hitTestable(),
            findsOneWidget,
            reason: '$condition at $width',
          );
        }
        expect(tester.getTopLeft(find.byType(MainScaffoldBody)).dy, 64);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'size changes live and reserves horizontal space without changing bar height',
    (tester) async {
      await pumpBoard(tester, size: const Size(1920, 720));
      final settings = getIt<Settings>();
      final defaultWidth = tester.getSize(source(Condition.stun)).width;
      final icon = find.descendant(
        of: source(Condition.stun),
        matching: find.byType(Image),
      );
      final defaultIconSize = tester.getSize(icon);
      expect(defaultIconSize.width, closeTo(52, 0.1));

      settings.statusEffectScale.value = 1;
      await tester.pumpAndSettle();
      expect(
        defaultIconSize.width,
        closeTo(2 * tester.getSize(icon).width, 0.1),
      );
      expect(
        defaultWidth,
        greaterThan(tester.getSize(source(Condition.stun)).width),
      );
      expect(tester.getTopLeft(find.byType(MainScaffoldBody)).dy, 64);

      for (final scale in [0.5, 1.0, 2.0, 3.0]) {
        settings.statusEffectScale.value = scale;
        await tester.pumpAndSettle();
        final effects = controls(tester).conditions;
        for (var i = 1; i < effects.length; i++) {
          expect(
            tester.getRect(source(effects[i])).left,
            greaterThanOrEqualTo(tester.getRect(source(effects[i - 1])).right),
          );
        }
        expect(tester.getTopLeft(find.byType(MainScaffoldBody)).dy, 64);
        expect(tester.takeException(), isNull);
      }
    },
  );

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      'mobile has no toolbar, selection affordance or drop targets on $platform',
      (tester) async {
        await pumpBoard(tester, platform: platform);
        expect(find.byType(DesktopConditionBar), findsNothing);
        expect(find.byType(Draggable<Condition>), findsNothing);
        expect(find.byType(DragTarget<Condition>), findsNothing);
        expect(
          find.byKey(const ValueKey('condition-select-Blinkblade')),
          findsNothing,
        );
        expect(find.byType(CharacterWidget), findsNWidgets(2));
        expect(find.byType(MonsterBox), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
