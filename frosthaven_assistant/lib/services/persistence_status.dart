/// Observable state for a serialized persistence queue.
class PersistenceStatus {
  const PersistenceStatus({required this.writing, this.error, this.stackTrace});

  const PersistenceStatus.idle()
    : writing = false,
      error = null,
      stackTrace = null;

  final bool writing;
  final Object? error;
  final StackTrace? stackTrace;

  bool get hasError => error != null;
}
