// ignore_for_file: no-magic-number, avoid-late-keyword

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_condition_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/commands/change_stat_commands/change_health_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../../unit_helpers.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  late Character character;
  late Monster monster;
  late MonsterInstance monsterInstance;
  late Settings conditionSettings;

  setUp(() {
    getIt<GameState>().clearList();
    AddCharacterCommand('Blinkblade', 'Frosthaven', "", 1).execute();
    AddMonsterCommand(
      "Zealot",
      1,
      false,
      gameState: getIt<GameState>(),
    ).execute();
    AddStandeeCommand(
      1,
      null,
      "Zealot",
      MonsterType.normal,
      false,
      gameState: getIt<GameState>(),
    ).execute();

    character =
        getIt<GameState>().currentList.firstWhere((e) => e is Character)
            as Character;
    monster =
        getIt<GameState>().currentList.firstWhere((e) => e is Monster)
            as Monster;
    monsterInstance = monster.monsterInstances.first;
    conditionSettings = Settings();
    conditionSettings.expireConditions.value = true;
  });

  void addCharacterConditions(Iterable<Condition> conditions) {
    for (final condition in conditions) {
      AddConditionCommand(
        condition,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
      ).execute();
    }
  }

  void addMonsterConditions(Iterable<Condition> conditions) {
    for (final condition in conditions) {
      AddConditionCommand(
        condition,
        monsterInstance.getId(),
        monster.id,
        gameState: getIt<GameState>(),
      ).execute();
    }
  }

  group('ChangeHealthCommand', () {
    test('should increase a character\'s health', () {
      // Arrange
      final initialHealth = character.characterState.health.value;
      final command = ChangeHealthCommand(
        5,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
      );

      // Act
      command.execute();

      // Assert
      expect(character.characterState.health.value, initialHealth + 5);
    });

    test('should decrease a character\'s health', () {
      // Arrange
      final initialHealth = character.characterState.health.value;
      final command = ChangeHealthCommand(
        -5,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
      );

      // Act
      command.execute();

      // Assert
      expect(character.characterState.health.value, initialHealth - 5);
    });

    test('should kill a character when health reaches 0', () {
      // Arrange
      final command = ChangeHealthCommand(
        -100,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
      );

      // Act
      command.execute();

      // Assert
      expect(character.characterState.health.value, 0);
      // A killed character's turn should be marked as done. this is not true
      //expect(character.turnState.value, TurnsState.done);
    });

    test('should increase a monster instance\'s health', () {
      // Arrange
      final initialHealth = monsterInstance.health.value;
      final command = ChangeHealthCommand(
        3,
        monsterInstance.getId(),
        monster.id,
        gameState: getIt<GameState>(),
      );

      // Act
      command.execute();

      // Assert
      expect(monsterInstance.health.value, initialHealth + 3);
    });

    test('uses the injected game state when changing health', () {
      final (injectedState, _) = makeGameAndSettings();
      expect(injectedState.loadFromData(getIt<GameState>().toString()), isTrue);
      final injectedMonster =
          injectedState.currentList.firstWhere((item) => item is Monster)
              as Monster;
      final injectedInstance = injectedMonster.monsterInstances.first;
      final injectedHealth = injectedInstance.health.value;
      final globalHealth = monsterInstance.health.value;

      ChangeHealthCommand(
        -1,
        injectedInstance.getId(),
        injectedMonster.id,
        gameState: injectedState,
      ).execute();

      expect(injectedInstance.health.value, injectedHealth - 1);
      expect(monsterInstance.health.value, globalHealth);
    });

    test('damage removes standard damage-triggered character conditions', () {
      const removed = {Condition.ward, Condition.regenerate, Condition.brittle};
      const retained = {
        Condition.poison,
        Condition.wound,
        Condition.bane,
        Condition.stun,
        Condition.poison2,
        Condition.wound2,
      };
      addCharacterConditions({...removed, ...retained});
      final previousConditions = character.characterState.conditions.value;
      final previousHealth = character.characterState.health.value;
      var updateCount = 0;
      void countUpdate() => updateCount++;
      getIt<GameState>().updateList.addListener(countUpdate);

      ChangeHealthCommand(
        -1,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
        settings: conditionSettings,
      ).execute();
      getIt<GameState>().updateList.removeListener(countUpdate);

      expect(character.characterState.health.value, previousHealth - 1);
      expect(
        character.characterState.conditions.value.toSet().intersection(removed),
        isEmpty,
      );
      expect(character.characterState.conditions.value, containsAll(retained));
      expect(
        identical(
          previousConditions,
          character.characterState.conditions.value,
        ),
        isFalse,
      );
      expect(updateCount, 1);
    });

    test('damage removes standard damage-triggered monster conditions', () {
      addMonsterConditions(const {
        Condition.ward,
        Condition.regenerate,
        Condition.brittle,
        Condition.poison,
        Condition.poison3,
      });
      final previousHealth = monsterInstance.health.value;

      ChangeHealthCommand(
        -1,
        monsterInstance.getId(),
        monster.id,
        gameState: getIt<GameState>(),
        settings: conditionSettings,
      ).execute();

      expect(monsterInstance.health.value, previousHealth - 1);
      expect(
        monsterInstance.conditions.value.toSet().intersection(const {
          Condition.ward,
          Condition.regenerate,
          Condition.brittle,
        }),
        isEmpty,
      );
      expect(
        monsterInstance.conditions.value,
        containsAll(const {Condition.poison, Condition.poison3}),
      );
    });

    test('healing removes standard heal-triggered character conditions', () {
      ChangeHealthCommand(
        -1,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
        settings: conditionSettings,
      ).execute();
      const removed = {
        Condition.poison,
        Condition.wound,
        Condition.brittle,
        Condition.bane,
      };
      const retained = {
        Condition.ward,
        Condition.regenerate,
        Condition.stun,
        Condition.poison2,
        Condition.poison4,
        Condition.wound2,
        Condition.infect,
        Condition.rupture,
      };
      addCharacterConditions({...removed, ...retained});
      final previousHealth = character.characterState.health.value;

      ChangeHealthCommand(
        1,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
        settings: conditionSettings,
      ).execute();

      expect(character.characterState.health.value, previousHealth + 1);
      expect(
        character.characterState.conditions.value.toSet().intersection(removed),
        isEmpty,
      );
      expect(character.characterState.conditions.value, containsAll(retained));
    });

    test('healing removes standard heal-triggered monster conditions', () {
      ChangeHealthCommand(
        -1,
        monsterInstance.getId(),
        monster.id,
        gameState: getIt<GameState>(),
        settings: conditionSettings,
      ).execute();
      addMonsterConditions(const {
        Condition.poison,
        Condition.wound,
        Condition.brittle,
        Condition.bane,
        Condition.regenerate,
        Condition.wound2,
      });
      final previousHealth = monsterInstance.health.value;

      ChangeHealthCommand(
        1,
        monsterInstance.getId(),
        monster.id,
        gameState: getIt<GameState>(),
        settings: conditionSettings,
      ).execute();

      expect(monsterInstance.health.value, previousHealth + 1);
      expect(
        monsterInstance.conditions.value.toSet().intersection(const {
          Condition.poison,
          Condition.wound,
          Condition.brittle,
          Condition.bane,
        }),
        isEmpty,
      );
      expect(
        monsterInstance.conditions.value,
        containsAll(const {Condition.regenerate, Condition.wound2}),
      );
    });

    test('a clamped health change does not consume conditions', () {
      ChangeHealthCommand(
        -100,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
        settings: conditionSettings,
      ).execute();
      const conditions = {
        Condition.ward,
        Condition.regenerate,
        Condition.brittle,
        Condition.poison,
        Condition.wound,
        Condition.bane,
      };
      addCharacterConditions(conditions);

      ChangeHealthCommand(
        -1,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
        settings: conditionSettings,
      ).execute();

      expect(character.characterState.health.value, 0);
      expect(
        character.characterState.conditions.value,
        containsAll(conditions),
      );
    });

    test('manual condition mode does not consume conditions', () {
      ChangeHealthCommand(
        -1,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
        settings: conditionSettings,
      ).execute();
      const conditions = {
        Condition.ward,
        Condition.regenerate,
        Condition.brittle,
        Condition.poison,
        Condition.wound,
        Condition.bane,
      };
      addCharacterConditions(conditions);
      final manualSettings = Settings();
      manualSettings.expireConditions.value = false;

      ChangeHealthCommand(
        -1,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
        settings: manualSettings,
      ).execute();
      ChangeHealthCommand(
        1,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
        settings: manualSettings,
      ).execute();

      expect(
        character.characterState.conditions.value,
        containsAll(conditions),
      );
    });

    test('condition cleanup clears both turn bookkeeping sets', () {
      final state =
          json.decode(getIt<GameState>().toString()) as Map<String, dynamic>;
      final currentList = state['currentList'] as List<dynamic>;
      final characterJson = currentList.cast<Map<String, dynamic>>().firstWhere(
        (item) => item['id'] == character.id,
      );
      final characterStateJson =
          characterJson['characterState'] as Map<String, dynamic>;
      characterStateJson['conditions'] = [
        Condition.ward.index,
        Condition.regenerate.index,
      ];
      characterStateJson['conditionsAddedThisTurn'] = [Condition.ward.index];
      characterStateJson['conditionsAddedPreviousTurn'] = [
        Condition.regenerate.index,
      ];
      expect(getIt<GameState>().loadFromData(json.encode(state)), isTrue);
      character =
          getIt<GameState>().currentList.firstWhere((item) => item is Character)
              as Character;

      ChangeHealthCommand(
        -1,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
        settings: conditionSettings,
      ).execute();

      expect(character.characterState.conditionsAddedThisTurn, isEmpty);
      expect(character.characterState.conditionsAddedPreviousTurn, isEmpty);
    });

    test('condition cleanup uses the injected game state and settings', () {
      addCharacterConditions(const {
        Condition.ward,
        Condition.regenerate,
        Condition.brittle,
      });
      final globalHealth = character.characterState.health.value;
      final (injectedState, injectedSettings) = makeGameAndSettings();
      expect(injectedState.loadFromData(getIt<GameState>().toString()), isTrue);
      injectedSettings.expireConditions.value = true;
      final injectedCharacter = injectedState.currentList
          .whereType<Character>()
          .single;

      ChangeHealthCommand(
        -1,
        injectedCharacter.id,
        injectedCharacter.id,
        gameState: injectedState,
        settings: injectedSettings,
      ).execute();

      expect(injectedCharacter.characterState.health.value, globalHealth - 1);
      expect(
        injectedCharacter.characterState.conditions.value,
        isNot(contains(Condition.ward)),
      );
      expect(character.characterState.health.value, globalHealth);
      expect(
        character.characterState.conditions.value,
        containsAll(const {
          Condition.ward,
          Condition.regenerate,
          Condition.brittle,
        }),
      );
    });

    test('undo restores health and conditions consumed by damage', () {
      final gameState = getIt<GameState>();
      gameState.action(
        AddConditionCommand(
          Condition.ward,
          character.id,
          character.id,
          gameState: gameState,
        ),
      );
      final previousHealth = character.characterState.health.value;

      gameState.action(
        ChangeHealthCommand(
          -1,
          character.id,
          character.id,
          gameState: gameState,
          settings: conditionSettings,
        ),
      );

      expect(character.characterState.health.value, previousHealth - 1);
      expect(
        character.characterState.conditions.value,
        isNot(contains(Condition.ward)),
      );

      gameState.undo();
      character = gameState.currentList.whereType<Character>().single;

      expect(character.characterState.health.value, previousHealth);
      expect(
        character.characterState.conditions.value,
        contains(Condition.ward),
      );
    });

    test('should kill a monster instance when health reaches 0', () {
      // Arrange
      final command = ChangeHealthCommand(
        -100,
        monsterInstance.getId(),
        monster.id,
        gameState: getIt<GameState>(),
      );
      final initialInstanceCount = monster.monsterInstances.length;

      // Act
      command.execute();

      // Assert
      expect(monster.monsterInstances.length, initialInstanceCount - 1);
    });

    test('should not decrease health below 0', () {
      // Arrange
      final command = ChangeHealthCommand(
        -100,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
      );

      // Act
      command.execute();

      // Assert
      expect(character.characterState.health.value, 0);
    });

    test('describe should return correct string for increasing health', () {
      final command = ChangeHealthCommand(
        5,
        'Blinkblade',
        'Blinkblade',
        gameState: getIt<GameState>(),
      );
      expect(command.describe(), "Increase Blinkblade's health by 5");
    });

    test('describe should return correct string for decreasing health', () {
      final command = ChangeHealthCommand(
        -5,
        'Blinkblade',
        'Blinkblade',
        gameState: getIt<GameState>(),
      );
      expect(command.describe(), "Decrease Blinkblade's health by 5");
    });

    test('describe should return kill string if health is already 0', () {
      // Arrange
      //character.characterState.setHealth(StateModifier(), 0);
      ChangeHealthCommand(
        -100,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
      ).execute();
      final command = ChangeHealthCommand(
        -1,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
      );

      // Act & Assert
      expect(command.describe(), 'Kill Blinkblade');
    });
  });
}
