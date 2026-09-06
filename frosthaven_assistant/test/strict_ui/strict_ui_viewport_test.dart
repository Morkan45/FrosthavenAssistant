// ignore_for_file: no-magic-number

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/MainList/main_list.dart';
import 'package:frosthaven_assistant/Layout/menus/SettingsMenu/settings_menu.dart';
import 'package:frosthaven_assistant/Layout/menus/StatusMenu/status_menu.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/scaling.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../command/test_helpers.dart';

const _viewports = <String, Size>{
  'phone': Size(360, 800),
  'tablet': Size(800, 1280),
  'desktop 720p': Size(1280, 720),
  'desktop 1080p': Size(1920, 1080),
  'desktop 1440p': Size(2560, 1440),
};

void main() {
  setUpAll(setUpGame);

  setUp(() {
    getIt<GameState>().clearList();
    final settings = getIt<Settings>();
    settings.userScalingMainList.value = 1;
    settings.userScalingMenus.value = 1;
    settings.fitMainListToWidth.value = true;
    settings.mainListColumns.value = 0;
  });

  testWidgets('strict harness reports an overflow', (tester) async {
    _setViewport(tester, const Size(100, 100));

    await tester.pumpWidget(
      _app(const Row(children: [SizedBox(width: 80), SizedBox(width: 80)])),
    );

    expect(
      tester.takeException().toString(),
      startsWith('A RenderFlex overflowed by'),
    );
  });

  testWidgets('strict harness reports a missing asset', (tester) async {
    await tester.pumpWidget(
      _app(Image.asset('assets/images/does-not-exist.png')),
    );
    await tester.pump();

    expect(
      tester.takeException().toString(),
      startsWith('Unable to load asset'),
    );
  });

  testWidgets('main list is strict with one through three columns', (
    tester,
  ) async {
    _setViewport(tester, const Size(1920, 1080));
    _populateCharacters();
    final settings = getIt<Settings>();
    settings.userScalingMainList.value = 0.2;

    await tester.pumpWidget(_app(const Scaffold(body: MainList())));
    for (final columns in [1, 2, 3]) {
      settings.mainListColumns.value = columns;
      await tester.pumpAndSettle();

      final scope = tester.widget<MainListLayoutScope>(
        find.byType(MainListLayoutScope),
      );
      expect(scope.layout.columnCount, columns);
      expect(tester.takeException(), isNull);
    }
  });

  for (final viewport in _viewports.entries) {
    testWidgets('main list is strict at ${viewport.key}', (tester) async {
      _setViewport(tester, viewport.value);
      _populateBoard();

      await tester.pumpWidget(_app(const Scaffold(body: MainList())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(MainList), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('status dialog is strict at ${viewport.key}', (tester) async {
      _setViewport(tester, viewport.value);
      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 4).execute();

      await tester.pumpWidget(
        _dialogLauncher(
          const StatusMenu(
            figureId: 'Blinkblade',
            characterId: 'Blinkblade',
            monsterId: null,
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(StatusMenu), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('settings dialog is strict at ${viewport.key}', (tester) async {
      _setViewport(tester, viewport.value);

      await tester.pumpWidget(_dialogLauncher(const SettingsMenu()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsMenu), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _populateBoard() {
  _populateCharacters();
  final state = getIt<GameState>();
  for (final monster in ['Zealot', 'Vermling Raider']) {
    AddMonsterCommand(monster, 4, false, gameState: state).execute();
    state.action(
      AddStandeeCommand(
        1,
        null,
        monster,
        MonsterType.normal,
        false,
        gameState: state,
      ),
    );
  }
}

void _populateCharacters() {
  AddCharacterCommand('Blinkblade', 'Frosthaven', null, 4).execute();
  AddCharacterCommand('Banner Spear', 'Frosthaven', null, 4).execute();
  AddCharacterCommand('Hatchet', 'Jaws of the Lion', null, 4).execute();
  AddCharacterCommand('Demolitionist', 'Jaws of the Lion', null, 4).execute();
}

Widget _dialogLauncher(Widget dialog) => _app(
  Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () =>
              showDialog<void>(context: context, builder: (context) => dialog),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

Widget _app(Widget home) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en')],
  home: home,
);
