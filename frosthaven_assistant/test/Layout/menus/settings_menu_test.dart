import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/menus/SettingsMenu/settings_menu.dart';
import 'package:frosthaven_assistant/Layout/menus/SettingsMenu/settings_layout.dart';
import 'package:frosthaven_assistant/Layout/menus/save_menu.dart';
import 'package:frosthaven_assistant/Resource/commands/set_ally_deck_in_og_gloom_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../../command/test_helpers.dart';

void main() {
  setUpAll(() async {
    await setUpGame();
  });

  setUp(() {
    final settings = getIt<Settings>();
    settings.fitMainListToWidth.value = false;
    settings.mainListColumns.value = 0;
    settings.userScalingMenus.value = 1;
  });

  Future<void> pumpMenu(
    WidgetTester tester, {
    Size? size,
    double platformTextScale = 1,
  }) async {
    if (size != null) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(platformTextScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SettingsMenu(),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('SettingsMenu', () {
    test('uses adaptive typography tiers for available width', () {
      expect(SettingsLayoutMetrics.adaptiveTextScale(const Size(500, 900)), 1);
      expect(
        SettingsLayoutMetrics.adaptiveTextScale(const Size(1280, 720)),
        1.1,
      );
      expect(
        SettingsLayoutMetrics.adaptiveTextScale(const Size(2560, 1440)),
        1.2,
      );
    });

    testWidgets(
      'large desktop combines adaptive, menu, and accessibility scaling',
      (WidgetTester tester) async {
        getIt<Settings>().userScalingMenus.value = 1.25;
        await pumpMenu(
          tester,
          size: const Size(1920, 1080),
          platformTextScale: 1.3,
        );

        final textContext = tester.element(find.text('Dark mode'));
        final textScaler = MediaQuery.textScalerOf(textContext);
        expect(textScaler.scale(20), closeTo(39, 0.001));

        final desktopLayout = tester.getSize(
          find.byKey(const Key('desktop-settings-layout')),
        );
        expect(desktopLayout, const Size(1120, 760));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('mobile keeps its base adaptive scale', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester, size: const Size(500, 900));

      final textContext = tester.element(find.text('Dark mode'));
      expect(MediaQuery.textScalerOf(textContext).scale(20), 20);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop separates settings into persistent categories', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester, size: const Size(1280, 720));

      expect(find.byKey(const Key('desktop-settings-layout')), findsOneWidget);
      expect(
        find.byKey(const Key('settings-category-navigation')),
        findsOneWidget,
      );
      expect(find.text('Display'), findsOneWidget);
      expect(find.text('Gameplay'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Network'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.text('Expire Conditions'), findsNothing);

      await tester.tap(find.text('Gameplay'));
      await tester.pump();

      expect(find.text('Dark mode'), findsNothing);
      expect(find.text('Expire Conditions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile keeps every category in one scrollable column', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester, size: const Size(500, 900));

      expect(find.byKey(const Key('desktop-settings-layout')), findsNothing);
      expect(find.byKey(const Key('settings-section-display')), findsOneWidget);
      expect(
        find.byKey(const Key('settings-section-gameplay')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('settings-section-content')), findsOneWidget);
      expect(find.byKey(const Key('settings-section-network')), findsOneWidget);
      expect(
        find.byKey(const Key('settings-section-advanced')),
        findsOneWidget,
      );
      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.text('Expire Conditions'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Dark mode checkbox', (WidgetTester tester) async {
      await pumpMenu(tester);
      expect(find.text('Dark mode'), findsOneWidget);
    });

    testWidgets('renders Expire Conditions checkbox', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);
      expect(find.text('Expire Conditions'), findsOneWidget);
    });

    testWidgets('renders Close button', (WidgetTester tester) async {
      await pumpMenu(tester);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Escape closes settings from keyboard focus', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester, size: const Size(1280, 720));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsMenu), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('tapping Dark mode checkbox toggles the setting', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.darkMode.value;
      await pumpMenu(tester);

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Dark mode'));
      await tester.pump();

      expect(settings.darkMode.value, !before);
      // restore
      settings.darkMode.value = before;
    });

    testWidgets('tapping Expire Conditions checkbox toggles the setting', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.expireConditions.value;
      await pumpMenu(tester);

      final finder = find.widgetWithText(CheckboxListTile, 'Expire Conditions');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();

      expect(settings.expireConditions.value, !before);
      settings.expireConditions.value = before;
    });

    testWidgets('tapping Soft numpad for input checkbox toggles the setting', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.softNumpadInput.value;
      await pumpMenu(tester);

      final finder = find.widgetWithText(
        CheckboxListTile,
        'Soft numpad for input',
      );
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();

      expect(settings.softNumpadInput.value, !before);
      settings.softNumpadInput.value = before;
    });

    testWidgets("tapping Don't ask for initiative checkbox toggles setting", (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.noInit.value;
      await pumpMenu(tester);

      final finder = find.widgetWithText(
        CheckboxListTile,
        "Don't ask for initiative",
      );
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();

      expect(settings.noInit.value, !before);
      settings.noInit.value = before;
    });

    testWidgets('tapping Auto Add Standees checkbox toggles the setting', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.autoAddStandees.value;
      await pumpMenu(tester);

      final finder = find.widgetWithText(CheckboxListTile, 'Auto Add Standees');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();

      expect(settings.autoAddStandees.value, !before);
      settings.autoAddStandees.value = before;
    });

    testWidgets('tapping Random Standees checkbox toggles the setting', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.randomStandees.value;
      await pumpMenu(tester);

      final finder = find.widgetWithText(CheckboxListTile, 'Random Standees');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();

      expect(settings.randomStandees.value, !before);
      settings.randomStandees.value = before;
    });

    testWidgets('tapping No Calculations checkbox toggles the setting', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.noCalculation.value;
      await pumpMenu(tester);

      final finder = find.widgetWithText(CheckboxListTile, 'No Calculations');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();

      expect(settings.noCalculation.value, !before);
      settings.noCalculation.value = before;
    });

    testWidgets("tapping Don't track Standees checkbox toggles setting", (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.noStandees.value;
      await pumpMenu(tester);

      final finder = find.widgetWithText(
        CheckboxListTile,
        "Don't track Standees",
      );
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();

      expect(settings.noStandees.value, !before);
      settings.noStandees.value = before;
    });

    testWidgets('tapping Auto Add Timed Spawns checkbox toggles setting', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.autoAddSpawns.value;
      await pumpMenu(tester);

      final finder = find.widgetWithText(
        CheckboxListTile,
        'Auto Add Timed Spawns',
      );
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();

      expect(settings.autoAddSpawns.value, !before);
      settings.autoAddSpawns.value = before;
    });

    testWidgets('tapping Hide Loot Deck checkbox toggles setting', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.hideLootDeck.value;
      await pumpMenu(tester);

      final finder = find.widgetWithText(CheckboxListTile, 'Hide Loot Deck');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();

      expect(settings.hideLootDeck.value, !before);
      settings.hideLootDeck.value = before;
    });

    testWidgets('tapping Stat card text shimmers checkbox toggles setting', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.shimmer.value;
      await pumpMenu(tester);

      final finder = find.widgetWithText(
        CheckboxListTile,
        'Stat card text shimmers',
      );
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();

      expect(settings.shimmer.value, !before);
      settings.shimmer.value = before;
    });

    testWidgets(
      'tapping Show Scenario names in list checkbox toggles setting',
      (WidgetTester tester) async {
        final settings = getIt<Settings>();
        final before = settings.showScenarioNames.value;
        await pumpMenu(tester);

        final finder = find.widgetWithText(
          CheckboxListTile,
          'Show Scenario names in list',
        );
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump();

        expect(settings.showScenarioNames.value, !before);
        settings.showScenarioNames.value = before;
      },
    );

    testWidgets('tapping Show Battle Goal Reminder checkbox toggles setting', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.showBattleGoalReminder.value;
      await pumpMenu(tester);

      final finder = find.widgetWithText(
        CheckboxListTile,
        'Show Battle Goal Reminder',
      );
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();

      expect(settings.showBattleGoalReminder.value, !before);
      settings.showBattleGoalReminder.value = before;
    });

    testWidgets('tapping Show Custom Content checkbox toggles setting', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.showCustomContent.value;
      await pumpMenu(tester);

      final finder = find.widgetWithText(
        CheckboxListTile,
        'Show Custom Content',
      );
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();

      expect(settings.showCustomContent.value, !before);
      settings.showCustomContent.value = before;
    });

    testWidgets(
      'tapping Show Sections in Main Screen checkbox toggles setting',
      (WidgetTester tester) async {
        final settings = getIt<Settings>();
        final before = settings.showSectionsInMainView.value;
        await pumpMenu(tester);

        final finder = find.widgetWithText(
          CheckboxListTile,
          'Show Sections in Main Screen',
        );
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump();

        expect(settings.showSectionsInMainView.value, !before);
        settings.showSectionsInMainView.value = before;
      },
    );

    testWidgets(
      'tapping Show Round Special Rule Reminders checkbox toggles setting',
      (WidgetTester tester) async {
        final settings = getIt<Settings>();
        final before = settings.showReminders.value;
        await pumpMenu(tester);

        final finder = find.widgetWithText(
          CheckboxListTile,
          'Show Round Special Rule Reminders',
        );
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump();

        expect(settings.showReminders.value, !before);
        settings.showReminders.value = before;
      },
    );

    testWidgets('tapping Show Attack Modifier Decks checkbox toggles setting', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.showAmdDeck.value;
      await pumpMenu(tester);

      final finder = find.widgetWithText(
        CheckboxListTile,
        'Show Attack Modifier Decks',
      );
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();

      expect(settings.showAmdDeck.value, !before);
      settings.showAmdDeck.value = before;
    });

    testWidgets(
      'tapping Show character Attack Modifier Decks checkbox toggles setting',
      (WidgetTester tester) async {
        final settings = getIt<Settings>();
        final before = settings.showCharacterAMD.value;
        await pumpMenu(tester);

        final finder = find.widgetWithText(
          CheckboxListTile,
          'Show character Attack Modifier Decks',
        );
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump();

        expect(settings.showCharacterAMD.value, !before);
        settings.showCharacterAMD.value = before;
      },
    );

    testWidgets('tapping Style radio buttons changes the style', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      await pumpMenu(tester);

      // Find and tap the 'Original' radio button
      final originalFinder = find.descendant(
        of: find.widgetWithText(Row, 'Original'),
        matching: find.byType(Radio<Style>),
      );
      if (originalFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(originalFinder.first);
        await tester.tap(originalFinder.first);
        await tester.pump();
        expect(settings.style.value, Style.original);
      }
      // Restore to Frosthaven style
      settings.style.value = Style.frosthaven;
    });

    testWidgets('tapping Clear unlocked characters runs the command', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);

      final finder = find.widgetWithText(
        ListTile,
        'Clear unlocked characters and stuff',
      );
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();
      expect(
        find.widgetWithText(ListTile, 'Clear unlocked characters and stuff'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Load/Save State opens SaveMenu', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);

      final finder = find.widgetWithText(ListTile, 'Load/Save State');
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(find.byType(SaveMenu), findsOneWidget);
    });

    testWidgets(
      'tapping Use Ally AMD in OG Gloomhaven checkbox toggles setting',
      (WidgetTester tester) async {
        final gameState = getIt<GameState>();
        final before = gameState.allyDeckInOGGloom.value;
        await pumpMenu(tester);

        final finder = find.widgetWithText(
          CheckboxListTile,
          'Use Ally Attack Modifier Deck in OG Gloomhaven',
        );
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump();

        expect(gameState.allyDeckInOGGloom.value, !before);
        // restore
        getIt<GameState>().action(
          SetAllyDeckInOgGloomCommand(before, gameState: getIt<GameState>()),
        );
      },
    );

    testWidgets('Main List Scaling updates while the pointer is down', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.userScalingMainList.value;

      await pumpMenu(tester);
      final slider = find.byType(Slider).first; // Main List Scaling
      await tester.ensureVisible(slider);
      final gesture = await tester.startGesture(tester.getCenter(slider));
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();

      expect(
        settings.userScalingMainList.value,
        isNot(before),
        reason: 'the main-list scale must update before pointer release',
      );
      await gesture.up();
      settings.userScalingMainList.value = before;
    });

    testWidgets('fit-width checkbox reveals the column selector', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      await pumpMenu(tester);

      final checkbox = find.widgetWithText(
        CheckboxListTile,
        'Fit main list to screen width',
      );
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();

      expect(settings.fitMainListToWidth.value, isTrue);
      expect(
        find.byKey(const Key('main-list-columns-selector')),
        findsOneWidget,
      );
    });

    testWidgets('column selector updates the desktop column preference', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      settings.fitMainListToWidth.value = true;
      await pumpMenu(tester);

      final selector = find.byKey(const Key('main-list-columns-selector'));
      await tester.ensureVisible(selector);
      await tester.tap(find.descendant(of: selector, matching: find.text('3')));
      await tester.pump();

      expect(settings.mainListColumns.value, 3);
    });

    testWidgets('scale presets update all layout scales and keep fine tuning', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      await pumpMenu(tester);

      final presets = find.byKey(const Key('layout-scale-presets'));
      await tester.ensureVisible(presets);
      await tester.tap(
        find.descendant(of: presets, matching: find.text('Large')),
      );
      await tester.pump();

      expect(settings.userScalingMainList.value, 1.5);
      expect(settings.userScalingBars.value, 2);
      expect(settings.userScalingMenus.value, 1.2);

      final mainScaleSlider = find.byType(Slider).first;
      await tester.drag(mainScaleSlider, const Offset(-30, 0));
      await tester.pump();

      expect(settings.userScalingMainList.value, isNot(1.5));
    });

    testWidgets('App Bar Scaling updates while the pointer is down', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.userScalingBars.value;

      await pumpMenu(tester);
      final slider = find.byType(Slider).at(1); // App Bar Scaling
      await tester.ensureVisible(slider);
      final gesture = await tester.startGesture(tester.getCenter(slider));
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();

      expect(
        settings.userScalingBars.value,
        isNot(before),
        reason: 'the app-bar scale must update before pointer release',
      );
      await gesture.up();
      settings.userScalingBars.value = before;
    });

    testWidgets('Menu Scaling updates while the pointer is down', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.userScalingMenus.value;

      await pumpMenu(tester);
      final slider = find.byType(Slider).at(2);
      await tester.ensureVisible(slider);
      final gesture = await tester.startGesture(tester.getCenter(slider));
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();

      expect(settings.userScalingMenus.value, isNot(before));
      await gesture.up();
      settings.userScalingMenus.value = before;
    });

    testWidgets('renders the three power-saving tiers with an info button', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);
      expect(find.text('Power saving'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Dim when idle'), findsOneWidget);
      expect(find.text('Reduce power use'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('selecting a tier updates the setting', (
      WidgetTester tester,
    ) async {
      final settings = getIt<Settings>();
      final before = settings.powerMode.value;
      addTearDown(() => settings.powerMode.value = before);

      await pumpMenu(tester);
      final radio = find.byWidgetPredicate(
        (w) => w is Radio<PowerMode> && w.value == PowerMode.dimWhenIdle,
      );
      await tester.ensureVisible(radio);
      await tester.pumpAndSettle();
      await tester.tap(radio);
      await tester.pumpAndSettle();

      expect(settings.powerMode.value, PowerMode.dimWhenIdle);
    });

    testWidgets('info button sits to the right of the Power saving label', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);
      final label = find.text('Power saving');
      final icon = find.byIcon(Icons.info_outline);
      await tester.ensureVisible(icon);
      await tester.pumpAndSettle();

      final labelRect = tester.getRect(label);
      final iconRect = tester.getRect(icon);
      expect(
        iconRect.left,
        greaterThanOrEqualTo(labelRect.right),
        reason: 'the info button must follow the label, not lead it',
      );
      // Same row, not wrapped onto a line of its own.
      expect((iconRect.center.dy - labelRect.center.dy).abs(), lessThan(8));
    });

    testWidgets('info button explains all three power tiers', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);
      final infoButton = find.byIcon(Icons.info_outline);
      await tester.ensureVisible(infoButton);
      await tester.pumpAndSettle();
      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      // The title text appears both in the dialog and behind it on the row.
      expect(find.text('Power saving'), findsNWidgets(2));

      final dialogText = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data ?? '')
          .join('\n');
      // The tradeoffs the user asked to be spelled out in-app.
      expect(dialogText, contains('Dim when idle'));
      expect(dialogText, contains('dims and turns off'));
      expect(dialogText, contains('shadows'));
      expect(dialogText, contains('shimmering text effects'));
      expect(dialogText, contains('no tracking, syncing or rules behaviour'));
      expect(
        dialogText,
        contains('infrequent use and low battery capacity devices'),
      );
    });
  });
}
