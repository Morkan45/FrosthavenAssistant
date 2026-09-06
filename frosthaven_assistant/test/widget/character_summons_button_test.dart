import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_summons_button.dart';
import 'package:frosthaven_assistant/Layout/menus/AddSummonMenu/add_summon_menu.dart';
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
  });

  group('CharacterSummonsButton', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      AddCharacterCommand('Banner Spear', 'Frosthaven', null, 1).execute();
      final character =
          getIt<GameState>().currentList.firstWhere(
                (e) => e.id == 'Banner Spear',
              )
              as Character;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSummonsButton(scale: 1.0, character: character),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CharacterSummonsButton), findsOneWidget);
    });

    testWidgets('tapping icon button opens AddSummonMenu', (
      WidgetTester tester,
    ) async {
      AddCharacterCommand('Banner Spear', 'Frosthaven', null, 1).execute();
      final character =
          getIt<GameState>().currentList.firstWhere(
                (e) => e.id == 'Banner Spear',
              )
              as Character;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSummonsButton(scale: 1.0, character: character),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('character-add-summon')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AddSummonMenu), findsOneWidget);
    });
  });
}
