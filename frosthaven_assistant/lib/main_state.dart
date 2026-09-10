import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/Resource/ui_utils.dart';
import 'package:frosthaven_assistant/services/android_foreground_service.dart';
import 'package:frosthaven_assistant/services/network/client.dart';
import 'package:frosthaven_assistant/services/network/network.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';
import 'package:frosthaven_assistant/services/desktop_close_controller.dart';
import 'package:window_manager/window_manager.dart';

import 'Layout/main_scaffold.dart';
import 'Model/campaign.dart';
import 'main.dart';

class DataLoadedNotification extends Notification {
  // ignore: prefer-match-file-name, companion type for MainState in same file
  final CampaignModel data;

  const DataLoadedNotification({required this.data});
}

class MainState extends State<MyHomePage>
    with WindowListener, WidgetsBindingObserver {
  late final Network _network;
  late final Settings _settings;
  late final Client _client;
  late final GameState _gameState;
  late final DesktopCloseController _desktopClose;
  bool _closeDialogOpen = false;

  @override
  void dispose() {
    _desktopClose.dispose();
    _settings.powerMode.removeListener(_applyWakelock);
    if (Platform.isAndroid) {
      _settings.server.removeListener(_onServerChanged);
    }
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      windowManager.removeListener(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Holds the screen awake unless the user has opted into reduce-power mode,
  /// in which case the normal system dim-then-sleep timer applies.
  ///
  /// Called on start, on resume, and whenever the setting changes, so toggling
  /// it takes effect without a restart.
  void _restoreBrightnessIfDimmed() {
    if (kIsWeb ||
        !(Platform.isAndroid ||
            Platform.isIOS ||
            Platform.isMacOS ||
            Platform.isWindows)) {
      return;
    }
    if (!isDimmed.value) return;
    ScreenBrightness.instance.resetApplicationScreenBrightness().ignore();
    isDimmed.value = false;
  }

  void _applyWakelock() {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    // Only the top tier releases the wakelock. `dimWhenIdle` deliberately keeps
    // holding it — dimming while staying awake is the whole point of that tier.
    if (_settings.powerMode.value == PowerMode.reducePower) {
      WakelockPlus.disable().ignore();
    } else {
      WakelockPlus.enable().ignore();
    }
  }

  void _onServerChanged() {
    if (_settings.server.value) {
      AndroidForegroundService.start();
    } else {
      AndroidForegroundService.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        //this happens all the time on pc, disable this for pc.
        _network.appInBackground = false;
        log("app in resumed");
        _applyWakelock();
        rebuildAllChildren(
          context,
        ); //might be a bit performance heavy, but ensures app state visually up to date with server.
        if (_network.clientDisconnectedWhileInBackground ||
            _settings.connectClientOnStartup) {
          log("client was in background so try reconnect");
          _network.clientDisconnectedWhileInBackground = false;
          if (_settings.client.value == ClientState.disconnected &&
              !_client.hasActiveConnection) {
            _settings.client.value = ClientState.connecting;
            _client.connect(_settings.lastKnownConnection);
          }
        }
        break;
      case AppLifecycleState.inactive: //goes background but still alive.
        //save client state. if somehow disconnected while in background (wifi strangled etc.), reconnect on resume
        log("app in inactive");
        _network.appInBackground = true;
        break;
      case AppLifecycleState.paused:
        log("app in paused");
        _requestBackgroundFlush();
        // Belt and braces: the brightness plugin resets on resign-active, but a
        // jetsam kill can skip that and UIScreen.brightness is the real system
        // slider — a leaked dim value would outlive the app.
        _restoreBrightnessIfDimmed();
        // Drop decoded images that nothing is currently displaying. Reduces the
        // chance iOS reclaims memory from a backgrounded app, which would force
        // a cold relaunch and a full asset re-decode.
        // Not clearLiveImages(): those are still referenced by the mounted
        // tree, so clearing them only forces a re-decode on resume.
        PaintingBinding.instance.imageCache.clear();
        break;
      case AppLifecycleState.detached:
        log("app in detached");
        //means shut down. save client state here. and try connect at startup if so.
        if (_settings.client.value == ClientState.connected) {
          log(
            "client was disconnected in background so try reconnect on restart",
          );
          _network.clientDisconnectedWhileInBackground = true;
          _settings.connectClientOnStartup = true;
          _network.appInBackground = true;
        }
        _requestBackgroundFlush();
        break;
      case AppLifecycleState.hidden:
        _requestBackgroundFlush();
        break;
    }
  }

  void rebuildAllChildren(BuildContext context) {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  void initState() {
    _network = getIt<Network>();
    _settings = getIt<Settings>();
    _client = getIt<Client>();
    _gameState = getIt<GameState>();
    _desktopClose = DesktopCloseController(
      flush: _saveAndFlushForClose,
      retryPersistence: _retryAllPersistence,
      destroy: windowManager.destroy,
    );
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (Platform.isAndroid) {
      _settings.server.addListener(_onServerChanged);
    }

    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      windowManager.addListener(this);
      unawaited(_preventUnflushedWindowClose());
    }

    _applyWakelock();
    _settings.powerMode.addListener(_applyWakelock);

    if (Platform.isAndroid || Platform.isIOS) {
      KeyboardVisibilityController().onChange.listen((bool visible) {
        if (kDebugMode) {
          print("keyboard visible $visible");
        }
        if (!visible && _settings.fullScreen.value) {
          _settings.setFullscreen(true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _gameState.persistenceStatus,
        _settings.persistenceStatus,
      ]),
      builder: (context, _) {
        final gameStatus = _gameState.persistenceStatus.value;
        final settingsStatus = _settings.persistenceStatus.value;
        final persistenceError = gameStatus.hasError || settingsStatus.hasError;
        return SafeArea(
          child: Material(
            child: Column(
              children: [
                if (persistenceError)
                  MaterialBanner(
                    content: const Text('Changes could not be saved.'),
                    actions: [
                      TextButton(
                        onPressed: () => unawaited(_retryPersistence()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                const Expanded(child: MainScaffold()),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _flushPersistence() async {
    await Future.wait([
      _gameState.flushPersistence(),
      _settings.flushPersistence(),
    ]);
  }

  Future<void> _saveAndFlushForClose() =>
      Future.wait([_gameState.saveAndFlush(), _settings.saveToDisk()]);

  Future<void> _retryPersistence() async {
    try {
      await _retryAllPersistence();
    } catch (error, stackTrace) {
      debugPrint('Persistence retry failed: $error\n$stackTrace');
    }
  }

  Future<void> _retryAllPersistence() => Future.wait([
    _gameState.retryPersistence(),
    _settings.retryPersistence(),
  ]);

  void _requestBackgroundFlush() {
    unawaited(
      _flushPersistence().catchError((Object error, StackTrace stackTrace) {
        debugPrint('Background persistence failed: $error\n$stackTrace');
      }),
    );
  }

  Future<void> _preventUnflushedWindowClose() async {
    try {
      await windowManager.setPreventClose(true);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to configure window-close persistence: $error');
      }
    }
  }

  @override
  void onWindowClose() async {
    if (_closeDialogOpen) return;
    final closed = await _desktopClose.requestClose();
    if (closed || !mounted || _desktopClose.value != DesktopCloseState.failed) {
      return;
    }
    _closeDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Changes could not be saved'),
        content: const Text(
          'Retry saving before closing, or close anyway. Closing anyway may lose recent changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final saved = await _desktopClose.retryAndClose();
              if (saved && dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () async {
              await _desktopClose.closeAnyway();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Close anyway'),
          ),
        ],
      ),
    );
    _closeDialogOpen = false;
  }

  @override
  void onWindowFocus() {
    setState(() {});
  }
}
