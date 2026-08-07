import 'package:flutter/material.dart';

import '../../Resource/settings.dart';
import '../../Resource/state/game_state.dart';
import '../../Resource/ui_utils.dart';
import '../menus/set_figure_note_menu.dart';

/// Inline, truncated note snippet shown on a figure's row (character or
/// monster). Blends into the row as white, shadowed italic text; renders
/// nothing when the note is empty (a note can still be added via the status
/// menu). Tapping opens the editor. Uses onTap only so the hold-to-reorder
/// gesture is preserved.
///
/// All sizing is expressed relative to [scale] so it tracks the current board
/// size/zoom setting like the rest of the row.
class FigureNoteWidget extends StatelessWidget {
  static const double _kFontSize = 11.0;

  const FigureNoteWidget({
    super.key,
    required this.figure,
    required this.scale,
    this.maxLines = 2,
    this.gameState,
    this.settings,
  });

  final ListItemData figure;
  final double scale;
  final int maxLines;
  final GameState? gameState;
  final Settings? settings;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: figure.note,
      builder: (context, note, child) {
        if (note.isEmpty) return const SizedBox.shrink();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => openDialog(
            context,
            SetFigureNoteMenu(
              figure: figure,
              gameState: gameState,
              settings: settings,
            ),
          ),
          child: Text(
            note,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: _kFontSize * scale,
              fontStyle: FontStyle.italic,
              shadows: [textShadow(scale)],
            ),
          ),
        );
      },
    );
  }
}
