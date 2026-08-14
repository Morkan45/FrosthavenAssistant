import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/imbue_element_command.dart';
import 'package:frosthaven_assistant/Resource/commands/load_character_save_command.dart';
import 'package:frosthaven_assistant/Resource/commands/load_save_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_campaign_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_scenario_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../unit_helpers.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  group('LoadSaveCommand', () {
    test('should restore game state from serialized data', () {
      getIt<GameState>().clearList();
      SetCampaignCommand('Jaws of the Lion').execute();
      AddCharacterCommand('Blinkblade', 'Frosthaven', 'SaveTest', 1).execute();
      final savedData = getIt<GameState>().toString();

      // Change state
      getIt<GameState>().clearList();

      // Restore
      LoadSaveCommand(
        'test save',
        savedData,
        gameState: getIt<GameState>(),
      ).execute();

      expect(getIt<GameState>().currentList.whereType<Character>().length, 1);
      expect(
        getIt<GameState>().currentList
            .whereType<Character>()
            .first
            .characterState
            .display
            .value,
        'SaveTest',
      );
    });

    test('describe includes save name', () {
      final command = LoadSaveCommand(
        'my save',
        '{}',
        gameState: getIt<GameState>(),
      );
      expect(command.describe(), 'Load saved game: my save');
    });

    test('undo restores element state from before loading a save', () {
      final (gameState, _) = makeGameAndSettings();
      final fireNotifier = gameState.elementStateFor(Elements.fire);
      final savedData = gameState.toString();

      ImbueElementCommand(Elements.fire, false, gameState: gameState).execute();
      gameState.save();

      gameState.action(
        LoadSaveCommand('inert elements', savedData, gameState: gameState),
      );
      expect(gameState.elementState[Elements.fire], ElementState.inert);

      gameState.undo();
      expect(gameState.elementState[Elements.fire], ElementState.full);
      expect(gameState.elementStateFor(Elements.fire), same(fireNotifier));

      gameState.redo();
      expect(gameState.elementState[Elements.fire], ElementState.inert);
    });
  });

  group('LoadCharacterSaveCommand', () {
    test('should load a character from serialized character data', () {
      getIt<GameState>().clearList();
      SetCampaignCommand('Frosthaven').execute();
      SetScenarioCommand(
        'custom',
        false,
        gameState: getIt<GameState>(),
      ).execute();
      AddCharacterCommand('Blinkblade', 'Frosthaven', 'OrigName', 1).execute();
      final character =
          getIt<GameState>().currentList.firstWhere((e) => e is Character)
              as Character;
      final charData = character.toSave();

      // Remove the character
      getIt<GameState>().clearList();

      // Reload from save data
      LoadCharacterSaveCommand(
        'Blinkblade',
        charData,
        gameState: getIt<GameState>(),
      ).execute();

      final loaded =
          getIt<GameState>().currentList.firstWhere((e) => e is Character)
              as Character;
      expect(loaded.id, 'Blinkblade');
      expect(loaded.characterState.display.value, 'OrigName');
    });

    test('describe includes save name', () {
      final command = LoadCharacterSaveCommand(
        'Blinkblade',
        '{}',
        gameState: getIt<GameState>(),
      );
      expect(command.describe(), 'Load saved character: Blinkblade');
    });
  });
}
