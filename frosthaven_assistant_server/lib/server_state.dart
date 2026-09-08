import 'dart:convert';

class ServerState {
  ServerState({
    this.maxHistoryEntries = 100,
    this.maxHistoryBytes = 16 * 1024 * 1024,
  })  : assert(maxHistoryEntries > 0),
        assert(maxHistoryBytes > 0);

  final int maxHistoryEntries;
  final int maxHistoryBytes;
  int commandIndex = -1;
  int firstRetainedIndex = 0;
  List<ServerSaveState> gameSaveStates = [ServerSaveState()];
  final List<Command?> commands = [];
  final List<String> commandDescriptions = [];

  static const String _noEventJson = '{"type":"none"}';

  int get oldestRetainedStateIndex => firstRetainedIndex - 1;
  int get retainedHistoryBytes =>
      gameSaveStates.fold(
          0, (sum, state) => sum + utf8.encode(state.getState()).length) +
      commandDescriptions.fold(
          0, (sum, value) => sum + utf8.encode(value).length);

  String get currentState => _stateAt(commandIndex);

  String get currentDescription => _descriptionAt(commandIndex);

  String redoState() {
    final lastRetainedIndex =
        firstRetainedIndex + commandDescriptions.length - 1;
    if (commandIndex < lastRetainedIndex) {
      commandIndex++;
      //gameSaveStates[commandIndex + 1].saveToDisk(this);
      //send last game state if connected
      print(
        'server sends, redo index: $commandIndex, description:${_descriptionAt(commandIndex)}',
      );
      return jsonEncode({
        'i': commandIndex,
        'd': _descriptionAt(commandIndex),
        'e': jsonDecode(_noEventJson),
        's': _stateAt(commandIndex),
      });
    }
    return "";
  }

  String undoState() {
    if (commandIndex >= firstRetainedIndex) {
      print(
        'server sends, undo index: $commandIndex, description:${_descriptionAt(commandIndex)}',
      );
      commandIndex--;
      return jsonEncode({
        'i': commandIndex,
        'd': _descriptionAt(commandIndex),
        'e': jsonDecode(_noEventJson),
        's': _stateAt(commandIndex),
      });
    }
    return "";
  }

  String rollbackState(int targetIndex) {
    if (targetIndex < oldestRetainedStateIndex) {
      // The requested snapshot was evicted. Return the current authoritative
      // state so clients converge instead of silently accepting a stale index.
      return _stateEnvelope(commandIndex);
    }
    if (targetIndex >= commandIndex) {
      return "";
    }
    commandIndex = targetIndex;
    return _stateEnvelope(commandIndex);
  }

  void resetState() {
    commandIndex = -1;
    commands.clear();
    commandDescriptions.clear();
    firstRetainedIndex = 0;
    gameSaveStates = [ServerSaveState()];
  }

  void save(String data) {
    ServerSaveState state = ServerSaveState();
    state._savedState = data;
    //state.saveToDisk(this);
    gameSaveStates.add(state); //do this from action handler instead
  }

  void acceptUpdate(int index, String description, String data) {
    if (index != commandIndex + 1 || index < firstRetainedIndex) {
      throw RangeError('Expected update at ${commandIndex + 1}, got $index');
    }
    final localIndex = index - firstRetainedIndex;
    if (commandDescriptions.length > localIndex) {
      commandDescriptions.removeRange(localIndex, commandDescriptions.length);
    }
    commandDescriptions.add(description);
    if (gameSaveStates.length > localIndex + 1) {
      gameSaveStates.removeRange(localIndex + 1, gameSaveStates.length);
    }
    commandIndex = index;
    save(data);
    _evictOldestHistory();
  }

  String _descriptionAt(int absoluteIndex) {
    if (absoluteIndex < firstRetainedIndex) return '';
    final localIndex = absoluteIndex - firstRetainedIndex;
    return commandDescriptions[localIndex];
  }

  String _stateAt(int absoluteIndex) {
    final localIndex = absoluteIndex - oldestRetainedStateIndex;
    return gameSaveStates[localIndex].getState();
  }

  String _stateEnvelope(int absoluteIndex) => jsonEncode({
        'i': absoluteIndex,
        'd': _descriptionAt(absoluteIndex),
        'e': jsonDecode(_noEventJson),
        's': _stateAt(absoluteIndex),
      });

  void _evictOldestHistory() {
    while (commandDescriptions.length > 1 &&
        (commandDescriptions.length > maxHistoryEntries ||
            retainedHistoryBytes > maxHistoryBytes)) {
      commandDescriptions.removeAt(0);
      gameSaveStates.removeAt(0);
      firstRetainedIndex++;
    }
  }
}

class Command {}

class ServerSaveState {
  String _savedState = "";

  String getState() {
    return _savedState;
  }

  void loadFromData(String data, ServerState gameState) {
    //have to call after init or element state overridden
    _savedState = data;
  }

  void save(ServerState gameState) {
    _savedState = gameState.toString();
  }
}
