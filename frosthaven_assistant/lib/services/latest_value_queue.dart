import 'dart:async';

/// Serializes asynchronous writes while retaining only the newest pending value.
class LatestValueQueue<T> {
  LatestValueQueue(this._write);

  final Future<void> Function(T value) _write;

  T? _pendingValue;
  bool _hasPendingValue = false;
  Future<void>? _drainFuture;
  Completer<void>? _idleCompleter;

  Future<void> schedule(T value) {
    _pendingValue = value;
    _hasPendingValue = true;

    final idleCompleter = _idleCompleter ??= Completer<void>();
    _drainFuture ??= _drain();
    return idleCompleter.future;
  }

  Future<void> flush() => _idleCompleter?.future ?? Future<void>.value();

  Future<void> _drain() async {
    Object? firstError;
    StackTrace? firstStackTrace;

    while (_hasPendingValue) {
      final value = _pendingValue as T;
      _pendingValue = null;
      _hasPendingValue = false;

      try {
        await _write(value);
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    _drainFuture = null;
    final idleCompleter = _idleCompleter;
    _idleCompleter = null;
    if (firstError == null) {
      idleCompleter?.complete();
    } else {
      idleCompleter?.completeError(firstError, firstStackTrace);
    }
  }
}
