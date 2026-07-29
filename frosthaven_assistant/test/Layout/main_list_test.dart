import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_widget.dart';
import 'package:frosthaven_assistant/Layout/MainList/main_list.dart';
import 'package:frosthaven_assistant/Layout/MainList/main_list_item.dart';
import 'package:frosthaven_assistant/Layout/MonsterWidget/monster_widget.dart';
import 'package:frosthaven_assistant/Layout/background.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/commands/reorder_list_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/scaling.dart';
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
    final settings = getIt<Settings>();
    settings.userScalingMainList.value = 1;
    settings.fitMainListToWidth.value = false;
    settings.mainListColumns.value = 0;
  });

  void populateDenseBoard() {
    final state = getIt<GameState>();
    AddCharacterCommand('Blinkblade', 'Frosthaven', null, 4).execute();
    AddCharacterCommand('Banner Spear', 'Frosthaven', null, 4).execute();
    AddCharacterCommand('Hatchet', 'Jaws of the Lion', null, 4).execute();
    AddCharacterCommand('Demolitionist', 'Jaws of the Lion', null, 4).execute();

    const monsters = [
      'Zealot',
      'Vermling Raider',
      'Ancient Artillery (FH)',
      'Rat Monstrosity',
      'Black Sludge',
    ];
    for (var index = 0; index < monsters.length; index++) {
      final monster = monsters[index];
      AddMonsterCommand(monster, 4, false, gameState: state).execute();
      state.action(
        AddStandeeCommand(
          index + 1,
          null,
          monster,
          MonsterType.normal,
          false,
          gameState: state,
        ),
      );
    }
  }

  Future<void> pumpWidget(WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    addTearDown(() => FlutterError.onError = originalOnError);
    FlutterError.onError = ignoreOverflowErrors;
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MainList())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    FlutterError.onError = originalOnError;
  }

  group('MainList', () {
    testWidgets('renders BackGround widget', (WidgetTester tester) async {
      await pumpWidget(tester);
      expect(find.byType(BackGround), findsOneWidget);
    });

    testWidgets('renders Scrollbar', (WidgetTester tester) async {
      await pumpWidget(tester);
      expect(find.byType(Scrollbar), findsNWidgets(2));
    });

    testWidgets('renders SingleChildScrollView', (WidgetTester tester) async {
      await pumpWidget(tester);
      expect(find.byType(SingleChildScrollView), findsAtLeast(1));
    });

    testWidgets('renders empty list without crashing when no items', (
      WidgetTester tester,
    ) async {
      await pumpWidget(tester);
      expect(find.byType(MainList), findsOneWidget);
      expect(find.byType(CharacterWidget), findsNothing);
      expect(find.byType(MonsterWidget), findsNothing);
    });

    testWidgets('renders CharacterWidget when a character is added', (
      WidgetTester tester,
    ) async {
      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
      await pumpWidget(tester);
      expect(find.byType(CharacterWidget), findsOneWidget);
    });

    testWidgets('renders MonsterWidget when a monster is added', (
      WidgetTester tester,
    ) async {
      AddMonsterCommand(
        'Zealot',
        1,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      await pumpWidget(tester);
      expect(find.byType(MonsterWidget), findsOneWidget);
    });

    testWidgets('renders both CharacterWidget and MonsterWidget together', (
      WidgetTester tester,
    ) async {
      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
      AddMonsterCommand(
        'Zealot',
        1,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      await pumpWidget(tester);
      expect(find.byType(CharacterWidget), findsOneWidget);
      expect(find.byType(MonsterWidget), findsOneWidget);
    });

    testWidgets('renders Item wrapper for each list element', (
      WidgetTester tester,
    ) async {
      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
      await pumpWidget(tester);
      expect(find.byType(MainListItem), findsAtLeast(1));
    });

    testWidgets('scrollToTop does not crash when called with no clients', (
      WidgetTester tester,
    ) async {
      // Before any widget is pumped, scrollController has no clients
      MainList.scrollToTop();
      await pumpWidget(tester);
      MainList.scrollToTop(); // After pumping, has a client
      expect(find.byType(MainList), findsOneWidget);
    });

    testWidgets('fit-width auto layout uses one column when content fits', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final settings = getIt<Settings>();
      settings.fitMainListToWidth.value = true;
      settings.mainListColumns.value = 0;
      addTearDown(() {
        settings.fitMainListToWidth.value = false;
        settings.mainListColumns.value = 0;
      });

      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
      AddCharacterCommand('Banner Spear', 'Frosthaven', null, 1).execute();
      AddMonsterCommand(
        'Zealot',
        1,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      AddMonsterCommand(
        'Vermling Raider',
        1,
        false,
        gameState: getIt<GameState>(),
      ).execute();

      await pumpWidget(tester);

      final items = find.byType(MainListItem);
      expect(items, findsNWidgets(4));
      final scope = tester.widget<MainListLayoutScope>(
        find.byType(MainListLayoutScope),
      );
      expect(scope.layout.columnCount, 1);
      expect(scope.layout.columnWidth, 900);
      final distinctColumns = <int>{
        for (var i = 0; i < 4; i++) tester.getTopLeft(items.at(i)).dx.round(),
      };
      expect(distinctColumns, hasLength(1));
      expect(distinctColumns.single, 830);
    });

    testWidgets('fit-width auto layout uses two columns for a dense board', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final settings = getIt<Settings>();
      settings.fitMainListToWidth.value = true;
      settings.userScalingMainList.value = 1.2;
      populateDenseBoard();

      await pumpWidget(tester);

      final scope = tester.widget<MainListLayoutScope>(
        find.byType(MainListLayoutScope),
      );
      expect(scope.layout.columnCount, 2);
    });

    testWidgets('fit-width auto layout adds a third column when enlarged', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final settings = getIt<Settings>();
      settings.fitMainListToWidth.value = true;
      settings.userScalingMainList.value = 1.8;
      populateDenseBoard();

      await pumpWidget(tester);

      final scope = tester.widget<MainListLayoutScope>(
        find.byType(MainListLayoutScope),
      );
      expect(scope.layout.columnCount, 3);
      expect(scope.layout.columnWidth, closeTo(1536, 0.01));
      expect(scope.layout.contentWidth, closeTo(4608, 0.01));

      final frameworkErrors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = frameworkErrors.add;
      addTearDown(() => FlutterError.onError = originalOnError);

      settings.userScalingMainList.value = 2;
      await tester.pump();

      final scaledScope = tester.widget<MainListLayoutScope>(
        find.byType(MainListLayoutScope),
      );
      expect(scaledScope.layout.columnCount, 3);
      expect(scaledScope.layout.columnWidth, closeTo(1706.67, 0.01));
      expect(scaledScope.layout.contentWidth, closeTo(5120, 0.01));
      expect(frameworkErrors, isEmpty);
    });
  });

  group('FLIP animation', () {
    testWidgets('translates items when list order changes', (
      WidgetTester tester,
    ) async {
      AddMonsterCommand(
        'Zealot',
        1,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      AddMonsterCommand(
        'Vermling Raider',
        1,
        false,
        gameState: getIt<GameState>(),
      ).execute();

      final originalOnError = FlutterError.onError;
      addTearDown(() => FlutterError.onError = originalOnError);
      FlutterError.onError = ignoreOverflowErrors;

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MainList())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Capture layout y-positions before the reorder.
      final monsterFinder = find.byType(MonsterWidget);
      final yBefore0 = tester.getTopLeft(monsterFinder.at(0)).dy;
      final yBefore1 = tester.getTopLeft(monsterFinder.at(1)).dy;
      expect(
        yBefore0,
        isNot(equals(yBefore1)),
        reason: 'Monsters must start at different y-positions for FLIP to work',
      );

      // Swap the two monsters.  ReorderListCommand calls updateList.notify()
      // internally, which fires _onUpdateList → _capturePositions + setState
      // + addPostFrameCallback.
      getIt<GameState>().action(
        ReorderListCommand(0, 1, gameState: getIt<GameState>()),
      );

      // One pump: rebuild + layout + post-frame callback (starts the
      // AnimationController via animateFrom).
      await tester.pump();

      // Advance the 500 ms animation to its midpoint.
      await tester.pump(const Duration(milliseconds: 250));

      // At the midpoint the FLIP offset should be ~half the item height.
      // We look for any Transform whose y-translation exceeds a small
      // threshold to avoid false positives from identity matrices.
      final transforms = tester
          .widgetList<Transform>(find.byType(Transform))
          .toList();
      // Matrix4 is column-major; y-translation is at storage index 13.
      final nonZeroYTranslations = transforms
          .map((t) => t.transform.storage[13].abs())
          .where((abs) => abs > 1.0)
          .toList();

      expect(
        nonZeroYTranslations,
        isNotEmpty,
        reason:
            'Expected at least one Transform with a non-zero '
            'y-translation at animation midpoint.\n'
            'All y-translations: ${transforms.map((t) => t.transform.storage[13]).toList()}',
      );
    });
  });

  group('Item widget', () {
    testWidgets('wraps CharacterWidget in AnimatedContainer', (
      WidgetTester tester,
    ) async {
      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
      final character =
          getIt<GameState>().currentList.firstWhere((e) => e is Character)
              as Character;
      final originalOnError = FlutterError.onError;
      addTearDown(() => FlutterError.onError = originalOnError);
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MainListItem(data: character)),
        ),
      );
      await tester.pump();
      FlutterError.onError = originalOnError;
      expect(find.byType(AnimatedContainer), findsOneWidget);
      expect(find.byType(CharacterWidget), findsOneWidget);
    });

    testWidgets('wraps MonsterWidget in AnimatedContainer', (
      WidgetTester tester,
    ) async {
      AddMonsterCommand(
        'Zealot',
        1,
        false,
        gameState: getIt<GameState>(),
      ).execute();
      final monster =
          getIt<GameState>().currentList.firstWhere((e) => e is Monster)
              as Monster;
      final originalOnError = FlutterError.onError;
      addTearDown(() => FlutterError.onError = originalOnError);
      FlutterError.onError = ignoreOverflowErrors;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MainListItem(data: monster)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      FlutterError.onError = originalOnError;
      expect(find.byType(AnimatedContainer), findsOneWidget);
      expect(find.byType(MonsterWidget), findsOneWidget);
    });
  });
}
