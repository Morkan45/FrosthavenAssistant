// ignore_for_file: no-magic-number, avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/menus/action_log_menu.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../../command/test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  GameState gs() => getIt<GameState>();

  setUp(() {
    gs().clearList();
    gs().resetCommandHistory();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(body: ActionLogMenu(gameState: gs())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists recent actions, newest action present', (tester) async {
    gs().action(AddCharacterCommand('Blinkblade', 'Frosthaven', 'Blinky', 1));
    gs().action(AddMonsterCommand('Zealot', 1, false, gameState: gs()));

    final descriptions = gs().commandDescriptions;
    expect(descriptions.length >= 2, true);

    await pump(tester);

    // Both the newest and previous actions render (using the exact stored
    // descriptions, so this is robust to wording/localisation).
    expect(find.text(descriptions.last), findsOneWidget);
    expect(find.text(descriptions[descriptions.length - 2]), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows empty state when there are no actions', (tester) async {
    await pump(tester);
    expect(find.text('No actions yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
