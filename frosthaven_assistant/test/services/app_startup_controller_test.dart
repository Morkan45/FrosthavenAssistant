import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/services/app_startup_controller.dart';

void main() {
  test('retry after a saved-game failure does not load data twice', () async {
    var dataLoads = 0;
    var gameLoads = 0;
    var translations = 0;
    var reconnects = 0;
    var resetGames = 0;
    var gameFails = true;
    final controller = AppStartupController(
      loadData: () async => dataLoads++,
      initializeGame: () async {},
      loadGame: () async {
        gameLoads++;
        if (gameFails) throw const FormatException('bad game');
      },
      loadSettings: () async {},
      initializeSettingsRuntime: () async {},
      loadTranslations: () async => translations++,
      beginStartupConnection: () async => reconnects++,
      resetGame: () async => resetGames++,
      resetSettings: () async {},
    );

    await controller.start();
    expect(controller.value.phase, AppStartupPhase.recoverableError);
    expect(controller.value.failure, AppStartupFailure.gameSave);
    expect(dataLoads, 1);
    expect(translations, 0);
    expect(reconnects, 0);

    gameFails = false;
    await controller.retry();
    expect(controller.value.phase, AppStartupPhase.ready);
    expect(dataLoads, 1);
    expect(gameLoads, 2);
    expect(translations, 1);
    expect(reconnects, 1);
    expect(resetGames, 0);
  });

  test('reset only invokes the failed save reset before retrying', () async {
    var resetGames = 0;
    var resetSettings = 0;
    var failGame = true;
    final controller = AppStartupController(
      loadData: () async {},
      initializeGame: () async {},
      loadGame: () async {
        if (failGame) throw const FormatException();
      },
      loadSettings: () async {},
      initializeSettingsRuntime: () async {},
      loadTranslations: () async {},
      beginStartupConnection: () async {},
      resetGame: () async => resetGames++,
      resetSettings: () async => resetSettings++,
    );

    await controller.start();
    failGame = false;
    await controller.resetAndRetry();

    expect(controller.value.phase, AppStartupPhase.ready);
    expect(resetGames, 1);
    expect(resetSettings, 0);
  });

  test('asset failure offers retry but no destructive reset', () async {
    final controller = AppStartupController(
      loadData: () async => throw StateError('missing asset'),
      initializeGame: () async {},
      loadGame: () async {},
      loadSettings: () async {},
      initializeSettingsRuntime: () async {},
      loadTranslations: () async {},
      beginStartupConnection: () async {},
      resetGame: () async {},
      resetSettings: () async {},
    );

    await controller.start();
    expect(controller.value.failure, AppStartupFailure.other);
    expect(controller.value.canReset, isFalse);
  });

  test('settings reset is offered only for settings-read failures', () async {
    var resetSettings = 0;
    var settingsFail = true;
    final controller = AppStartupController(
      loadData: () async {},
      initializeGame: () async {},
      loadGame: () async {},
      loadSettings: () async {
        if (settingsFail) throw const FormatException('bad settings');
      },
      initializeSettingsRuntime: () async {},
      loadTranslations: () async {},
      beginStartupConnection: () async {},
      resetGame: () async {},
      resetSettings: () async => resetSettings++,
    );

    await controller.start();
    expect(controller.value.failure, AppStartupFailure.settings);

    settingsFail = false;
    await controller.resetAndRetry();
    expect(controller.value.phase, AppStartupPhase.ready);
    expect(resetSettings, 1);
  });

  test('runtime initialization failure cannot reset saved settings', () async {
    final controller = AppStartupController(
      loadData: () async {},
      initializeGame: () async {},
      loadGame: () async {},
      loadSettings: () async {},
      initializeSettingsRuntime: () async => throw StateError('window'),
      loadTranslations: () async {},
      beginStartupConnection: () async {},
      resetGame: () async {},
      resetSettings: () async {},
    );

    await controller.start();
    expect(controller.value.failure, AppStartupFailure.other);
    expect(controller.value.canReset, isFalse);
  });
}
