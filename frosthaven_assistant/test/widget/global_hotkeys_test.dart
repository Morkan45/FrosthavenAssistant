import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/global_hotkeys.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/draw_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_init_command.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/game_data.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore_for_file: no-magic-number

void main() {
  Future<void> resetGame() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    setupGetIt();
    getIt<GameState>().init();
    await getIt<GameData>().loadData('assets/testData/');
    await getIt<GameState>().load();
    getIt<GameState>().clearList();
    getIt<Settings>().noInit.value = false;
  }

  setUp(() async {
    await resetGame();
  });

  Future<void> pumpHotkeys(
    WidgetTester tester, {
    bool includeTextField = false,
    Widget? child,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobalHotkeys(
            child: Focus(
              autofocus: true,
              child:
                  child ??
                  Column(
                    children: [
                      if (includeTextField) const TextField(autofocus: true),
                      const SizedBox(height: 24, width: 24),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> sendCtrlShortcut(
    WidgetTester tester,
    LogicalKeyboardKey key,
  ) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(
      key,
      physicalKey: key == LogicalKeyboardKey.add
          ? PhysicalKeyboardKey.equal
          : null,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  Future<void> scrollWheel(WidgetTester tester, Offset delta) async {
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(find.byType(GlobalHotkeys)),
        scrollDelta: delta,
      ),
    );
    await tester.pump();
  }

  group('GlobalHotkeys', () {
    testWidgets('Ctrl zoom supports shifted plus, equals and the numpad', (
      tester,
    ) async {
      final settings = getIt<Settings>();
      await pumpHotkeys(tester);
      for (final key in [
        LogicalKeyboardKey.equal,
        LogicalKeyboardKey.add,
        LogicalKeyboardKey.numpadAdd,
      ]) {
        settings.userScalingMainList.value = 1;
        await sendCtrlShortcut(tester, key);
        expect(settings.userScalingMainList.value, 1.1);
      }
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.equal);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(settings.userScalingMainList.value, 1.2);
      for (final key in [
        LogicalKeyboardKey.minus,
        LogicalKeyboardKey.numpadSubtract,
      ]) {
        settings.userScalingMainList.value = 1;
        await sendCtrlShortcut(tester, key);
        expect(settings.userScalingMainList.value, 0.9);
      }
    });

    testWidgets('Ctrl zoom leaves focused text fields alone', (tester) async {
      await pumpHotkeys(tester, includeTextField: true);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await sendCtrlShortcut(tester, LogicalKeyboardKey.numpadAdd);
      await sendCtrlShortcut(tester, LogicalKeyboardKey.minus);
      expect(getIt<Settings>().userScalingMainList.value, 1);
    });

    testWidgets('ctrl z undoes and ctrl y redoes', (WidgetTester tester) async {
      final gameState = getIt<GameState>();
      gameState.action(
        AddCharacterCommand('Blinkblade', 'Frosthaven', 'Blinkblade', 1),
      );

      await pumpHotkeys(tester);
      expect(gameState.currentList, isNotEmpty);

      await sendCtrlShortcut(tester, LogicalKeyboardKey.keyZ);
      expect(gameState.currentList, isEmpty);

      await sendCtrlShortcut(tester, LogicalKeyboardKey.keyY);
      expect(gameState.currentList, isNotEmpty);
    });

    testWidgets('Alt+Z undoes a game action and Ctrl+Y can redo it', (
      tester,
    ) async {
      final gameState = getIt<GameState>();
      gameState.action(
        AddCharacterCommand('Blinkblade', 'Frosthaven', 'Blinkblade', 1),
      );
      await pumpHotkeys(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      expect(gameState.currentList, isEmpty);

      await sendCtrlShortcut(tester, LogicalKeyboardKey.keyY);
      expect(gameState.currentList, isNotEmpty);
    });

    testWidgets('Alt+Z leaves focused text input alone', (tester) async {
      final gameState = getIt<GameState>();
      gameState.action(
        AddCharacterCommand('Blinkblade', 'Frosthaven', 'Blinkblade', 1),
      );
      await pumpHotkeys(tester, includeTextField: true);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      final initialIndex = gameState.commandIndex.value;

      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      expect(gameState.commandIndex.value, initialIndex);
      expect(gameState.currentList, isNotEmpty);
    });

    testWidgets(
      'Ctrl+wheel zooms over a scrollable without scrolling or adding game actions',
      (tester) async {
        final settings = getIt<Settings>();
        final gameState = getIt<GameState>();
        final controller = ScrollController(initialScrollOffset: 200);
        addTearDown(controller.dispose);
        await pumpHotkeys(
          tester,
          child: SingleChildScrollView(
            controller: controller,
            child: const SizedBox(height: 2000, width: double.infinity),
          ),
        );
        final initialIndex = gameState.commandIndex.value;

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await scrollWheel(tester, const Offset(0, -120));
        expect(settings.userScalingMainList.value, 1.1);
        expect(controller.offset, 200);
        await scrollWheel(tester, const Offset(0, 120));
        expect(settings.userScalingMainList.value, 1);
        expect(controller.offset, 200);
        expect(gameState.commandIndex.value, initialIndex);

        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await scrollWheel(tester, const Offset(0, 120));
        expect(controller.offset, 320);
        expect(settings.userScalingMainList.value, 1);
      },
    );

    testWidgets('Ctrl+wheel respects zoom limits and saves the shared scale', (
      tester,
    ) async {
      final settings = getIt<Settings>();
      await pumpHotkeys(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
      settings.userScalingMainList.value = 3;
      await scrollWheel(tester, const Offset(0, -120));
      expect(settings.userScalingMainList.value, 3);
      settings.userScalingMainList.value = 0.2;
      await scrollWheel(tester, const Offset(0, 120));
      expect(settings.userScalingMainList.value, 0.2);
      await scrollWheel(tester, const Offset(0, -120));
      expect(settings.userScalingMainList.value, 0.3);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);

      await settings.flushPersistence();
      final restored = Settings();
      await restored.loadFromDisk(reconnectOnStartup: false);
      expect(restored.userScalingMainList.value, 0.3);
    });

    testWidgets(
      'Ctrl+horizontal wheel scrolls normally without changing zoom',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await pumpHotkeys(
          tester,
          child: SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: const SizedBox(width: 2000, height: 100),
          ),
        );
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await scrollWheel(tester, const Offset(120, 0));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        expect(controller.offset, 120);
        expect(getIt<Settings>().userScalingMainList.value, 1);
      },
    );

    testWidgets('holding Ctrl does not block child button clicks', (
      tester,
    ) async {
      var pressed = false;
      await pumpHotkeys(
        tester,
        child: Center(
          child: TextButton(
            onPressed: () => pressed = true,
            child: const Text('Test action'),
          ),
        ),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.byType(TextButton));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(pressed, isTrue);
      expect(getIt<Settings>().userScalingMainList.value, 1);
    });

    testWidgets('tab advances activation and shift tab undoes it', (
      WidgetTester tester,
    ) async {
      AddCharacterCommand(
        'Blinkblade',
        'Frosthaven',
        'Blinkblade',
        1,
      ).execute();
      AddCharacterCommand(
        'Banner Spear',
        'Frosthaven',
        'Banner Spear',
        1,
      ).execute();
      SetInitCommand('Blinkblade', 25, gameState: getIt<GameState>()).execute();
      SetInitCommand(
        'Banner Spear',
        30,
        gameState: getIt<GameState>(),
      ).execute();
      final gameState = getIt<GameState>();

      gameState.action(DrawCommand(gameState: getIt<GameState>()));
      await tester.pump(const Duration(milliseconds: 600));
      await pumpHotkeys(tester);

      expect(gameState.currentList.first.turnState.value, TurnsState.current);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(gameState.currentList.first.turnState.value, TurnsState.done);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(gameState.currentList.first.turnState.value, TurnsState.current);
    });

    testWidgets('space runs draw action', (WidgetTester tester) async {
      AddCharacterCommand(
        'Blinkblade',
        'Frosthaven',
        'Blinkblade',
        1,
      ).execute();
      SetInitCommand('Blinkblade', 25, gameState: getIt<GameState>()).execute();
      final gameState = getIt<GameState>();

      await pumpHotkeys(tester);
      expect(gameState.roundState.value, RoundState.chooseInitiative);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(gameState.roundState.value, RoundState.playTurns);
    });

    testWidgets('number keys toggle elements', (WidgetTester tester) async {
      final gameState = getIt<GameState>();

      await pumpHotkeys(tester);
      expect(gameState.elementState[Elements.fire], ElementState.inert);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pump();
      expect(gameState.elementState[Elements.fire], ElementState.full);

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pump();
      expect(gameState.elementState[Elements.fire], ElementState.inert);
    });

    testWidgets('shortcuts are ignored while text input is focused', (
      WidgetTester tester,
    ) async {
      AddCharacterCommand(
        'Blinkblade',
        'Frosthaven',
        'Blinkblade',
        1,
      ).execute();
      final gameState = getIt<GameState>();

      await pumpHotkeys(tester, includeTextField: true);
      expect(find.byType(TextField), findsOneWidget);

      await sendCtrlShortcut(tester, LogicalKeyboardKey.keyZ);

      expect(gameState.currentList, isNotEmpty);
    });
  });
}
