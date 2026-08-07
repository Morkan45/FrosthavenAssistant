// ignore_for_file: no-magic-number, avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/NoteWidget/note_row_widget.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
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

  Future<void> pumpNote(WidgetTester tester, NoteRow note) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        // A Wrap reproduces the list's unbounded-width layout context, so a
        // row that wrongly relied on Expanded would throw here.
        home: Scaffold(
          body: SingleChildScrollView(
            child: Wrap(
              children: [NoteRowWidget(data: note, gameState: gs())],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unlinked note renders its text without overflow',
      (tester) async {
    final note = NoteRow.create('note1', text: 'remember to focus');
    await pumpNote(tester, note);

    expect(find.text('remember to focus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('player note shows just the text (no name label)',
      (tester) async {
    AddCharacterCommand('Blinkblade', 'Frosthaven', 'Blinky', 1).execute();
    final note =
        NoteRow.create('note1', text: 'low hp', linkedId: 'Blinkblade');
    await pumpNote(tester, note);

    expect(find.text('low hp'), findsOneWidget);
    // The player row is distinct, so no name/number prefix is shown.
    expect(find.text('Blinky'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('monster note is prefixed with the standee number', (tester) async {
    AddMonsterCommand('Zealot', 1, false, gameState: gs()).execute();
    final note = NoteRow.create('note1',
        text: 'shield', linkedId: 'Zealot', standeeNr: 3);
    await pumpNote(tester, note);

    expect(find.text('3:'), findsOneWidget);
    expect(find.text('shield'), findsOneWidget);
    // The monster's name is not shown (the number identifies the standee).
    expect(find.textContaining('Zealot'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('monster note for the whole group shows "All:"', (tester) async {
    AddMonsterCommand('Zealot', 1, false, gameState: gs()).execute();
    final note =
        NoteRow.create('note1', text: 'focus', linkedId: 'Zealot');
    await pumpNote(tester, note);

    expect(find.text('All:'), findsOneWidget);
    expect(find.text('focus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
