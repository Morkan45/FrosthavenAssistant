import 'package:flutter/foundation.dart';

enum DesktopCloseState { idle, saving, failed, closed }

/// Keeps the window-close decision independent from window_manager so its
/// failure and retry behaviour can be tested without a desktop plugin.
class DesktopCloseController extends ValueNotifier<DesktopCloseState> {
  DesktopCloseController({
    required Future<void> Function() flush,
    required Future<void> Function() retryPersistence,
    required Future<void> Function() destroy,
  }) : _flush = flush,
       _retryPersistence = retryPersistence,
       _destroy = destroy,
       super(DesktopCloseState.idle);

  final Future<void> Function() _flush;
  final Future<void> Function() _retryPersistence;
  final Future<void> Function() _destroy;
  bool _working = false;
  Object? error;

  Future<bool> requestClose() => _saveThenClose(retry: false);

  Future<bool> retryAndClose() => _saveThenClose(retry: true);

  Future<void> closeAnyway() async {
    if (_working || value == DesktopCloseState.closed) return;
    _working = true;
    try {
      await _destroy();
      value = DesktopCloseState.closed;
    } finally {
      _working = false;
    }
  }

  Future<bool> _saveThenClose({required bool retry}) async {
    if (_working || value == DesktopCloseState.closed) return false;
    _working = true;
    value = DesktopCloseState.saving;
    error = null;
    try {
      if (retry) await _retryPersistence();
      await _flush();
      await _destroy();
      value = DesktopCloseState.closed;
      return true;
    } catch (caught) {
      error = caught;
      value = DesktopCloseState.failed;
      return false;
    } finally {
      _working = false;
    }
  }
}
