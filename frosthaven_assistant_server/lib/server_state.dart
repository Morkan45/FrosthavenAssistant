import 'dart:convert';

class ServerState {
  int commandIndex = -1;
  List<ServerSaveState> gameSaveStates = [ServerSaveState()];
  final List<Command?> commands = [];
  final List<String> commandDescriptions = [];

  static const String _noEventJson = '{"type":"none"}';

  String redoState() {
    if (commandIndex < commandDescriptions.length - 1) {
      commandIndex++;
      //gameSaveStates[commandIndex + 1].saveToDisk(this);
      //send last game state if connected
      print(
        'server sends, redo index: $commandIndex, description:${commandDescriptions[commandIndex]}',
      );
      return jsonEncode({
        'i': commandIndex,
        'd': commandDescriptions[commandIndex],
        'e': jsonDecode(_noEventJson),
        's': gameSaveStates[commandIndex + 1].getState(),
      });
    }
    return "";
  }

  String undoState() {
    if (commandIndex >= 0) {
      print(
        'server sends, undo index: $commandIndex, description:${commandDescriptions[commandIndex]}',
      );
      commandIndex--;
      return jsonEncode({
        'i': commandIndex,
        'd': commandIndex >= 0 ? commandDescriptions[commandIndex] : '',
        'e': jsonDecode(_noEventJson),
        's': gameSaveStates[commandIndex + 1].getState(),
      });
    }
    return "";
  }

  void resetState() {
    commandIndex = -1;
    commands.clear();
    commandDescriptions.clear();
    if (gameSaveStates.isNotEmpty) {
      gameSaveStates.removeRange(0, gameSaveStates.length - 1);
    }
  }

  void save(String data) {
    ServerSaveState state = ServerSaveState();
    state._savedState = data;
    //state.saveToDisk(this);
    gameSaveStates.add(state); //do this from action handler instead
  }

  void acceptUpdate(int index, String description, String data) {
    if (index < 0 || index > commandDescriptions.length) {
      throw RangeError.range(index, 0, commandDescriptions.length, 'index');
    }
    if (commandDescriptions.length > index) {
      commandDescriptions.removeRange(index, commandDescriptions.length);
    }
    commandDescriptions.add(description);
    if (gameSaveStates.length > index + 1) {
      gameSaveStates.removeRange(index + 1, gameSaveStates.length);
    }
    commandIndex = index;
    save(data);
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
