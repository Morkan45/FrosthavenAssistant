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
    controls.applyToActive(Condition.stun);
    expect(state.commandIndex.value, initialIndex);
    startTurn('Banner Spear');
    expect(controls.activeItem?.id, 'Banner Spear');
    controls.applyToActive(Condition.poison);
    expect(character('Banner Spear').characterState.conditions.value, [
      Condition.poison,
    ]);
    expect(character('Blinkblade').characterState.conditions.value, isEmpty);
    state.action(TurnDoneCommand('Banner Spear', gameState: state));
    expect(controls.activeItem?.id, 'Blinkblade');
    controls.applyToActive(Condition.wound);
    expect(character('Blinkblade').characterState.conditions.value, [
      Condition.wound,
    ]);
    state.undo();
    state.undo();
    expect(controls.activeItem?.id, 'Banner Spear');
    state.redo();
    expect(controls.activeItem?.id, 'Blinkblade');
  });

  test('an existing effect is a no-op and stays applied after redo', () {
    startTurn('Blinkblade');
    controls.applyToActive(Condition.poison);
    final index = state.commandIndex.value;
    controls.applyToActive(Condition.poison);
    expect(state.commandIndex.value, index);
    expect(controls.canApplyToActive(Condition.poison), isFalse);
    state.undo();
    expect(controls.isApplied(Condition.poison), isFalse);
    state.redo();
    expect(controls.isApplied(Condition.poison), isTrue);
  });

  test('drops target a single figure independently of the current turn', () {
    startTurn('Blinkblade');
    controls.apply(Condition.wound, 'Banner Spear', 'Banner Spear');
    expect(character('Blinkblade').characterState.conditions.value, isEmpty);
    expect(character('Banner Spear').characterState.conditions.value, [
      Condition.wound,
    ]);
    expect(controls.activeItem?.id, 'Blinkblade');
  });

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
    controls.applyToActive(Condition.poison);
    expect(state.commandIndex.value, index + 1);
    expect(controls.isApplied(Condition.poison), isTrue);
    state.undo();
    expect(controls.isApplied(Condition.poison), isFalse);
    controls.applyToActive(Condition.wound);
    for (final standee in monster.monsterInstances) {
      expect(standee.conditions.value, contains(Condition.wound));
    }
    state.undo();
    for (final standee in monster.monsterInstances) {
      expect(standee.conditions.value, isNot(contains(Condition.wound)));
    }
  });

  test('group clicks skip defeated standees and immune effects', () {
    addStandees('Blood Tumor', MonsterType.boss);
    startTurn('Blood Tumor');
    final monster = state.currentList.whereType<Monster>().single;
    final dead = monster.monsterInstances.last;
    dead.setHealth(DrawCommand(gameState: state).stateAccess, 0);
    final index = state.commandIndex.value;
    controls.applyToActive(Condition.stun);
    expect(state.commandIndex.value, index);
    controls.applyToActive(Condition.wound);
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
    controls.applyToActive(Condition.stun);
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
