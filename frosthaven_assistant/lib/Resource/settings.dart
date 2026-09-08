import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:frosthaven_assistant/Resource/scaling.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../services/network/client.dart';
import '../services/network/network.dart';
import '../services/latest_value_queue.dart';
import '../services/persistence_status.dart';
import '../services/service_locator.dart';
import 'commands/load_character_save_command.dart';
import 'commands/load_save_command.dart';
import 'enums.dart';
import 'settings_codec.dart';

class Settings {
  static const double _kDesktopBarScale = 1.6;
  static const String _sharedPrefsKey = 'settingsState';

  Settings({Future<void> Function(String value)? writer}) {
    _defaultSnapshot = _snapshot();
    _saveQueue = LatestValueQueue<String>(writer ?? _writeToSharedPreferences);
  }

  final SettingsCodec _codec = const SettingsCodec();
  late final SettingsSnapshot _defaultSnapshot;
  late final LatestValueQueue<String> _saveQueue;
  bool _diskLoadFailed = false;

  ValueListenable<PersistenceStatus> get persistenceStatus => _saveQueue.status;
  Future<void> retryPersistence() =>
      _diskLoadFailed ? _loadFailure() : _saveQueue.retryLatest();
  Future<void> flushPersistence() =>
      _diskLoadFailed ? _loadFailure() : _saveQueue.flush();

  Future<void> _loadFailure() {
    final result = Future<void>.error(
      StateError('Unreadable settings must be reset before saving.'),
    );
    result.ignore();
    return result;
  }

  final userScalingMainList = ValueNotifier<double>(1.0);
  final fitMainListToWidth = ValueNotifier<bool>(false);
  final mainListColumns = ValueNotifier<int>(0);
  final userScalingBars = ValueNotifier<double>(
    (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
        ? _kDesktopBarScale
        : 1.0,
  );
  final userScalingMenus = ValueNotifier<double>(1.0);
  final fullScreen = ValueNotifier<bool>(true);
  final darkMode = ValueNotifier<bool>(false);
  final noInit = ValueNotifier<bool>(true);
  final noStandees = ValueNotifier<bool>(false);
  final randomStandees = ValueNotifier<bool>(false);
  final noCalculation = ValueNotifier<bool>(false);
  final expireConditions = ValueNotifier<bool>(true);
  final hideLootDeck = ValueNotifier<bool>(false);
  final shimmer = ValueNotifier<bool>(
    (Platform.isWindows || Platform.isLinux || Platform.isMacOS),
  );

  /// Opt-in display power saving, in escalating tiers. Defaults to
  /// [PowerMode.normal]: the higher tiers trade away polish or convenience, so
  /// they are the user's choice to make.
  ///
  /// Most of the codebase should not read this directly — use
  /// `reducePowerEnabled()` in `ui_utils.dart`, which asks the narrower
  /// question "may I degrade visual quality?".
  final powerMode = ValueNotifier<PowerMode>(PowerMode.normal);
  final showScenarioNames = ValueNotifier<bool>(true);
  final showCustomContent = ValueNotifier<bool>(true);
  final showSectionsInMainView = ValueNotifier<bool>(true);
  final showReminders = ValueNotifier<bool>(true);
  final autoAddStandees = ValueNotifier<bool>(true);
  final autoAddSpawns = ValueNotifier<bool>(true);
  final showAmdDeck = ValueNotifier<bool>(true);
  final showBattleGoalReminder = ValueNotifier<bool>(true);
  final fhHazTerrainCalcInOGGloom = ValueNotifier<bool>(true);
  final showCharacterAMD = ValueNotifier<bool>(true);
  final enableHeathWheel = ValueNotifier<bool>(true);

  //used for both initiative and search menus
  final softNumpadInput = ValueNotifier<bool>(false);

  final style = ValueNotifier<Style>(Style.original);
  final locale = ValueNotifier<String>('en');

  final saves = ValueNotifier<Map<String, String>>({});
  final characterSaves = ValueNotifier<Map<String, String>>({});

  //network
  final server = ValueNotifier<bool>(false); //not saving these
  final client = ValueNotifier<ClientState>(ClientState.disconnected);
  String lastKnownConnection = "192.168.1.???"; //only these
  String lastKnownPort = "4567";
  String lastKnownHostIP = "";

  bool connectClientOnStartup = false;
  Timer? _startupConnectTimer;

  Future<void> init({Network? network, bool reconnectOnStartup = true}) async {
    await loadFromDisk(reconnectOnStartup: reconnectOnStartup);
    setFullscreen(fullScreen.value);

    (network ?? getIt<Network>()).networkInfo.initNetworkInfo();
  }

  void loadSave(String saveName, {GameState? gameState}) {
    String? save = saves.value[saveName];
    if (save != null) {
      final gs = gameState ?? getIt<GameState>();
      gs.action(LoadSaveCommand(saveName, save, gameState: gs));
    }
  }

  void saveState(String saveName, {GameState? gameState}) {
    saves.value[saveName] = (gameState ?? getIt<GameState>()).toString();
    Map<String, String> newMap = {};
    for (String key in saves.value.keys) {
      newMap[key] = saves.value[key] ?? '';
    }
    saves.value = newMap;
    saveToDisk();
  }

  void deleteSave(String saveName) {
    saves.value.remove(saveName);
    Map<String, String> newMap = {};
    for (String key in saves.value.keys) {
      newMap[key] = saves.value[key] ?? '';
    }
    saves.value = newMap;
    saveToDisk();
  }

  void loadCharacterSave(String saveName, {GameState? gameState}) {
    String? save = characterSaves.value[saveName];
    if (save != null) {
      final gs = gameState ?? getIt<GameState>();
      gs.action(LoadCharacterSaveCommand(saveName, save, gameState: gs));
    }
  }

  void saveCharacterState(String saveName, Character character) {
    characterSaves.value['$saveName\n${character.id}'] = character.toSave();
    Map<String, String> newMap = {};
    for (String key in characterSaves.value.keys) {
      newMap[key] = characterSaves.value[key] ?? '';
    }
    characterSaves.value = newMap;
    saveToDisk();
  }

  void deleteCharacterSave(String saveId) {
    characterSaves.value.remove(saveId);
    Map<String, String> newMap = {};
    for (String key in characterSaves.value.keys) {
      newMap[key] = characterSaves.value[key] ?? '';
    }
    characterSaves.value = newMap;
    saveToDisk();
  }

  Future<void> setFullscreen(bool fullscreen) async {
    fullScreen.value = fullscreen;
    //to set fullscreen on pc - need to add exit button to quit //would be good to exit/enter mode with ctrl+enter
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      WidgetsFlutterBinding.ensureInitialized();
      windowManager.ensureInitialized();

      // Use it only after calling `hiddenWindowAtLaunch`
      await windowManager.waitUntilReadyToShow();
      // Hide window title bar
      if (fullscreen) {
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
        await windowManager.setFullScreen(true);
        await windowManager.center();
        await windowManager.show();
        await windowManager.setSkipTaskbar(false);
        await windowManager.setPosition(
          const Offset(0, 0),
        ); //weird this was needed
        await windowManager.show();
      } else {
        await windowManager.setTitleBarStyle(TitleBarStyle.normal);
        await windowManager.setFullScreen(false);
        await windowManager.center();
        await windowManager.show();
        await windowManager.setSkipTaskbar(false);
        await windowManager.focus();
        await windowManager.setAlwaysOnTop(false);
      }
    } else {
      //android:
      //to hide ui top and bottom on android
      SystemUiMode nonFullscreen = SystemUiMode.manual;
      if (fullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(
          nonFullscreen,
          overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
        );
      }
      //to fix issue with system bottom bar on top after keyboard shown on earlier os (24)
      SystemChrome.setSystemUIChangeCallback(
        (
          systemOverlaysAreVisible,
        ) => Future.delayed(const Duration(milliseconds: 1001), () {
          if (fullscreen) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            if (kDebugMode) {
              print("force fullscreen 1 sec");
            }
          } else {
            SystemChrome.setEnabledSystemUIMode(
              nonFullscreen,
              overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
            );
          }
          //in case the first went too early?
          Future.delayed(const Duration(milliseconds: 301), () {
            if (fullscreen) {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
              if (kDebugMode) {
                print("force fullscreen 1.3 sec");
              }
            } else {
              SystemChrome.setEnabledSystemUIMode(
                nonFullscreen,
                overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
              );
            }
          });
        }),
      );
    }
  }

  Future<void> saveToDisk() {
    if (_diskLoadFailed) return _loadFailure();
    final result = _saveQueue.schedule(toString());
    result.ignore();
    return result;
  }

  Future<void> loadFromDisk({
    Client? client,
    bool reconnectOnStartup = true,
  }) async {
    //have to call after init or element state overridden

    _startupConnectTimer?.cancel();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final state = prefs.getString(_sharedPrefsKey);
      if (state != null) {
        final snapshot = _codec.decode(state, defaults: _defaultSnapshot);
        _apply(snapshot);
      }
      _diskLoadFailed = false;
    } catch (_) {
      _diskLoadFailed = true;
      rethrow;
    }
    if (reconnectOnStartup) {
      startStartupConnection(client: client);
    }
  }

  /// Deletes settings only after an explicit recovery choice by the user.
  Future<void> resetSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.remove(_sharedPrefsKey)) {
      throw StateError('Unable to reset saved settings.');
    }
    _startupConnectTimer?.cancel();
    _apply(_defaultSnapshot);
    _diskLoadFailed = false;
  }

  /// Starts the delayed reconnect after startup has reached a ready state.
  void startStartupConnection({Client? client}) {
    if (!connectClientOnStartup) return;
    _startupConnectTimer?.cancel();
    _startupConnectTimer = Timer(const Duration(milliseconds: 2000), () {
      final reconnectClient = client ?? getIt<Client>();
      if (this.client.value == ClientState.disconnected &&
          !reconnectClient.hasActiveConnection) {
        this.client.value = ClientState.connecting;
        reconnectClient.connect(lastKnownConnection);
      }
    });
  }

  static Future<void> _writeToSharedPreferences(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(_sharedPrefsKey, value);
    if (!saved) {
      throw StateError('SharedPreferences rejected the settings write.');
    }
  }

  SettingsSnapshot _snapshot() => SettingsSnapshot({
    'userScalingMainList': userScalingMainList.value,
    'fitMainListToWidth': fitMainListToWidth.value,
    'mainListColumns': mainListColumns.value,
    'userScalingBars': userScalingBars.value,
    'userScalingMenus': userScalingMenus.value,
    'fullScreen': fullScreen.value,
    'softNumpadInput': softNumpadInput.value,
    'darkMode': darkMode.value,
    'noInit': noInit.value,
    'noStandees': noStandees.value,
    'randomStandees': randomStandees.value,
    'noCalculation': noCalculation.value,
    'expireConditions': expireConditions.value,
    'hideLootDeck': hideLootDeck.value,
    'style': style.value,
    'shimmer': shimmer.value,
    'powerMode': powerMode.value,
    'showScenarioNames': showScenarioNames.value,
    'showCustomContent': showCustomContent.value,
    'showSectionsInMainView': showSectionsInMainView.value,
    'showReminders': showReminders.value,
    'autoAddStandees': autoAddStandees.value,
    'autoAddSpawns': autoAddSpawns.value,
    'showAmdDeck': showAmdDeck.value,
    'showBattleGoalReminder': showBattleGoalReminder.value,
    'fhHazTerrainCalcInOGGloom': fhHazTerrainCalcInOGGloom.value,
    'showCharacterAMD': showCharacterAMD.value,
    'enableHeathWheel': enableHeathWheel.value,
    'locale': locale.value,
    'saves': Map<String, String>.of(saves.value),
    'characterSaves': Map<String, String>.of(characterSaves.value),
    'connectClientOnStartup': connectClientOnStartup,
    'lastKnownConnection': lastKnownConnection,
    'lastKnownPort': lastKnownPort,
    'lastKnownHostIP': lastKnownHostIP,
  });

  void _apply(SettingsSnapshot data) {
    userScalingMainList.value = data.value('userScalingMainList');
    fitMainListToWidth.value = data.value('fitMainListToWidth');
    mainListColumns.value = data.value('mainListColumns');
    userScalingBars.value = data.value('userScalingBars');
    userScalingMenus.value = data.value('userScalingMenus');
    fullScreen.value = data.value('fullScreen');
    softNumpadInput.value = data.value('softNumpadInput');
    darkMode.value = data.value('darkMode');
    noInit.value = data.value('noInit');
    noStandees.value = data.value('noStandees');
    randomStandees.value = data.value('randomStandees');
    noCalculation.value = data.value('noCalculation');
    expireConditions.value = data.value('expireConditions');
    hideLootDeck.value = data.value('hideLootDeck');
    style.value = data.value('style');
    shimmer.value = data.value('shimmer');
    powerMode.value = data.value('powerMode');
    showScenarioNames.value = data.value('showScenarioNames');
    showCustomContent.value = data.value('showCustomContent');
    showSectionsInMainView.value = data.value('showSectionsInMainView');
    showReminders.value = data.value('showReminders');
    autoAddStandees.value = data.value('autoAddStandees');
    autoAddSpawns.value = data.value('autoAddSpawns');
    showAmdDeck.value = data.value('showAmdDeck');
    showBattleGoalReminder.value = data.value('showBattleGoalReminder');
    fhHazTerrainCalcInOGGloom.value = data.value('fhHazTerrainCalcInOGGloom');
    showCharacterAMD.value = data.value('showCharacterAMD');
    enableHeathWheel.value = data.value('enableHeathWheel');
    locale.value = data.value('locale');
    saves.value = Map<String, String>.of(data.value('saves'));
    characterSaves.value = Map<String, String>.of(data.value('characterSaves'));
    connectClientOnStartup = data.value('connectClientOnStartup');
    lastKnownConnection = data.value('lastKnownConnection');
    lastKnownPort = data.value('lastKnownPort');
    lastKnownHostIP = data.value('lastKnownHostIP');
    setMaxWidth();
  }

  @override
  String toString() => jsonEncode({
    'userScalingMainList': userScalingMainList.value,
    'fitMainListToWidth': fitMainListToWidth.value,
    'mainListColumns': mainListColumns.value,
    'userScalingBars': userScalingBars.value,
    'userScalingMenus': userScalingMenus.value,
    'fullScreen': fullScreen.value,
    'softNumpadInput': softNumpadInput.value,
    'noInit': noInit.value,
    'noStandees': noStandees.value,
    'randomStandees': randomStandees.value,
    'noCalculation': noCalculation.value,
    'expireConditions': expireConditions.value,
    'hideLootDeck': hideLootDeck.value,
    'style': style.value.index,
    'darkMode': darkMode.value,
    'shimmer': shimmer.value,
    'powerMode': powerMode.value.index,
    'showScenarioNames': showScenarioNames.value,
    'showCustomContent': showCustomContent.value,
    'showSectionsInMainView': showSectionsInMainView.value,
    'showReminders': showReminders.value,
    'autoAddStandees': autoAddStandees.value,
    'autoAddSpawns': autoAddSpawns.value,
    'showAmdDeck': showAmdDeck.value,
    'showBattleGoalReminder': showBattleGoalReminder.value,
    'fhHazTerrainCalcInOGGloom': fhHazTerrainCalcInOGGloom.value,
    'showCharacterAMD': showCharacterAMD.value,
    'enableHeathWheel': enableHeathWheel.value,
    'locale': locale.value,
    'saves': saves.value,
    'characterSaves': characterSaves.value,
    'connectClientOnStartup': connectClientOnStartup,
    'lastKnownConnection': lastKnownConnection,
    'lastKnownPort': lastKnownPort,
    'lastKnownHostIP': lastKnownHostIP,
  });
}
