part of 'game_state.dart';

// ignore_for_file: library_private_types_in_public_api
class ListItemData {
  String id = '';
  final _turnState = ValueNotifier<TurnsState>(TurnsState.notDone);
  ValueListenable<TurnsState> get turnState => _turnState;

  // Free-form inline note shown on the row. Shared by characters and monsters.
  final _note = ValueNotifier<String>("");
  ValueListenable<String> get note => _note;

  void setTurnState(_StateModifier _, TurnsState value) {
    _turnState.value = value;
  }

  void setNote(_StateModifier _, String value) {
    _note.value = value;
  }

  Map<String, dynamic> toJson() => {};
}
