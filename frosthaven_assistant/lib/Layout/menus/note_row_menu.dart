import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Resource/commands/add_note_row_command.dart';
import 'package:frosthaven_assistant/Resource/commands/remove_note_row_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_note_row_color_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_note_row_link_command.dart';
import 'package:frosthaven_assistant/Resource/commands/set_note_row_text_command.dart';
import 'package:frosthaven_assistant/Resource/ui_utils.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';

import '../../Resource/settings.dart';
import '../../Resource/state/game_state.dart';
import '../../services/service_locator.dart';
import '../widgets/modal_background.dart';

/// Editor for a [NoteRow], used both to create a new note (when [note] is null)
/// and to edit an existing one. In create mode all edits accumulate locally and
/// are committed by the Add button; in edit mode colour/link changes commit
/// immediately and the text commits on close.
class NoteRowMenu extends StatefulWidget {
  const NoteRowMenu({
    super.key,
    this.note,
    this.presetLinkId = "",
    this.presetStandeeNr = 0,
    this.gameState,
    this.settings,
  });

  /// Existing note to edit; null to create a new one.
  final NoteRow? note;

  /// For create mode: pre-select a link target (used when adding from a
  /// figure's status menu).
  final String presetLinkId;
  final int presetStandeeNr;

  final GameState? gameState;
  final Settings? settings;

  @override
  NoteRowMenuState createState() => NoteRowMenuState();
}

class NoteRowMenuState extends State<NoteRowMenu> {
  static const double _kMenuWidth = 340.0;
  static const int _kMaxNoteLength = 300;
  static const List<int> _kPalette = [
    0xFF4E5D6C, // slate
    0xFF6D4C41, // brown
    0xFF37474F, // blue grey
    0xFF5D4037, // dark brown
    0xFF455A64, // steel
    0xFF6A1B9A, // purple
    0xFFAD1457, // pink
    0xFFC62828, // red
    0xFFE65100, // orange
    0xFF2E7D32, // green
    0xFF1565C0, // blue
    0xFF00838F, // teal
  ];

  GameState get _gameState => widget.gameState ?? getIt<GameState>();
  Settings get _settings => widget.settings ?? getIt<Settings>();

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _color = NoteRow.defaultColor;
  String _linkedId = "";
  int _standeeNr = 0;
  String _lastCommittedText = "";

  bool get _isEdit => widget.note != null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    if (note != null) {
      _controller.text = note.text.value;
      _color = note.color.value;
      _linkedId = note.linkedId.value;
      _standeeNr = note.standeeNr.value;
      _focusNode.addListener(_commitTextOnBlur);
    } else {
      _color = NoteRow.defaultColor;
      _linkedId = widget.presetLinkId;
      _standeeNr = widget.presetStandeeNr;
    }
    _lastCommittedText = _controller.text;
  }

  void _commitTextOnBlur() {
    if (!_focusNode.hasFocus) _commitText();
  }

  void _commitText() {
    final note = widget.note;
    if (note == null) return;
    final text = _controller.text.trim();
    if (text == _lastCommittedText) return;
    _lastCommittedText = text;
    _gameState
        .action(SetNoteRowTextCommand(text, note.id, gameState: _gameState));
  }

  void _onColorPicked(int color) {
    setState(() => _color = color);
    final note = widget.note;
    if (note != null) {
      _gameState.action(
          SetNoteRowColorCommand(color, note.id, gameState: _gameState));
    }
  }

  void _onLinkChanged(String linkedId, int standeeNr) {
    setState(() {
      _linkedId = linkedId;
      _standeeNr = linkedId.isEmpty ? 0 : standeeNr;
    });
    final note = widget.note;
    if (note != null) {
      _gameState.action(SetNoteRowLinkCommand(note.id, _linkedId, _standeeNr,
          gameState: _gameState));
    }
  }

  void _onAdd() {
    final id = 'note_${DateTime.now().microsecondsSinceEpoch}';
    _gameState.action(AddNoteRowCommand(
      NoteRow.create(id,
          text: _controller.text.trim(),
          color: _color,
          linkedId: _linkedId,
          standeeNr: _standeeNr),
      gameState: _gameState,
    ));
    Navigator.of(context).pop();
  }

  void _onDelete() {
    final note = widget.note;
    if (note != null) {
      _gameState.action(RemoveNoteRowCommand(note.id, gameState: _gameState));
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_commitTextOnBlur);
    _commitText();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _targetItems(AppLocalizations l10n) {
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: "", child: Text(l10n.noteRowConnectNone)),
    ];
    for (final item in _gameState.currentList) {
      if (item is Character) {
        final display = item.characterState.display.value;
        final name = display.isNotEmpty ? display : item.id;
        items.add(DropdownMenuItem(
            value: item.id, child: Text('${l10n.noteRowConnectPlayer}: $name')));
      } else if (item is Monster) {
        items.add(DropdownMenuItem(
            value: item.id,
            child: Text('${l10n.noteRowConnectMonster}: ${item.id}')));
      }
    }
    return items;
  }

  /// Standee selector items for the currently linked monster (empty if the
  /// target is not a monster or has no standees).
  List<DropdownMenuItem<int>> _standeeItems(AppLocalizations l10n) {
    final target = _gameState.currentList
        .where((e) => e.id == _linkedId)
        .whereType<Monster>()
        .firstOrNull;
    if (target == null) return const [];
    final items = <DropdownMenuItem<int>>[
      DropdownMenuItem(value: 0, child: Text(l10n.noteRowWholeGroup)),
    ];
    for (final instance in target.monsterInstances) {
      items.add(DropdownMenuItem(
          value: instance.standeeNr,
          child: Text(l10n.noteRowStandeeNr(instance.standeeNr))));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final double scale = getModalMenuScale(context);
    final l10n = AppLocalizations.of(context)!;
    final standeeItems = _standeeItems(l10n);
    // Dropdown children are plain Text, so without an explicit style they fall
    // back to the theme's default (black) — unreadable on the dark modal. Match
    // the surrounding labels and the modal background so both the collapsed
    // value and the opened menu are legible in light and dark mode.
    final TextStyle dropdownTextStyle = getButtonTextStyle(scale);
    final Color dropdownColor =
        _settings.darkMode.value ? const Color(0xFF202020) : Colors.white;

    return ModalBackground(
      width: _kMenuWidth * scale,
      child: Padding(
        padding: EdgeInsets.all(14 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.noteRowTitle,
                style: getTitleTextStyle(scale), textAlign: TextAlign.center),
            SizedBox(height: 10 * scale),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLength: _kMaxNoteLength,
              maxLines: 3,
              style: getButtonTextStyle(scale),
              decoration: InputDecoration(
                hintText: l10n.noteRowHint,
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(l10n.noteRowColourLabel, style: getButtonTextStyle(scale)),
            SizedBox(height: 4 * scale),
            Wrap(
              spacing: 6 * scale,
              runSpacing: 6 * scale,
              children: _kPalette.map((c) {
                final selected = c == _color;
                return GestureDetector(
                  onTap: () => _onColorPicked(c),
                  child: Container(
                    width: 26 * scale,
                    height: 26 * scale,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.white : Colors.black26,
                        width: selected ? 3 * scale : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10 * scale),
            Text(l10n.noteRowConnectLabel, style: getButtonTextStyle(scale)),
            DropdownButton<String>(
              isExpanded: true,
              value: _linkedId,
              style: dropdownTextStyle,
              dropdownColor: dropdownColor,
              iconEnabledColor: dropdownTextStyle.color,
              items: _targetItems(l10n),
              onChanged: (value) => _onLinkChanged(value ?? "", 0),
            ),
            if (standeeItems.isNotEmpty)
              DropdownButton<int>(
                isExpanded: true,
                value: standeeItems.any((e) => e.value == _standeeNr)
                    ? _standeeNr
                    : 0,
                style: dropdownTextStyle,
                dropdownColor: dropdownColor,
                iconEnabledColor: dropdownTextStyle.color,
                items: standeeItems,
                onChanged: (value) => _onLinkChanged(_linkedId, value ?? 0),
              ),
            SizedBox(height: 12 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isEdit)
                  TextButton(
                    onPressed: _onDelete,
                    child: Text(l10n.noteRowDelete,
                        style: getButtonTextStyle(scale)
                            .copyWith(color: Colors.redAccent)),
                  )
                else
                  const SizedBox.shrink(),
                TextButton(
                  onPressed: _isEdit
                      ? () {
                          _commitText();
                          Navigator.of(context).pop();
                        }
                      : _onAdd,
                  child: Text(_isEdit ? l10n.close : l10n.noteRowAddFromMenu,
                      style: getButtonTextStyle(scale)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
