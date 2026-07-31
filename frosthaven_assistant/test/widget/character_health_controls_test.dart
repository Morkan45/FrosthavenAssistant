import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_health_controls.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  setUp(() {
    getIt<GameState>().clearList();
    AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
  });

  Character getCharacter() =>
      getIt<GameState>().currentList.single as Character;

  Future<void> pumpControls(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterHealthControls(
            character: getCharacter(),
            scale: 1,
            gameState: getIt<GameState>(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('CharacterHealthControls', () {
    testWidgets('uses two equal 50 logical-pixel targets', (
      WidgetTester tester,
    ) async {
      await pumpControls(tester);

      final decrease = find.byKey(const Key('character-health-decrease'));
      final increase = find.byKey(const Key('character-health-increase'));
      expect(tester.getSize(decrease), const Size(50, 50));
      expect(tester.getSize(increase), const Size(50, 50));
    });

    testWidgets('decreases and increases health by one', (
      WidgetTester tester,
    ) async {
      final character = getCharacter();
      final initialHealth = character.characterState.health.value;
      await pumpControls(tester);

      await tester.tap(find.byKey(const Key('character-health-decrease')));
      await tester.pump();
      expect(character.characterState.health.value, initialHealth - 1);

      await tester.tap(find.byKey(const Key('character-health-increase')));
      await tester.pump();
      expect(character.characterState.health.value, initialHealth);
    });

    testWidgets('disables increase at maximum health', (
      WidgetTester tester,
    ) async {
      await pumpControls(tester);

      final increaseButton = tester.widget<IconButton>(
        find.descendant(
          of: find.byKey(const Key('character-health-increase')),
          matching: find.byType(IconButton),
        ),
      );
      expect(increaseButton.onPressed, isNull);
    });
  });
}
