import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_health_controls.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/change_stat_commands/change_health_command.dart';
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

    testWidgets('shows the cumulative net health change', (
      WidgetTester tester,
    ) async {
      final character = getCharacter();
      final state = getIt<GameState>();
      state.action(
        ChangeHealthCommand(
          -3,
          character.id,
          character.id,
          gameState: state,
        ),
      );
      await pumpControls(tester);

      final decrease = find.byKey(const Key('character-health-decrease'));
      final increase = find.byKey(const Key('character-health-increase'));

      await tester.tap(increase);
      await tester.pump();
      expect(find.text('+1'), findsOneWidget);
      expect(
        find.descendant(of: increase, matching: find.text('+1')),
        findsOneWidget,
      );

      await tester.tap(increase);
      await tester.pump();
      expect(find.text('+2'), findsOneWidget);

      await tester.tap(decrease);
      await tester.pump();
      expect(find.text('+1'), findsOneWidget);

      await tester.tap(decrease);
      await tester.pump();
      expect(
        find.byKey(const Key('character-health-positive-feedback')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('character-health-negative-feedback')),
        findsNothing,
      );

      await tester.tap(decrease);
      await tester.pump();
      expect(find.text('-1'), findsOneWidget);
      expect(
        find.descendant(of: decrease, matching: find.text('-1')),
        findsOneWidget,
      );
    });

    testWidgets('restarts the four second inactivity timeout', (
      WidgetTester tester,
    ) async {
      await pumpControls(tester);
      final decrease = find.byKey(const Key('character-health-decrease'));

      await tester.tap(decrease);
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(decrease);
      await tester.pump();
      expect(find.text('-2'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 3999));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(
                const Key('character-health-negative-feedback'),
              ),
            )
            .opacity,
        1,
      );

      await tester.pump(const Duration(milliseconds: 1));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(
                const Key('character-health-negative-feedback'),
              ),
            )
            .opacity,
        0,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('character-health-negative-feedback')),
        findsNothing,
      );
    });

    testWidgets('outside tap dismisses feedback and starts a fresh burst', (
      WidgetTester tester,
    ) async {
      await pumpControls(tester);
      final decrease = find.byKey(const Key('character-health-decrease'));

      await tester.tap(decrease);
      await tester.pump();
      expect(find.text('-1'), findsOneWidget);

      await tester.tapAt(const Offset(200, 200));
      await tester.pump();
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(
                const Key('character-health-negative-feedback'),
              ),
            )
            .opacity,
        0,
      );
      await tester.pumpAndSettle();
      expect(find.text('-1'), findsNothing);

      await tester.tap(decrease);
      await tester.pump();
      expect(find.text('-1'), findsOneWidget);
      expect(find.text('-2'), findsNothing);
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

      await tester.tap(find.byKey(const Key('character-health-increase')));
      await tester.pump();
      expect(
        find.byKey(const Key('character-health-positive-feedback')),
        findsNothing,
      );
    });
  });
}
