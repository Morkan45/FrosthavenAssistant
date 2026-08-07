import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Resource/commands/set_figure_note_command.dart';
import 'package:frosthaven_assistant/Resource/ui_utils.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';

import '../../Layout/widgets/modal_background.dart';
import '../../Resource/settings.dart';
import '../../Resource/state/game_state.dart';
import '../../services/service_locator.dart';

/// A small modal for editing the free-form note shown inline on a figure's row
/// (character or monster). The note is committed (via [SetFigureNoteCommand])
/// when the field loses focus or the dialog is dismissed, so it survives both
/// the Save button and a tap outside.
class SetFigureNoteMenu extends StatefulWidget {
  const SetFigureNoteMenu(
      {super.key, required this.figure, this.gameState, this.settings});

  final ListItemData figure;
  final GameState? gameState;
  final Settings? settings;

  @override
  SetFigureNoteMenuState createState() => SetFigureNoteMenuState();
}

class SetFigureNoteMenuState extends State<SetFigureNoteMenu> {
  static const double _kMenuWidth = 300.0;
  static const double _kMenuHeight = 200.0;
  static const int _kMaxNoteLength = 140;

  GameState get _gameState => widget.gameState ?? getIt<GameState>();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _lastCommitted = "";

  @override
  void initState() {
    super.initState();
    _lastCommitted = widget.figure.note.value;
    _controller.text = _lastCommitted;
    _focusNode.addListener(_focusNodeListener);
  }

  void _focusNodeListener() {
    if (!_focusNode.hasFocus) {
      _commit();
    }
  }

  /// Dispatches a command only when the text actually changed, so an unedited
  /// open/close doesn't pollute the undo history.
  void _commit() {
    final text = _controller.text.trim();
    if (text == _lastCommitted) return;
    _lastCommitted = text;
    _gameState.action(
        SetFigureNoteCommand(text, widget.figure.id, gameState: _gameState));
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusNodeListener);
    _commit();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double scale = getModalMenuScale(context);
    final l10n = AppLocalizations.of(context)!;

    return ModalBackground(
      width: _kMenuWidth * scale,
      height: _kMenuHeight * scale,
      child: Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.characterNoteTitle,
                style: getTitleTextStyle(scale),
                textAlign: TextAlign.center),
            SizedBox(height: 12 * scale),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              maxLength: _kMaxNoteLength,
              maxLines: 3,
              style: getTitleTextStyle(scale),
              decoration: InputDecoration(
                hintText: l10n.characterNoteHint,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                _commit();
                Navigator.of(context).pop();
              },
            ),
            SizedBox(height: 8 * scale),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _commit();
                  Navigator.of(context).pop();
                },
                child: Text(l10n.close, style: getButtonTextStyle(scale)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
