// ignore_for_file: no-magic-number, avoid-late-keyword

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/menus/action_log_menu.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_level_command.dart';
import 'package:frosthaven_assistant/Resource/game_event.dart';
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

    final descriptions = gs()
        .historyEntries
        .map((entry) => entry.description)
        .toList(growable: false);
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

  testWidgets('mounted history shows received snapshots and same-index corrections', (tester) async {
    gs().action(SetLevelCommand(2, null));
    final first = gs().toString();
    gs().action(SetLevelCommand(3, null));
    final second = gs().toString();
    gs().resetCommandHistory();
    await pump(tester);

    for (final item in [(0, first, 'received A'), (1, second, 'received B')]) {
      expect(gs().applyReceivedTransition(
        state: item.$2,
        index: item.$1,
        description: item.$3,
        event: const NoEvent(),
        kind: ReceivedTransitionKind.newStep,
      ), isTrue);
    }
    await tester.pump();
    expect(find.text('received A'), findsOneWidget);
    expect(find.text('received B'), findsOneWidget);

    expect(gs().applyReceivedTransition(
      state: second,
      index: 1,
      description: 'corrected B',
      event: const NoEvent(),
      kind: ReceivedTransitionKind.authoritativeCorrection,
    ), isTrue);
    await tester.pump();
    expect(find.text('received B'), findsNothing);
    expect(find.text('corrected B'), findsOneWidget);

    await tester.tap(find.ancestor(
      of: find.text('received A'), matching: find.byType(InkWell),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roll back'));
    await tester.pumpAndSettle();
    expect(gs().commandIndex.value, 0);
    expect(gs().level.value, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rolls back directly to the selected action', (tester) async {
    gs().action(SetLevelCommand(2, null));
    gs().action(SetLevelCommand(4, null));

    await pump(tester);
    await tester.tap(
      find.ancestor(of: find.text('1.'), matching: find.byType(InkWell)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roll back'));
    await tester.pumpAndSettle();

    expect(gs().commandIndex.value, 0);
    expect(gs().level.value, 2);
    expect(gs().canRedo, isTrue);
  });
}
