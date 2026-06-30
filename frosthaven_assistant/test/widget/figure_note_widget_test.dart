// ignore_for_file: no-magic-number, avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/figure_note_widget.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_figure_note_command.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  GameState gs() => getIt<GameState>();

  setUp(() {
    gs().clearList();
  });

  Future<void> pump(WidgetTester tester, ListItemData figure) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: FigureNoteWidget(figure: figure, scale: 1.0, gameState: gs()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a character note when set', (tester) async {
    AddCharacterCommand('Blinkblade', 'Frosthaven', 'Blinky', 1).execute();
    final character =
        gs().currentList.firstWhere((e) => e is Character) as Character;
    gs().action(
        SetFigureNoteCommand('poison next turn', 'Blinkblade', gameState: gs()));
    await pump(tester, character);

    expect(find.text('poison next turn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a monster note when set', (tester) async {
    AddMonsterCommand('Zealot', 1, false, gameState: gs()).execute();
    final monster = gs().currentList.firstWhere((e) => e is Monster) as Monster;
    gs().action(SetFigureNoteCommand('focus first', 'Zealot', gameState: gs()));
    await pump(tester, monster);

    expect(find.text('focus first'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders nothing when the note is empty', (tester) async {
    AddCharacterCommand('Blinkblade', 'Frosthaven', 'Blinky', 1).execute();
    final character =
        gs().currentList.firstWhere((e) => e is Character) as Character;
    await pump(tester, character);

    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
