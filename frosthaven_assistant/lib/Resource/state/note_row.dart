part of 'game_state.dart';
// ignore_for_file: library_private_types_in_public_api

/// A free-form note that lives in the main list as its own row, styled like a
/// player/monster row but in a user-pickable colour.
///
/// A note can be unlinked (a free-floating row placed wherever the user drags
/// it) or linked to a figure (a character or monster row) by that figure's
/// [id]. When linked it is kept positioned directly beneath its target by
/// [GameState._reflowNoteRows]. For a monster target it may additionally be
/// pinned to a specific [standeeNr] to annotate one standee rather than the
/// whole group.
class NoteRow extends ListItemData {
  // Slate tone, clearly distinct from character/monster rows.
  static const int defaultColor = 0xFF4E5D6C;

  final _text = ValueNotifier<String>("");
  final _color = ValueNotifier<int>(defaultColor);
  // "" means unlinked.
  final _linkedId = ValueNotifier<String>("");
  // 0 means "whole group / not standee-specific".
  final _standeeNr = ValueNotifier<int>(0);

  ValueListenable<String> get text => _text;
  ValueListenable<int> get color => _color;
  ValueListenable<String> get linkedId => _linkedId;
  ValueListenable<int> get standeeNr => _standeeNr;

  bool get isLinked => _linkedId.value.isNotEmpty;

  NoteRow(String anId) {
    id = anId;
  }

  NoteRow.create(
    String anId, {
    String text = "",
    int color = defaultColor,
    String linkedId = "",
    int standeeNr = 0,
  }) {
    id = anId;
    _text.value = text;
    _color.value = color;
    _linkedId.value = linkedId;
    _standeeNr.value = standeeNr;
  }

  NoteRow.fromJson(Map<String, dynamic> json) {
    id = json['id'] as String;
    _applyJson(json);
  }

  /// Updates fields in-place (preserving object identity, so existing
  /// [ValueListenableBuilder] subscriptions keep working across network syncs).
  void updateFromJson(Map<String, dynamic> json) {
    _applyJson(json);
  }

  void _applyJson(Map<String, dynamic> json) {
    _text.value = json['text'] as String? ?? "";
    _color.value = json['color'] as int? ?? defaultColor;
    _linkedId.value = json['linkedId'] as String? ?? "";
    _standeeNr.value = json['standeeNr'] as int? ?? 0;
  }

  void setText(_StateModifier _, String value) {
    _text.value = value;
  }

  void setColor(_StateModifier _, int value) {
    _color.value = value;
  }

  /// Links the note to [linkedId] (a figure id; "" to unlink) and, for monster
  /// targets, an optional [standeeNr] (0 for the whole group).
  void setLink(_StateModifier _, String linkedId, int standeeNr) {
    _linkedId.value = linkedId;
    _standeeNr.value = linkedId.isEmpty ? 0 : standeeNr;
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        // Discriminator used by GameSaveState.load to rebuild the right type.
        'noteRow': true,
        'text': _text.value,
        'color': _color.value,
        'linkedId': _linkedId.value,
        'standeeNr': _standeeNr.value,
      };

  @override
  String toString() => json.encode(toJson());
}
