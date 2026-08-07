import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_widget.dart';
import 'package:frosthaven_assistant/Layout/MainList/main_list.dart';
import 'package:frosthaven_assistant/Layout/MainList/main_list_item.dart';
import 'package:frosthaven_assistant/Layout/MonsterWidget/monster_widget.dart';
import 'package:frosthaven_assistant/Layout/background.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_monster_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/commands/draw_command.dart';
import 'package:frosthaven_assistant/Resource/commands/next_round_command.dart';
import 'package:frosthaven_assistant/Resource/commands/reorder_list_command.dart';
import 'package:frosthaven_assistant/Resource/commands/turn_done_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/game_data.dart';
import 'package:frosthaven_assistant/Resource/scaling.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';
import 'package:reorderables/reorderables.dart';

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

  Future<void> pumpWidget(
    WidgetTester tester, {
    TargetPlatform platform = TargetPlatform.windows,
  }) async {
    final originalOnError = FlutterError.onError;
    addTearDown(() => FlutterError.onError = originalOnError);
    FlutterError.onError = ignoreOverflowErrors(FlutterError.onError);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        home: const Scaffold(body: MainList()),
      ),
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
      expect(find.byType(Scrollbar), findsAtLeast(1));
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

    testWidgets('character tracks stay aligned at minimum and maximum scale', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2560, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final settings = getIt<Settings>();
      settings.fitMainListToWidth.value = true;
      settings.mainListColumns.value = 3;
      settings.userScalingMainList.value = 3;
      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
      await pumpWidget(tester);

      void expectAlignedTracks() {
        final itemContext = tester.element(find.byType(MainListItem));
        final scale = getMainListLayout(itemContext).scale;
        final icon = tester.getRect(
          find.byKey(const Key('character-icon-column')),
        );
        final initiative = tester.getRect(
          find.byKey(const Key('character-initiative-column')),
        );
        final details = tester.getRect(
          find.byKey(const Key('character-details-column')),
        );

        expect(icon.width, closeTo(62 * scale, 0.01));
        expect(initiative.width, closeTo(45 * scale, 0.01));
        expect(details.width, closeTo(145 * scale, 0.01));
        expect(initiative.left, closeTo(icon.right, 0.01));
        expect(details.left, closeTo(initiative.right, 0.01));
      }

      expectAlignedTracks();
      settings.userScalingMainList.value = 0.2;
      await tester.pumpAndSettle();
      expectAlignedTracks();

      final name = tester.widget<Text>(find.byKey(const Key('character-name')));
      expect(name.maxLines, 1);
      expect(name.overflow, TextOverflow.ellipsis);
    });

    testWidgets('turn state uses distinct play and completed markers', (
      WidgetTester tester,
    ) async {
      final state = getIt<GameState>();
      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
      await pumpWidget(tester);
      final id = state.currentList.single.id;

      expect(find.byKey(Key('turn-state-current-$id')), findsNothing);
      expect(find.byKey(Key('turn-state-done-$id')), findsNothing);

      DrawCommand(gameState: state).execute();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(Key('turn-state-current-$id')), findsOneWidget);

      TurnDoneCommand(id, gameState: state).execute();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(Key('turn-state-current-$id')), findsNothing);
      expect(find.byKey(Key('turn-state-done-$id')), findsOneWidget);

      NextRoundCommand(
        gameState: state,
        gameData: getIt<GameData>(),
        settings: getIt<Settings>(),
      ).execute();
      await tester.pump(const Duration(milliseconds: 700));
    });

    testWidgets('desktop uses immediate drag with a grab cursor', (
      WidgetTester tester,
    ) async {
      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
      AddCharacterCommand('Banner Spear', 'Frosthaven', null, 1).execute();
      await pumpWidget(tester);

      final reorderable = tester.widget<ReorderableWrap>(
        find.byType(ReorderableWrap),
      );
      expect(reorderable.needsLongPressDraggable, isFalse);
      final rowCursor = find.ancestor(
        of: find.byType(MainListItem),
        matching: find.byType(MouseRegion),
      );
      expect(
        tester.widget<MouseRegion>(rowCursor.first).cursor,
        SystemMouseCursors.grab,
      );

      final items = find.byType(MainListItem);
      final firstId = getIt<GameState>().currentList.first.id;
      final secondId = getIt<GameState>().currentList[1].id;
      final firstCenter = tester.getCenter(items.at(0));
      final secondCenter = tester.getCenter(items.at(1));
      final gesture = await tester.startGesture(
        firstCenter,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await gesture.moveTo(secondCenter);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(
        Offset(0, tester.getRect(items.at(1)).height * 0.75),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(getIt<GameState>().currentList.first.id, secondId);
      expect(getIt<GameState>().currentList[1].id, firstId);
    });

    testWidgets('focused rows can be reordered with Alt and arrow keys', (
      WidgetTester tester,
    ) async {
      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
      AddCharacterCommand('Banner Spear', 'Frosthaven', null, 1).execute();
      await pumpWidget(tester);

      final state = getIt<GameState>();
      final firstId = state.currentList.first.id;
      final secondId = state.currentList[1].id;
      final interaction = find.byKey(Key('keyboard-reorder-$firstId'));
      final detector = tester.widget<FocusableActionDetector>(interaction);
      detector.focusNode!.requestFocus();
      await tester.pump();

      expect(detector.focusNode!.hasFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();

      expect(state.currentList.first.id, secondId);
      expect(state.currentList[1].id, firstId);
      expect(
        tester.widget<FocusableActionDetector>(interaction).focusNode!.hasFocus,
        isTrue,
      );
    });

    testWidgets('mobile retains long-press drag behavior', (
      WidgetTester tester,
    ) async {
      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
      AddCharacterCommand('Banner Spear', 'Frosthaven', null, 1).execute();
      await pumpWidget(tester, platform: TargetPlatform.android);

      final reorderable = tester.widget<ReorderableWrap>(
        find.byType(ReorderableWrap),
      );
      expect(reorderable.needsLongPressDraggable, isTrue);

      final items = find.byType(MainListItem);
      final firstId = getIt<GameState>().currentList.first.id;
      final secondId = getIt<GameState>().currentList[1].id;
      final firstCenter = tester.getCenter(items.at(0));
      final secondCenter = tester.getCenter(items.at(1));

      final immediateGesture = await tester.startGesture(firstCenter);
      await immediateGesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await immediateGesture.moveTo(secondCenter);
      await tester.pump();
      await immediateGesture.up();
      await tester.pumpAndSettle();
      expect(getIt<GameState>().currentList.first.id, firstId);

      final longPressGesture = await tester.startGesture(firstCenter);
      await tester.pump(const Duration(milliseconds: 600));
      await longPressGesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await longPressGesture.moveTo(secondCenter);
      await tester.pump(const Duration(milliseconds: 100));
      await longPressGesture.moveBy(
        Offset(0, tester.getRect(items.at(1)).height * 0.75),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await longPressGesture.up();
      await tester.pumpAndSettle();
      expect(getIt<GameState>().currentList.first.id, secondId);
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
      final distinctColumns = <int>{
        for (var i = 0; i < 4; i++) tester.getTopLeft(items.at(i)).dx.round(),
      };
      expect(distinctColumns, hasLength(1));
      final firstItemBounds = tester.getRect(items.first);
      expect(firstItemBounds.center.dx, closeTo(1280, 0.5));
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

    testWidgets(
      'fit-width auto layout adds a third column at maximum scaling',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(2560, 1080);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final settings = getIt<Settings>();
        settings.fitMainListToWidth.value = true;
        settings.userScalingMainList.value = 3;
        populateDenseBoard();

        await pumpWidget(tester);

        final scope = tester.widget<MainListLayoutScope>(
          find.byType(MainListLayoutScope),
        );
        expect(scope.layout.columnCount, 3);
        expect(scope.layout.columnWidth * 3, lessThanOrEqualTo(2560));
      },
    );

    testWidgets('explicit three-column scaling stays inside the viewport', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final settings = getIt<Settings>();
      settings.fitMainListToWidth.value = true;
      settings.mainListColumns.value = 3;
      settings.userScalingMainList.value = 1.8;
      populateDenseBoard();

      await pumpWidget(tester);

      final scope = tester.widget<MainListLayoutScope>(
        find.byType(MainListLayoutScope),
      );
      expect(scope.layout.columnCount, 3);
      final initialColumnWidth = scope.layout.columnWidth;
      expect(initialColumnWidth * 3, lessThanOrEqualTo(2560));

      final frameworkErrors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = frameworkErrors.add;
      addTearDown(() => FlutterError.onError = originalOnError);

      settings.userScalingMainList.value = 3;
      await tester.pump();

      final scaledScope = tester.widget<MainListLayoutScope>(
        find.byType(MainListLayoutScope),
      );
      expect(scaledScope.layout.columnCount, 3);
      expect(scaledScope.layout.columnWidth, greaterThan(initialColumnWidth));
      expect(scaledScope.layout.columnWidth * 3, lessThanOrEqualTo(2560));
      final items = find.byType(MainListItem);
      for (var index = 0; index < items.evaluate().length; index++) {
        final bounds = tester.getRect(items.at(index));
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(2560));
      }
      expect(frameworkErrors, isEmpty);
    });

    testWidgets('three visible character columns have no horizontal gaps', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final settings = getIt<Settings>();
      settings.fitMainListToWidth.value = true;
      settings.mainListColumns.value = 3;
      settings.userScalingMainList.value = 1.8;
      AddCharacterCommand('Blinkblade', 'Frosthaven', null, 1).execute();
      AddCharacterCommand('Banner Spear', 'Frosthaven', null, 1).execute();
      AddCharacterCommand('Hatchet', 'Jaws of the Lion', null, 1).execute();

      await pumpWidget(tester);

      final itemRects = [
        for (var index = 0; index < 3; index++)
          tester.getRect(find.byType(MainListItem).at(index)),
      ]..sort((a, b) => a.left.compareTo(b.left));
      final barRects = [
        for (var index = 0; index < 3; index++)
          tester.getRect(
            find.byKey(const Key('character-status-hit-area')).at(index),
          ),
      ]..sort((a, b) => a.left.compareTo(b.left));

      for (var index = 0; index < 3; index++) {
        expect(barRects[index].left, closeTo(itemRects[index].left, 0.01));
        expect(barRects[index].right, closeTo(itemRects[index].right, 0.01));
        expect(itemRects[index].left, greaterThanOrEqualTo(0));
        expect(itemRects[index].right, lessThanOrEqualTo(2560));
      }
      expect(barRects[0].right, closeTo(barRects[1].left, 0.01));
      expect(barRects[1].right, closeTo(barRects[2].left, 0.01));
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
      FlutterError.onError = ignoreOverflowErrors(FlutterError.onError);

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
      FlutterError.onError = ignoreOverflowErrors(FlutterError.onError);
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
      FlutterError.onError = ignoreOverflowErrors(FlutterError.onError);
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
