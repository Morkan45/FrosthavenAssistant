import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/CharacterWidget/character_widget_internal.dart';
import 'package:frosthaven_assistant/Layout/main_scaffold.dart';
import 'package:frosthaven_assistant/Layout/theme.dart';
import 'package:frosthaven_assistant/Resource/commands/add_character_command.dart';
import 'package:frosthaven_assistant/Resource/commands/add_standee_command.dart';
import 'package:frosthaven_assistant/Resource/commands/change_stat_commands/change_health_command.dart';
import 'package:frosthaven_assistant/Resource/commands/draw_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_campaign_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_level_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_scenario_command.dart';
import 'package:frosthaven_assistant/Resource/game_data.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../test/command/test_helpers.dart';

// flutter test --update-goldens tool/objective_screenshot_test.dart
void main() {
  setUpAll(() async {
    await setUpGame();
    await getIt<GameData>().loadData('assets/data/');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
          (_) async => null,
        );
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('Ravens Roost objective controls and rejected condition hover', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = getIt<GameState>()..clearList();
    final settings = getIt<Settings>();
    settings.userScalingBars.value = 1;
    settings.userScalingMainList.value = 3;
    settings.shimmer.value = false;
    settings.fitMainListToWidth.value = true;
    settings.mainListColumns.value = 2;
    settings.enableHeathWheel.value = false;
    settings.style.value = Style.frosthaven;
    settings.autoAddStandees.value = false;
    settings.showBattleGoalReminder.value = false;
    settings.showCharacterAMD.value = false;
    loading.value = false;
    SetCampaignCommand('Frosthaven').execute();
    AddCharacterCommand('Blinkblade', 'Frosthaven', 'Hejsan', 8).execute();
    AddCharacterCommand('Banner Spear', 'Frosthaven', 'Lol', 8).execute();
    AddCharacterCommand('Drifter', 'Frosthaven', 'ew', 8).execute();
    SetLevelCommand(6, null).execute();
    SetScenarioCommand("#32 Raven's Roost", false, gameState: state).execute();
    SetScenarioCommand('#66.1(1)', true, gameState: state).execute();
    final objective = state.currentList.whereType<Character>().singleWhere(
      (item) => item.characterClass.id == 'Objective',
    );
    expect(objective.characterState.maxHealth.value, 72);
    ChangeHealthCommand(
      -3,
      objective.id,
      objective.id,
      gameState: state,
    ).execute();
    for (final nr in [2, 3, 5, 6]) {
      AddStandeeCommand(
        nr,
        null,
        'Frozen Corpse',
        MonsterType.normal,
        false,
        gameState: state,
      ).execute();
    }
    for (final nr in [1, 2, 3]) {
      AddStandeeCommand(
        nr,
        null,
        'Harrower Infester (FH)',
        nr == 1 ? MonsterType.normal : MonsterType.elite,
        false,
        gameState: state,
      ).execute();
    }
    DrawCommand(gameState: state).execute();

    await tester.pumpWidget(
      testApp(
        Theme(
          data: themeFH.copyWith(platform: TargetPlatform.windows),
          child: const MainScaffold(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).first);
    final images = <ImageProvider>[
      ...tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => image.image),
      for (final widget in tester.widgetList<DecoratedBox>(
        find.byType(DecoratedBox),
      ))
        if (widget.decoration case BoxDecoration(image: final image?))
          image.image,
    ];
    await tester.runAsync(
      () => Future.wait(images.map((image) => precacheImage(image, context))),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile(
        '../../artifacts/objective-controls-2026-10-25/desktop.png',
      ),
    );
    await expectLater(
      find.byWidgetPredicate(
        (widget) =>
            widget is CharacterWidgetInternal &&
            widget.characterId == objective.id,
      ),
      matchesGoldenFile(
        '../../artifacts/objective-controls-2026-10-25/objective-bar.png',
      ),
    );

    final source = find.byKey(const ValueKey('condition-source-poison'));
    final origin = tester.getCenter(source);
    final gesture = await tester.startGesture(
      origin,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(origin + const Offset(0, 24));
    await tester.pump();
    final target = find.byKey(
      ValueKey('condition-target-${objective.id}-${objective.id}'),
    );
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    expect(
      (tester.widget<DecoratedBox>(target).decoration as BoxDecoration)
          .border!
          .top
          .color,
      Colors.redAccent,
    );
    await expectLater(
      find.byType(Overlay).first,
      matchesGoldenFile(
        '../../artifacts/objective-controls-2026-10-25/immune-hover.png',
      ),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(objective.characterState.conditions.value, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
