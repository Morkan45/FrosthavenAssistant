import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Layout/global_hotkeys.dart';
import 'package:frosthaven_assistant/Layout/theme.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/main_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'Layout/idle_dimmer.dart';
import 'Layout/startup_recovery_screen.dart';
import 'Resource/game_data.dart';
import 'Resource/theme_switcher.dart';
import 'l10n/app_localizations.dart';
import 'services/linux_font_loader.dart';
import 'services/app_startup_controller.dart';
import 'services/network/network.dart';
import 'services/translation_service.dart';

// SocketExceptions caused by normal TCP connection lifecycle events (client
// disconnects, network changes, timeouts). These are handled gracefully in
// the networking layer and should not consume the Sentry error quota.
const _benignSocketErrno = <int>{
  9, // EBADF          – bad file descriptor (socket already closed)
  32, // EPIPE          – broken pipe (client disconnected mid-write)
  54, // ECONNRESET     – connection reset by peer (macOS/iOS)
  60, // ETIMEDOUT      – operation timed out (macOS/iOS)
  64, // EHOSTDOWN      – host is down (macOS/BSD)
  103, // ECONNABORTED   – software caused connection abort (Android/Linux)
  104, // ECONNRESET     – connection reset by peer (Linux/Android)
  107, // ENOTCONN       – transport endpoint not connected
  110, // ETIMEDOUT      – operation timed out (Linux)
  113, // EHOSTUNREACH   – no route to host
  121, // ERROR_SEM_TIMEOUT – semaphore timeout (Windows)
  10053, // WSAECONNABORTED – connection aborted by local software (Windows)
  10054, // WSAECONNRESET  – connection forcibly closed by remote host (Windows)
};

bool _isBenignNetworkError(Object? error) {
  if (error is OSError) {
    return _benignSocketErrno.contains(error.errorCode);
  }
  if (error is SocketException) {
    final errno = error.osError?.errorCode;
    return errno != null && _benignSocketErrno.contains(errno);
  }
  return false;
}

const title = 'X-haven Assistant';
String appVersion = '';

void _enablePlatformOverrideForDesktop() {
  if (kDebugMode && !kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupGetIt();
  appVersion = (await PackageInfo.fromPlatform()).version;

  _enablePlatformOverrideForDesktop();
  //debugPrintRebuildDirtyWidgets = true;
  //debugProfileBuildsEnabled = true;
  //debugProfileLayoutsEnabled = true;
  //debugRepaintRainbowEnabled = true;

  const minScreenWidth = 400.0;
  const minScreenHeight = 600.0;

  await loadLinuxFonts();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    windowManager.setTitle(title);
    windowManager.setMinimumSize(const Size(minScreenWidth, minScreenHeight));
    windowManager.setResizable(true);
  }

  FlutterError.onError = (details) {
    if (kReleaseMode) {
      if (!_isBenignNetworkError(details.exception)) {
        Sentry.captureException(details.exception, stackTrace: details.stack);
      }
    } else {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kReleaseMode && !_isBenignNetworkError(error)) {
      Sentry.captureException(error, stackTrace: stack);
    }
    return true;
  };

  ErrorWidget.builder = (e) {
    if (kReleaseMode) {
      Sentry.captureException(e.exception, stackTrace: e.stack);
      return Container();
    }
    return ErrorWidget(e);
  };

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      // Sentry's own FlutterError/PlatformDispatcher integrations capture
      // events unconditionally, bypassing the filtering done in the
      // FlutterError.onError/PlatformDispatcher.instance.onError overrides
      // above. beforeSend is the one choke point all of those (plus the
      // explicit Sentry.captureException calls below) funnel through, so
      // it's the only place a filter reliably applies.
      options.beforeSend = (event, hint) async {
        if (_isBenignNetworkError(event.throwable)) {
          return null;
        }
        return event;
      };
    },
    appRunner: () =>
        runApp(ThemeSwitcherWidget(initialTheme: theme, child: const MyApp())),
  );
}

Locale _parseLocale(String code) {
  final parts = code.split('_');
  return parts.length == 2 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppStartupController _startup;

  @override
  void initState() {
    super.initState();
    _startup = AppStartupController(
      loadData: () => getIt<GameData>().loadData('assets/data/'),
      initializeGame: () async => getIt<GameState>().init(),
      loadGame: () => getIt<GameState>().load(),
      // Decode/read failures are the only startup failures which can offer a
      // settings reset. Platform effects run in the following, ordinary stage.
      loadSettings: () =>
          getIt<Settings>().loadFromDisk(reconnectOnStartup: false),
      initializeSettingsRuntime: () async {
        final settings = getIt<Settings>();
        await settings.setFullscreen(settings.fullScreen.value);
        // Address discovery includes an external lookup. It improves the
        // network settings UI, but an offline table must still be able to
        // start its local game.
        unawaited(
          getIt<Network>().networkInfo.initNetworkInfo().catchError(
            (Object error, StackTrace stackTrace) => debugPrint(
              'Network address refresh failed: $error\n$stackTrace',
            ),
          ),
        );
      },
      loadTranslations: () =>
          getIt<TranslationService>().load(getIt<Settings>().locale.value),
      // Settings defers this until the complete startup pipeline succeeds.
      beginStartupConnection: () async =>
          getIt<Settings>().startStartupConnection(),
      resetGame: () => getIt<GameState>().resetSavedGame(),
      resetSettings: () => getIt<Settings>().resetSavedSettings(),
    );
    unawaited(_start());
  }

  Future<void> _start() async {
    await _startup.start();
    if (_startup.value.phase == AppStartupPhase.ready) {
      loading.value = false;
    } else if (_startup.value.error != null) {
      Sentry.captureException(_startup.value.error);
      debugPrint('Init failed: ${_startup.value.error}');
    }
  }

  @override
  void dispose() {
    _startup.dispose();
    super.dispose();
  }

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    //debugInvertOversizedImages = true;

    return ValueListenableBuilder<String>(
      valueListenable: getIt<Settings>().locale,
      builder: (context, locale, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        debugShowMaterialGrid: false,
        checkerboardOffscreenLayers: false,
        showPerformanceOverlay: false,
        title: title,
        theme: ThemeSwitcher.of(context).themeData,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [
          Locale('en'),
          Locale('de'),
          Locale('fr'),
          Locale('es'),
          Locale('pl'),
          Locale('ko'),
          Locale('ru'),
          Locale('zh'),
          Locale('zh', 'Hant'),
          Locale('th'),
        ],
        locale: _parseLocale(locale),
        builder: (context, child) {
          if (child == null) {
            return const SizedBox.shrink();
          }
          return child;
        },
        home: ValueListenableBuilder<AppStartupState>(
          valueListenable: _startup,
          builder: (context, startup, _) {
            if (startup.phase == AppStartupPhase.ready) {
              return const IdleDimmer(
                child: GlobalHotkeys(child: MyHomePage(title: title)),
              );
            }
            if (startup.phase == AppStartupPhase.recoverableError) {
              return StartupRecoveryScreen(
                state: startup,
                onRetry: () async {
                  await _startup.retry();
                  if (_startup.value.phase == AppStartupPhase.ready) {
                    loading.value = false;
                  }
                },
                onReset: () async {
                  await _startup.resetAndRetry();
                  if (_startup.value.phase == AppStartupPhase.ready) {
                    loading.value = false;
                  }
                },
              );
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => MainState();
}
