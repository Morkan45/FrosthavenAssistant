import 'state/game_state.dart';

class HistoryEntry {
  HistoryEntry({
    required this.index,
    required String description,
    required this.timestamp,
    Command? command,
    GameSaveState? snapshot,
  }) : _description = description,
       _command = command,
       _snapshot = snapshot;

  final int index;
  final DateTime timestamp;
  String _description;
  Command? _command;
  GameSaveState? _snapshot;

  String get description => _description;
  Command? get command => _command;
  GameSaveState? get snapshot => _snapshot;
  bool get canRestore => _snapshot != null;
}

class ActionHistory {
  ActionHistory({this.maxEntries = 500, this.maxSnapshots = 251})
    : assert(maxEntries > 0),
      assert(maxSnapshots > 0);

  final int maxEntries;
  final int maxSnapshots;
  final List<HistoryEntry> _entries = [];
  GameSaveState? _baselineSnapshot;

  List<HistoryEntry> get entries => List.unmodifiable(_entries);
  int get length => _entries.length;
  int? get firstIndex => _entries.isEmpty ? null : _entries.first.index;
  int? get lastIndex => _entries.isEmpty ? null : _entries.last.index;

  int get retainedSnapshotCount =>
      (_baselineSnapshot == null ? 0 : 1) +
      _entries.where((entry) => entry.snapshot != null).length;

  HistoryEntry? entryAt(int index) {
    if (_entries.isEmpty) return null;
    final offset = index - _entries.first.index;
    if (offset < 0 || offset >= _entries.length) return null;
    final entry = _entries[offset];
    return entry.index == index ? entry : null;
  }

  Command? commandAt(int index) => entryAt(index)?.command;
  String? descriptionAt(int index) => entryAt(index)?.description;

  GameSaveState? snapshotAt(int index) =>
      index == -1 ? _baselineSnapshot : entryAt(index)?.snapshot;

  GameSaveState? latestSnapshotAtOrBefore(int index) {
    if (index == -1) return _baselineSnapshot;
    for (final entry in _entries.reversed) {
      if (entry.index <= index && entry.snapshot != null) {
        return entry.snapshot;
      }
    }
    return _baselineSnapshot;
  }

  void reset(GameSaveState? baseline) {
    _entries.clear();
    _baselineSnapshot = baseline;
  }

  void clearCommands() {
    for (final entry in _entries) {
      entry._command = null;
    }
  }

  void append({
    required int index,
    required String description,
    Command? command,
  }) {
    _truncateFrom(index);
    final expectedIndex = _entries.isEmpty ? index : _entries.last.index + 1;
    if (index != expectedIndex) {
      throw StateError(
        'History index $index is not contiguous with $expectedIndex',
      );
    }
    _entries.add(
      HistoryEntry(
        index: index,
        description: description,
        timestamp: DateTime.now(),
        command: command,
      ),
    );
    _enforceEntryLimit();
  }

  void synchronizeDescription(int index, String description) {
    if (index < 0) return;
    final existing = entryAt(index);
    if (existing != null) {
      existing._description = description;
      return;
    }

    if (_entries.isNotEmpty && index != _entries.last.index + 1) {
      _entries.clear();
    }
    append(index: index, description: description);
  }

  void attachSnapshot(int index, GameSaveState snapshot) {
    if (index == -1) {
      _baselineSnapshot = snapshot;
    } else {
      final entry = entryAt(index);
      if (entry != null) {
        entry._snapshot = snapshot;
      } else if (_entries.isEmpty || index == _entries.last.index + 1) {
        _entries.add(
          HistoryEntry(
            index: index,
            description: '',
            timestamp: DateTime.now(),
            snapshot: snapshot,
          ),
        );
        _enforceEntryLimit();
      }
    }
    _enforceSnapshotLimit();
  }

  /// Discards a rejected local future while retaining the corrected state.
  void discardAfter(int index) => _truncateFrom(index + 1);

  void _truncateFrom(int index) {
    final firstToRemove = _entries.indexWhere((entry) => entry.index >= index);
    if (firstToRemove >= 0) {
      _entries.removeRange(firstToRemove, _entries.length);
    }
  }

  void _enforceEntryLimit() {
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
  }

  void _enforceSnapshotLimit() {
    var excess = retainedSnapshotCount - maxSnapshots;
    if (excess <= 0) return;
    if (_baselineSnapshot != null) {
      _baselineSnapshot = null;
      excess--;
    }
    for (final entry in _entries) {
      if (excess <= 0) break;
      if (entry._snapshot != null) {
        entry._snapshot = null;
        entry._command = null;
        excess--;
      }
    }
  }
}
