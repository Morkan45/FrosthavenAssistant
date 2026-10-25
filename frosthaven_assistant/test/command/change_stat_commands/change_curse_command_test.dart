import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/commands/change_stat_commands/change_curse_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

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
    );
  });

  group('ChangeCurseCommand', () {
    test('objectives cannot gain Curse but existing cards can be removed', () {
      final state = getIt<GameState>();
      AddCharacterCommand('Objective', 'na', 'Raven Nest a', 1).execute();
      final objective = state.currentList.whereType<Character>().firstWhere(
        (item) => item.characterClass.id == 'Objective',
      );
      final deck = objective.characterState.modifierDeck;
      final monsterCurses = state.modifierDeck.getRemovable('curse').value;
      final command = ChangeCurseCommand(
        1,
        objective.id,
        objective.id,
        gameState: state,
      );
      command.execute();
      expect(deck.getRemovable('curse').value, 0);
      expect(state.modifierDeck.getRemovable('curse').value, monsterCurses);
      deck.addRemovableValue(command.stateAccess, 'curse', 1);
      ChangeCurseCommand(
        -1,
        objective.id,
        objective.id,
        gameState: state,
      ).execute();
      expect(deck.getRemovable('curse').value, 0);
    });

    test('should add a curse card to a character deck', () {
      // Arrange
      final character = getIt<GameState>().currentList.first as Character;
      final command = ChangeCurseCommand(
        1,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
      );
      final initialCurseCount = character.characterState.modifierDeck
          .getRemovable("curse")
          .value;

      // Act
      command.execute();

      // Assert
      final finalCurseCount = character.characterState.modifierDeck
          .getRemovable("curse")
          .value;
      expect(finalCurseCount, initialCurseCount + 1);
      checkSaveState();
    });

    test('should remove a curse card from a character deck', () {
      // Arrange
      final character = getIt<GameState>().currentList.first as Character;
      ChangeCurseCommand(
        1,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
      ).execute(); // Add a curse first
      final initialCurseCount = character.characterState.modifierDeck
          .getRemovable("curse")
          .value;
      final command = ChangeCurseCommand(
        -1,
        character.id,
        character.id,
        gameState: getIt<GameState>(),
      );

      // Act
      command.execute();

      // Assert
      final finalCurseCount = character.characterState.modifierDeck
          .getRemovable("curse")
          .value;
      expect(finalCurseCount, initialCurseCount - 1);
      checkSaveState();
    });

    test('should add a curse card to the monster deck', () {
      // Arrange
      final gameState = getIt<GameState>();
      final command = ChangeCurseCommand(
        1,
        "Zealot",
        "Zealot",
        gameState: getIt<GameState>(),
      ); // Empty string for monster deck
      final initialCurseCount = gameState.modifierDeck
          .getRemovable("curse")
          .value;

      // Act
      command.execute();

      // Assert
      final finalCurseCount = gameState.modifierDeck
          .getRemovable("curse")
          .value;
      expect(finalCurseCount, initialCurseCount + 1);
      checkSaveState();
    });

    test('should remove a curse card from the monster deck', () {
      // Arrange
      final gameState = getIt<GameState>();
      ChangeCurseCommand(
        1,
        "Zealot",
        "Zealot",
        gameState: getIt<GameState>(),
      ).execute(); // Add a curse first
      final initialCurseCount = gameState.modifierDeck
          .getRemovable("curse")
          .value;
      final command = ChangeCurseCommand(
        -1,
        "Zealot",
        "Zealot",
        gameState: getIt<GameState>(),
      );

      // Act
      command.execute();

      // Assert
      final finalCurseCount = gameState.modifierDeck
          .getRemovable("curse")
          .value;
      expect(finalCurseCount, initialCurseCount - 1);
      checkSaveState();
    });

    test('describe should return correct string for adding curse', () {
      // Arrange
      final command = ChangeCurseCommand(
        1,
        'Blinkblade',
        'Blinkblade',
        gameState: getIt<GameState>(),
      );

      // Act & Assert
      expect(command.describe(), 'Add a Curse');
      checkSaveState();
    });

    test('describe should return correct string for removing curse', () {
      // Arrange
      final command = ChangeCurseCommand(
        -1,
        'Blinkblade',
        'Blinkblade',
        gameState: getIt<GameState>(),
      );

      // Act & Assert
      expect(command.describe(), 'Remove a Curse');
      checkSaveState();
    });

    test('describe should return correct string for monster deck', () {
      // Arrange
      final command = ChangeCurseCommand(
        1,
        "Zealot",
        "Zealot",
        gameState: getIt<GameState>(),
      );

      // Act & Assert
      expect(command.describe(), 'Add a Curse');
      checkSaveState();
    });
  });
}
