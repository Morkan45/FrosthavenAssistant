import 'package:flutter/foundation.dart';

enum AppStartupPhase { loading, ready, recoverableError }

enum AppStartupFailure { gameSave, settings, other }

class AppStartupState {
  const AppStartupState._(this.phase, {this.failure, this.error});

  const AppStartupState.loading() : this._(AppStartupPhase.loading);

  const AppStartupState.ready() : this._(AppStartupPhase.ready);

  const AppStartupState.recoverableError({
    required AppStartupFailure failure,
    required Object error,
  }) : this._(AppStartupPhase.recoverableError, failure: failure, error: error);

  final AppStartupPhase phase;
  final AppStartupFailure? failure;
  final Object? error;

  bool get canReset =>
      failure == AppStartupFailure.gameSave ||
      failure == AppStartupFailure.settings;
}

/// Starts the app in ordered stages and remembers completed stages across a
/// recovery retry. In particular, assets are not loaded a second time after a
/// corrupt local save has been reset or becomes readable again.
class AppStartupController extends ValueNotifier<AppStartupState> {
  AppStartupController({
    required Future<void> Function() loadData,
    required Future<void> Function() initializeGame,
    required Future<void> Function() loadGame,
    required Future<void> Function() loadSettings,
    required Future<void> Function() initializeSettingsRuntime,
    required Future<void> Function() loadTranslations,
    required Future<void> Function() beginStartupConnection,
    required Future<void> Function() resetGame,
    required Future<void> Function() resetSettings,
  }) : _loadData = loadData,
       _initializeGame = initializeGame,
       _loadGame = loadGame,
       _loadSettings = loadSettings,
       _initializeSettingsRuntime = initializeSettingsRuntime,
       _loadTranslations = loadTranslations,
       _beginStartupConnection = beginStartupConnection,
       _resetGame = resetGame,
       _resetSettings = resetSettings,
       super(const AppStartupState.loading());

  final Future<void> Function() _loadData;
  final Future<void> Function() _initializeGame;
  final Future<void> Function() _loadGame;
  final Future<void> Function() _loadSettings;
  final Future<void> Function() _initializeSettingsRuntime;
  final Future<void> Function() _loadTranslations;
  final Future<void> Function() _beginStartupConnection;
  final Future<void> Function() _resetGame;
  final Future<void> Function() _resetSettings;

  bool _dataLoaded = false;
  bool _gameInitialized = false;
  bool _gameLoaded = false;
  bool _settingsLoaded = false;
  bool _settingsRuntimeInitialized = false;
  bool _translationsLoaded = false;
  bool _running = false;

  Future<void> start() => _run();

  Future<void> retry() => _run();

  Future<void> resetAndRetry() async {
    if (_running) return;
    final failure = value.failure;
    if (failure != AppStartupFailure.gameSave &&
        failure != AppStartupFailure.settings) {
      return;
    }
    _running = true;
    value = const AppStartupState.loading();
    try {
      if (failure == AppStartupFailure.gameSave) {
        await _resetGame();
        _gameLoaded = false;
      } else {
        await _resetSettings();
        _settingsLoaded = false;
        _translationsLoaded = false;
      }
    } catch (error) {
      _fail(failure!, error);
      return;
    } finally {
      _running = false;
    }
    await _run();
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    value = const AppStartupState.loading();
    try {
      if (!_dataLoaded) {
        await _loadData();
        _dataLoaded = true;
      }
      if (!_gameInitialized) {
        await _initializeGame();
        _gameInitialized = true;
      }
      if (!_gameLoaded) {
        try {
          await _loadGame();
          _gameLoaded = true;
        } catch (error) {
          _fail(AppStartupFailure.gameSave, error);
          return;
        }
      }
      if (!_settingsLoaded) {
        try {
          await _loadSettings();
          _settingsLoaded = true;
        } catch (error) {
          _fail(AppStartupFailure.settings, error);
          return;
        }
      }
      if (!_settingsRuntimeInitialized) {
        await _initializeSettingsRuntime();
        _settingsRuntimeInitialized = true;
      }
      if (!_translationsLoaded) {
        await _loadTranslations();
        _translationsLoaded = true;
      }
      await _beginStartupConnection();
      value = const AppStartupState.ready();
    } catch (error) {
      _fail(AppStartupFailure.other, error);
    } finally {
      _running = false;
    }
  }

  void _fail(AppStartupFailure failure, Object error) {
    value = AppStartupState.recoverableError(failure: failure, error: error);
  }
}
