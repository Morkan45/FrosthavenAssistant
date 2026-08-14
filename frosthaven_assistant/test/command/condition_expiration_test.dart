// ignore_for_file: avoid-late-keyword

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_condition_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/commands/draw_command.dart';
import 'package:frosthaven_assistant/Resource/commands/next_round_command.dart';
import 'package:frosthaven_assistant/Resource/commands/remove_condition_command.dart';
import 'package:frosthaven_assistant/Resource/commands/turn_done_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/game_data.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../unit_helpers.dart';
import 'test_helpers.dart';

void main() {
  const standardCharacterTimedConditions = <Condition>[
    Condition.strengthen,
    Condition.stun,
    Condition.immobilize,
    Condition.muddle,
    Condition.invisible,
    Condition.disarm,
    Condition.impair,
  ];
  const standardMonsterTimedConditions = <Condition>[
    Condition.strengthen,
    Condition.stun,
    Condition.immobilize,
    Condition.muddle,
    Condition.invisible,
    Condition.disarm,
  ];

  late String emptyState;
  late GameState globalState;
  late Settings globalSettings;
  late Character character;
  late Monster monster;
  late MonsterInstance monsterInstance;

  setUpAll(() async {
    await setUpGame();
    globalState = getIt<GameState>();
    globalState.clearList();
    emptyState = globalState.toString();
  });

  setUp(() {
    expect(globalState.loadFromData(emptyState), isTrue);
    globalSettings = getIt<Settings>();
    globalSettings.expireConditions.value = true;

    AddCharacterCommand('Blinkblade', 'Frosthaven', 'BB', 1).execute();
    AddMonsterCommand('Zealot', 1, false, gameState: globalState).execute();
    AddStandeeCommand(
      1,
      null,
      'Zealot',
      MonsterType.normal,
      false,
      gameState: globalState,
    ).execute();

    character = globalState.currentList.whereType<Character>().single;
    monster = globalState.currentList.whereType<Monster>().single;
    monsterInstance = monster.monsterInstances.single;
  });

  (GameState, Settings) cloneGlobalState() {
    final (isolatedState, isolatedSettings) = makeGameAndSettings();
    expect(isolatedState.loadFromData(globalState.toString()), isTrue);
    return (isolatedState, isolatedSettings);
  }

  Character isolatedCharacter(GameState state) =>
      state.currentList.whereType<Character>().single;

  group('condition command state isolation', () {
    test('add and remove condition mutate only the injected game state', () {
      final (isolatedState, _) = cloneGlobalState();
      final isolated = isolatedCharacter(isolatedState);

      AddConditionCommand(
        Condition.muddle,
        isolated.id,
        isolated.id,
        gameState: isolatedState,
      ).execute();

      expect(
        isolated.characterState.conditions.value,
        contains(Condition.muddle),
      );
      expect(
        character.characterState.conditions.value,
        isNot(contains(Condition.muddle)),
      );

      AddConditionCommand(
        Condition.muddle,
        character.id,
        character.id,
        gameState: globalState,
      ).execute();
      RemoveConditionCommand(
        Condition.muddle,
        isolated.id,
        isolated.id,
        gameState: isolatedState,
      ).execute();

      expect(
        isolated.characterState.conditions.value,
        isNot(contains(Condition.muddle)),
      );
      expect(
        character.characterState.conditions.value,
        contains(Condition.muddle),
      );
    });

    test('turn completion mutates only the injected game state', () {
      AddConditionCommand(
        Condition.strengthen,
        character.id,
        character.id,
        gameState: globalState,
      ).execute();
      DrawCommand(gameState: globalState).execute();

      final (isolatedState, isolatedSettings) = cloneGlobalState();
      final isolated = isolatedCharacter(isolatedState);

      TurnDoneCommand(
        isolated.id,
        gameState: isolatedState,
        settings: isolatedSettings,
      ).execute();

      expect(
        isolated.characterState.conditions.value,
        isNot(contains(Condition.strengthen)),
      );
      expect(
        character.characterState.conditions.value,
        contains(Condition.strengthen),
      );
      expect(character.turnState.value, TurnsState.current);
    });

    test('turn completion uses the injected expiration setting', () {
      AddConditionCommand(
        Condition.strengthen,
        character.id,
        character.id,
        gameState: globalState,
      ).execute();
      DrawCommand(gameState: globalState).execute();

      final (isolatedState, isolatedSettings) = cloneGlobalState();
      final isolated = isolatedCharacter(isolatedState);
      globalSettings.expireConditions.value = true;
      isolatedSettings.expireConditions.value = false;

      TurnDoneCommand(
        isolated.id,
        gameState: isolatedState,
        settings: isolatedSettings,
      ).execute();

      expect(
        isolated.characterState.conditions.value,
        contains(Condition.strengthen),
      );
      expect(isolated.turnState.value, TurnsState.done);
      expect(character.turnState.value, TurnsState.current);
    });

    test('next round uses the injected game state and settings', () {
      AddConditionCommand(
        Condition.strengthen,
        character.id,
        character.id,
        gameState: globalState,
      ).execute();
      DrawCommand(gameState: globalState).execute();

      final (isolatedState, isolatedSettings) = cloneGlobalState();
      final isolated = isolatedCharacter(isolatedState);
      final globalRound = globalState.round.value;
      globalSettings.expireConditions.value = false;
      isolatedSettings.expireConditions.value = true;

      NextRoundCommand(
        gameState: isolatedState,
        gameData: getIt<GameData>(),
        settings: isolatedSettings,
      ).execute();

      expect(
        isolated.characterState.conditions.value,
        isNot(contains(Condition.strengthen)),
      );
      expect(isolatedState.round.value, globalRound + 1);
      expect(
        character.characterState.conditions.value,
        contains(Condition.strengthen),
      );
      expect(globalState.round.value, globalRound);
    });
  });

  group('timed condition expiration', () {
    test('all standard timed conditions expire for a character', () {
      for (final condition in standardCharacterTimedConditions) {
        AddConditionCommand(
          condition,
          character.id,
          character.id,
          gameState: globalState,
        ).execute();
      }

      DrawCommand(gameState: globalState).execute();
      TurnDoneCommand(character.id, gameState: globalState).execute();

      expect(
        character.characterState.conditions.value,
        isNot(contains(anyOf(standardCharacterTimedConditions))),
      );
    });

    test('all standard timed conditions expire for a monster', () {
      for (final condition in standardMonsterTimedConditions) {
        AddConditionCommand(
          condition,
          monsterInstance.getId(),
          monster.id,
          gameState: globalState,
        ).execute();
      }

      DrawCommand(gameState: globalState).execute();
      TurnDoneCommand(character.id, gameState: globalState).execute();
      expect(monster.turnState.value, TurnsState.current);
      TurnDoneCommand(monster.id, gameState: globalState).execute();

      expect(
        monsterInstance.conditions.value,
        isNot(contains(anyOf(standardMonsterTimedConditions))),
      );
    });

    test('refresh during own turn survives then expires after next turn', () {
      AddConditionCommand(
        Condition.strengthen,
        character.id,
        character.id,
        gameState: globalState,
      ).execute();
      DrawCommand(gameState: globalState).execute();

      AddConditionCommand(
        Condition.strengthen,
        character.id,
        character.id,
        gameState: globalState,
      ).execute();
      TurnDoneCommand(character.id, gameState: globalState).execute();

      expect(
        character.characterState.conditions.value,
        contains(Condition.strengthen),
      );

      NextRoundCommand(
        gameState: globalState,
        gameData: getIt<GameData>(),
        settings: globalSettings,
      ).execute();
      DrawCommand(gameState: globalState).execute();
      TurnDoneCommand(character.id, gameState: globalState).execute();

      expect(
        character.characterState.conditions.value,
        isNot(contains(Condition.strengthen)),
      );
    });

    test('undo restores a condition removed at turn completion', () {
      globalState.action(
        AddConditionCommand(
          Condition.muddle,
          character.id,
          character.id,
          gameState: globalState,
        ),
      );
      globalState.action(DrawCommand(gameState: globalState));
      globalState.action(
        TurnDoneCommand(
          character.id,
          gameState: globalState,
          settings: globalSettings,
        ),
      );

      expect(
        character.characterState.conditions.value,
        isNot(contains(Condition.muddle)),
      );
      expect(character.turnState.value, TurnsState.done);

      globalState.undo();
      character = globalState.currentList.whereType<Character>().single;

      expect(
        character.characterState.conditions.value,
        contains(Condition.muddle),
      );
      expect(character.turnState.value, TurnsState.current);
    });

    test('expiration and turn rewind notify condition listeners', () {
      AddConditionCommand(
        Condition.muddle,
        character.id,
        character.id,
        gameState: globalState,
      ).execute();
      DrawCommand(gameState: globalState).execute();

      int notifications = 0;
      character.characterState.conditions.addListener(() {
        notifications++;
      });

      TurnDoneCommand(character.id, gameState: globalState).execute();
      expect(notifications, 1);
      expect(
        character.characterState.conditions.value,
        isNot(contains(Condition.muddle)),
      );

      TurnDoneCommand(character.id, gameState: globalState).execute();
      expect(notifications, 2);
      expect(
        character.characterState.conditions.value,
        contains(Condition.muddle),
      );
    });

    test('chill expiration and turn rewind preserve the stack count', () {
      for (int i = 0; i < 2; i++) {
        AddConditionCommand(
          Condition.chill,
          character.id,
          character.id,
          gameState: globalState,
        ).execute();
      }
      DrawCommand(gameState: globalState).execute();

      int notifications = 0;
      character.characterState.conditions.addListener(() {
        notifications++;
      });

      TurnDoneCommand(character.id, gameState: globalState).execute();
      expect(notifications, 1);
      expect(character.characterState.chill.value, 1);
      expect(
        character.characterState.conditions.value.where(
          (condition) => condition == Condition.chill,
        ),
        hasLength(1),
      );

      TurnDoneCommand(character.id, gameState: globalState).execute();
      expect(notifications, 2);
      expect(character.characterState.chill.value, 2);
      expect(
        character.characterState.conditions.value.where(
          (condition) => condition == Condition.chill,
        ),
        hasLength(2),
      );
    });
  });
}
