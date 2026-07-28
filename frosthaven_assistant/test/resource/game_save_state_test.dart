import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_level_command.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';

void main() {
  setUpAll(setUpGame);

  setUp(() => getIt<GameState>().clearList());

  test('malformed state rolls back all mutations', () {
    final gameState = getIt<GameState>();
    gameState.action(SetLevelCommand(3, null));
    final original = gameState.toString();
    final malformed = jsonDecode(original) as Map<String, dynamic>;
    malformed['level'] = 7;
    malformed['currentList'] = 'not-a-list';

    expect(gameState.loadFromData(jsonEncode(malformed)), isFalse);
    expect(gameState.toString(), original);
    gameState.undo();
  });

  test('older character state defaults newly added fields', () {
    final gameState = getIt<GameState>();
    gameState.action(AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1));
    final legacy = jsonDecode(gameState.toString()) as Map<String, dynamic>;
    final character =
        (legacy['currentList'] as List).single as Map<String, dynamic>;
    final characterState = character['characterState'] as Map<String, dynamic>;
    characterState.remove('chill');
    characterState.remove('display');
    characterState.remove('summonList');
    characterState.remove('conditions');

    expect(gameState.loadFromData(jsonEncode(legacy)), isTrue);
    expect(gameState.currentList.single, isA<Character>());
    gameState.undo();
  });
}
