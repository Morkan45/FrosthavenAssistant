import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/set_scenario_command.dart';
import 'package:frosthaven_assistant/Resource/commands/unlock_special_command.dart';
import 'package:frosthaven_assistant/Resource/game_data.dart';

import '../unit_helpers.dart';

void main() {
  test('unlock command mutates only its injected game state', () {
    final (firstGame, _) = makeGameAndSettings();
    final (secondGame, _) = makeGameAndSettings();

    UnlockSpecialCommand('Demons', gameState: firstGame).execute();

    expect(firstGame.unlockedClasses, contains('Demons'));
    expect(secondGame.unlockedClasses, isNot(contains('Demons')));
  });

  test('scenario command mutates only its injected game state', () {
    final (firstGame, firstSettings) = makeGameAndSettings();
    final (secondGame, _) = makeGameAndSettings();

    SetScenarioCommand(
      '#section',
      true,
      gameState: firstGame,
      gameData: GameData(),
      settings: firstSettings,
    ).execute();

    expect(firstGame.scenarioSectionsAdded, contains('#section'));
    expect(secondGame.scenarioSectionsAdded, isNot(contains('#section')));
  });
}
