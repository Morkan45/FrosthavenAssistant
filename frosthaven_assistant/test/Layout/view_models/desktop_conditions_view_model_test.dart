import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/view_models/desktop_conditions_view_model.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/commands/draw_command.dart';
import 'package:frosthaven_assistant/Resource/commands/turn_done_command.dart';
import 'package:frosthaven_assistant/Resource/commands/remove_character_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../../command/test_helpers.dart';

void main() {
  setUpAll(setUpGame);
  late GameState state;
  late DesktopConditionsViewModel controls;

  setUp(() {
    state = getIt<GameState>()..clearList();
    RoundMethods.setRoundState(
      DrawCommand(gameState: state).stateAccess,
      RoundState.chooseInitiative,
      gameState: state,
    );
    AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
    AddCharacterCommand('Banner Spear', 'Frosthaven', null, 1).execute();
    state.save();
    state.resetCommandHistory();
    controls = DesktopConditionsViewModel();
  });
  tearDown(() => controls.dispose());

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

  test('clicks follow the current turn and follow undo and redo', () {
    final initialIndex = state.commandIndex.value;
    expect(controls.activeItem, isNull);
    controls.toggleActive(Condition.stun);
    expect(state.commandIndex.value, initialIndex);
    startTurn('Banner Spear');
    expect(controls.activeItem?.id, 'Banner Spear');
    controls.toggleActive(Condition.poison);
    expect(character('Banner Spear').characterState.conditions.value, [
      Condition.poison,
    ]);
    expect(character('Blinkblade').characterState.conditions.value, isEmpty);
    state.action(TurnDoneCommand('Banner Spear', gameState: state));
    expect(controls.activeItem?.id, 'Blinkblade');
    controls.toggleActive(Condition.wound);
    expect(character('Blinkblade').characterState.conditions.value, [
      Condition.wound,
    ]);
    state.undo();
    state.undo();
    expect(controls.activeItem?.id, 'Banner Spear');
    state.redo();
    expect(controls.activeItem?.id, 'Blinkblade');
  });

  test(
    'a second click clears the effect and turn tracking with undo and redo',
    () {
      startTurn('Blinkblade');
      controls.toggleActive(Condition.poison);
      expect(controls.isApplied(Condition.poison), isTrue);
      expect(controls.canToggleActive(Condition.poison), isTrue);
      expect(
        character('Blinkblade').characterState.conditionsAddedThisTurn,
        contains(Condition.poison),
      );
      final index = state.commandIndex.value;
      controls.toggleActive(Condition.poison);
      expect(state.commandIndex.value, index + 1);
      expect(character('Blinkblade').characterState.conditions.value, isEmpty);
      expect(
        character('Blinkblade').characterState.conditionsAddedThisTurn,
        isNot(contains(Condition.poison)),
      );
      expect(controls.isApplied(Condition.poison), isFalse);
      state.undo();
      expect(controls.isApplied(Condition.poison), isTrue);
      state.redo();
      expect(controls.isApplied(Condition.poison), isFalse);
      controls.toggleActive(Condition.poison);
      expect(controls.isApplied(Condition.poison), isTrue);
    },
  );

  test('drops target a single figure independently of the current turn', () {
    startTurn('Blinkblade');
    controls.apply(Condition.wound, 'Banner Spear', 'Banner Spear');
    expect(character('Blinkblade').characterState.conditions.value, isEmpty);
    expect(character('Banner Spear').characterState.conditions.value, [
      Condition.wound,
    ]);
    expect(controls.activeItem?.id, 'Blinkblade');
  });

  test(
    'ordinary and sticky drops reject every basic condition on objectives',
    () {
      AddCharacterCommand('Objective', 'na', 'Raven Nest a', 1).execute();
      final objective = character('Raven Nest a');
      final index = state.commandIndex.value;
      for (final condition in controls.conditions) {
        expect(
          controls.canApply(condition, objective.id, objective.id),
          isFalse,
        );
        controls.acceptDrop(condition, objective.id, objective.id);
        controls.beginDrag(condition);
        controls.hoverTarget(objective.id, objective.id);
        controls.stickyDrop();
        controls.endDrag();
      }
      expect(objective.characterState.conditions.value, isEmpty);
      expect(state.commandIndex.value, index);
      controls.apply(Condition.poison, 'Blinkblade', 'Blinkblade');
      expect(character('Blinkblade').characterState.conditions.value, [
        Condition.poison,
      ]);
    },
  );

  void addStandees(String name, MonsterType type) {
    AddMonsterCommand(name, 1, false, gameState: state).execute();
    for (final nr in [1, 2]) {
      AddStandeeCommand(
        nr,
        null,
        name,
        type,
        false,
        gameState: state,
      ).execute();
    }
  }

  test('monster turns apply to all living standees in one undo step', () {
    addStandees('Zealot', MonsterType.normal);
    startTurn('Zealot');
    final monster = state.currentList.whereType<Monster>().single;
    final first = monster.monsterInstances.first;
    controls.apply(Condition.poison, first.getId(), monster.id);
    final index = state.commandIndex.value;
    expect(controls.isApplied(Condition.poison), isFalse);
    controls.toggleActive(Condition.poison);
    expect(state.commandIndex.value, index + 1);
    expect(controls.isApplied(Condition.poison), isTrue);
    state.undo();
    expect(controls.isApplied(Condition.poison), isFalse);
    controls.toggleActive(Condition.wound);
    for (final standee in monster.monsterInstances) {
      expect(standee.conditions.value, contains(Condition.wound));
    }
    state.undo();
    for (final standee in monster.monsterInstances) {
      expect(standee.conditions.value, isNot(contains(Condition.wound)));
    }
  });

  test('a second group click clears all living standees in one undo step', () {
    addStandees('Zealot', MonsterType.normal);
    AddStandeeCommand(
      3,
      null,
      'Zealot',
      MonsterType.elite,
      false,
      gameState: state,
    ).execute();
    final monster = state.currentList.whereType<Monster>().single;
    final dead = monster.monsterInstances.last;
    controls.apply(Condition.poison, dead.getId(), monster.id);
    dead.setHealth(DrawCommand(gameState: state).stateAccess, 0);
    controls.apply(Condition.poison, 'Banner Spear', 'Banner Spear');
    startTurn('Zealot');
    controls.toggleActive(Condition.poison);
    expect(controls.isApplied(Condition.poison), isTrue);
    final index = state.commandIndex.value;
    controls.toggleActive(Condition.poison);
    expect(state.commandIndex.value, index + 1);
    for (final standee in monster.monsterInstances.where(
      (s) => s.health.value > 0,
    )) {
      expect(standee.conditions.value, isEmpty);
      expect(
        standee.conditionsAddedThisTurn,
        isNot(contains(Condition.poison)),
      );
    }
    expect(dead.conditions.value, [Condition.poison]);
    expect(character('Banner Spear').characterState.conditions.value, [
      Condition.poison,
    ]);
    state.undo();
    expect(controls.isApplied(Condition.poison), isTrue);
    state.redo();
    expect(controls.isApplied(Condition.poison), isFalse);
  });

  test(
    'immune standees do not prevent highlighting and clearing an applied effect',
    () {
      addStandees('Zealot', MonsterType.normal);
      final monster = state.currentList.whereType<Monster>().single;
      final immune = monster.monsterInstances.first;
      final eligible = monster.monsterInstances.last;
      eligible.setType(
        DrawCommand(gameState: state).stateAccess,
        MonsterType.elite,
      );
      final immunities =
          monster.type.levels[monster.level.value].normal!.immunities;
      final originalImmunities = List<String>.of(immunities);
      immunities.add('stun');
      addTearDown(() {
        immunities
          ..clear()
          ..addAll(originalImmunities);
      });
      startTurn('Zealot');
      controls.toggleActive(Condition.stun);
      expect(immune.conditions.value, isEmpty);
      expect(eligible.conditions.value, [Condition.stun]);
      expect(controls.isApplied(Condition.stun), isTrue);
      expect(controls.canToggleActive(Condition.stun), isTrue);
      controls.toggleActive(Condition.stun);
      expect(eligible.conditions.value, isEmpty);
      expect(controls.isApplied(Condition.stun), isFalse);
    },
  );

  test('group clicks skip defeated standees and immune effects', () {
    addStandees('Blood Tumor', MonsterType.boss);
    startTurn('Blood Tumor');
    final monster = state.currentList.whereType<Monster>().single;
    final dead = monster.monsterInstances.last;
    dead.setHealth(DrawCommand(gameState: state).stateAccess, 0);
    final index = state.commandIndex.value;
    controls.toggleActive(Condition.stun);
    expect(state.commandIndex.value, index);
    controls.toggleActive(Condition.wound);
    expect(monster.monsterInstances.first.conditions.value, [Condition.wound]);
    expect(dead.conditions.value, isEmpty);
  });

  test('removing the current character leaves no stale click target', () {
    startTurn('Blinkblade');
    RemoveCharacterCommand([
      character('Blinkblade'),
    ], gameState: state).execute();
    final index = state.commandIndex.value;
    expect(controls.activeItem, isNull);
    controls.toggleActive(Condition.stun);
    expect(state.commandIndex.value, index);
  });

  test(
    'quick effects contain only the 13 basics with custom content on or off',
    () {
      const basics = [
        Condition.stun,
        Condition.immobilize,
        Condition.disarm,
        Condition.wound,
        Condition.muddle,
        Condition.poison,
        Condition.bane,
        Condition.brittle,
        Condition.impair,
        Condition.strengthen,
        Condition.invisible,
        Condition.regenerate,
        Condition.ward,
      ];
      for (final custom in [true, false]) {
        getIt<Settings>().showCustomContent.value = custom;
        expect(controls.conditions, basics);
      }
    },
  );
}
