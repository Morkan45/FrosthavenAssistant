import 'dart:async';

import 'package:flutter/foundation.dart';

import 'persistence_status.dart';

/// Serializes asynchronous writes while retaining only the newest pending value.
class LatestValueQueue<T> {
  LatestValueQueue(this._write);

  final Future<void> Function(T value) _write;

  T? _pendingValue;
  bool _hasPendingValue = false;
  T? _latestValue;
  bool _hasLatestValue = false;
  bool _hasRetryValue = false;
  bool _isDraining = false;
  Completer<void>? _idleCompleter;
  Object? _lastError;
  StackTrace? _lastStackTrace;
  final ValueNotifier<PersistenceStatus> _status =
      ValueNotifier<PersistenceStatus>(const PersistenceStatus.idle());

  ValueListenable<PersistenceStatus> get status => _status;

  Future<void> schedule(T value) {
    _latestValue = value;
    _hasLatestValue = true;
    _pendingValue = value;
    _hasPendingValue = true;

    final idleCompleter = _idleCompleter ??= Completer<void>();
    if (!_isDraining) {
      _isDraining = true;
      _status.value = PersistenceStatus(
        writing: true,
        error: _lastError,
        stackTrace: _lastStackTrace,
      );
      unawaited(_drain());
      // Persistence is commonly scheduled from callbacks that cannot await. Keep
      // those calls from producing an uncaught asynchronous error; callers that
      // do await the returned future still observe the same failure.
      unawaited(
        idleCompleter.future.then<void>(
          (_) {},
          onError: (Object _, StackTrace stackTrace) {},
        ),
      );
    }
    return idleCompleter.future;
  }

  Future<void> flush() {
    final active = _idleCompleter;
    if (active != null) {
      return active.future;
    }
    if (_lastError != null) {
      return Future<void>.error(_lastError!, _lastStackTrace);
    }
    return Future<void>.value();
  }

  /// Retries the newest value whose write failed.
  ///
  /// If a newer value is already pending, that value remains authoritative.
  Future<void> retryLatest() {
    if (!_hasRetryValue || !_hasLatestValue) {
      return flush();
    }
    return schedule(_latestValue as T);
  }

  Future<void> _drain() async {
    Object? firstError;
    StackTrace? firstStackTrace;

    while (_hasPendingValue) {
      final value = _pendingValue as T;
      _pendingValue = null;
      _hasPendingValue = false;

      try {
        await _write(value);
        _hasRetryValue = false;
        _lastError = null;
        _lastStackTrace = null;
        _status.value = const PersistenceStatus(writing: true);
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
        _hasRetryValue = true;
        _lastError = error;
        _lastStackTrace = stackTrace;
        _status.value = PersistenceStatus(
          writing: true,
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    _isDraining = false;
    final idleCompleter = _idleCompleter;
    _idleCompleter = null;
    _status.value = PersistenceStatus(
      writing: false,
      error: _lastError,
      stackTrace: _lastStackTrace,
    );
    if (firstError == null) {
      idleCompleter?.complete();
    } else {
      idleCompleter?.completeError(firstError, firstStackTrace);
    }
  }
}
