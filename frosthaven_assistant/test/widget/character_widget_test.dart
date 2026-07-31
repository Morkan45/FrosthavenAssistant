import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_health_controls.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_level_widget.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_summons_button.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_widget.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_widget_internal.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_xp_widget.dart';
import 'package:frosthaven_assistant/Layout/menus/StatusMenu/status_menu.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/draw_command.dart';
import 'package:frosthaven_assistant/Resource/commands/next_round_command.dart';
import 'package:frosthaven_assistant/Resource/commands/turn_done_command.dart';
import 'package:frosthaven_assistant/Resource/game_data.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
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

  Future<void> pumpCharacterWidget(WidgetTester tester, {Size? size}) async {
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    final originalOnError = FlutterError.onError;
    FlutterError.onError = ignoreOverflowErrors(FlutterError.onError);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: const CharacterWidget(characterId: 'Blinkblade'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    FlutterError.onError = originalOnError;
  }

  group('CharacterWidget', () {
    testWidgets('renders when character exists', (WidgetTester tester) async {
      await pumpCharacterWidget(tester);
      expect(find.byType(CharacterWidget), findsOneWidget);
    });

    testWidgets('shows InkWell for tap interaction', (
      WidgetTester tester,
    ) async {
      await pumpCharacterWidget(tester);
      expect(find.byType(InkWell), findsAtLeast(1));
    });

    testWidgets('shows direct health controls instead of a summon button', (
      WidgetTester tester,
    ) async {
      await pumpCharacterWidget(tester);

      expect(find.byType(CharacterHealthControls), findsOneWidget);
      expect(find.byType(CharacterSummonsButton), findsNothing);
    });

    testWidgets('health controls stay inside the row and do not open status', (
      WidgetTester tester,
    ) async {
      final character = getIt<GameState>().currentList.single as Character;
      final initialHealth = character.characterState.health.value;
      await pumpCharacterWidget(tester, size: const Size(412, 915));

      final rowRect = tester.getRect(find.byType(CharacterWidgetInternal));
      final decrease = find.byKey(const Key('character-health-decrease'));
      final increase = find.byKey(const Key('character-health-increase'));
      final decreaseRect = tester.getRect(decrease);
      final increaseRect = tester.getRect(increase);
      final xpRect = tester.getRect(find.byType(CharacterXPWidget));
      final levelRect = tester.getRect(find.byType(CharacterLevelWidget));

      expect(decreaseRect.left, greaterThanOrEqualTo(rowRect.left));
      expect(increaseRect.right, lessThanOrEqualTo(rowRect.right));
      expect(xpRect.right, lessThanOrEqualTo(decreaseRect.left));
      expect(levelRect.right, lessThanOrEqualTo(decreaseRect.left));

      await tester.tap(decrease);
      await tester.pump();
      expect(character.characterState.health.value, initialHealth - 1);
      expect(find.byType(StatusMenu), findsNothing);

      await tester.tap(increase);
      await tester.pump();
      expect(character.characterState.health.value, initialHealth);
      expect(find.byType(StatusMenu), findsNothing);
    });

    testWidgets('tapping character widget opens StatusMenu', (
      WidgetTester tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors(FlutterError.onError);
      await pumpCharacterWidget(tester);
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      FlutterError.onError = originalOnError;
      expect(find.byType(StatusMenu), findsOneWidget);
    });

    testWidgets('returns empty Container when character not found', (
      WidgetTester tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors(FlutterError.onError);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CharacterWidget(characterId: 'NonExistent')),
        ),
      );
      await tester.pump();
      FlutterError.onError = originalOnError;
      // Should render without crash — returns Container()
      expect(find.byType(CharacterWidget), findsOneWidget);
    });

    testWidgets('renders ColorFiltered widget when character turn is done', (
      WidgetTester tester,
    ) async {
      final gs = getIt<GameState>();
      // ColorFiltered is only applied when notGrayScale is false (turn done in
      // playTurns). Draw to enter playTurns, then mark the character's turn done.
      DrawCommand(gameState: gs).execute();
      TurnDoneCommand('Blinkblade', gameState: gs).execute();
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors(FlutterError.onError);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CharacterWidget(characterId: 'Blinkblade'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      FlutterError.onError = originalOnError;
      expect(find.byType(ColorFiltered), findsAtLeast(1));
      // Reset round state for subsequent tests.
      NextRoundCommand(
        gameState: gs,
        gameData: getIt<GameData>(),
        settings: getIt<Settings>(),
      ).execute();
      await tester.pump(const Duration(milliseconds: 700));
    });

    testWidgets('renders health wheel when not in chooseInitiative round state', (
      WidgetTester tester,
    ) async {
      // Draw changes roundState to playTurns, triggering buildWithHealthWheel path
      DrawCommand(gameState: getIt<GameState>()).execute();
      final originalOnError = FlutterError.onError;
      FlutterError.onError = ignoreOverflowErrors(FlutterError.onError);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CharacterWidget(characterId: 'Blinkblade'),
            ),
          ),
        ),
      );
      // Pump past DrawCommand's 600ms Future.delayed timer
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      FlutterError.onError = originalOnError;
      expect(find.byType(CharacterWidget), findsOneWidget);
      // Reset round state (NextRoundCommand also has 600ms timer — pump past it)
      NextRoundCommand(
        gameState: getIt<GameState>(),
        gameData: getIt<GameData>(),
        settings: getIt<Settings>(),
      ).execute();
      await tester.pump(const Duration(milliseconds: 700));
    });
  });
}
