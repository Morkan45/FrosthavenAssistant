import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Resource/scaling.dart';

import '../../Resource/settings.dart';
import '../../Resource/state/game_state.dart';
import '../../Resource/ui_utils.dart';
import '../../services/service_locator.dart';
import '../../l10n/app_localizations.dart';
import '../menus/note_row_menu.dart';

/// Renders a [NoteRow] as a row in the main list. When linked it takes a
/// gradient/border derived from its target row's colour (a framed look that
/// still reads as a distinct note) and an indent + connector; monster notes are
/// prefixed with the standee number (or "All"), while player notes just show
/// their text since the row is that one player. Unlinked notes use the note's
/// own colour. Tapping opens the editor. Uses onTap only so the hold-to-reorder
/// gesture is preserved.
class NoteRowWidget extends StatelessWidget {
  static const double _kHeight = 40.0;
  static const double _kMarginH = 3.2;
  static const double _kIndent = 24.0;
  static const double _kRadius = 6.0;
  // Base tones for monster targets, which have no per-figure colour.
  static const Color _kEnemyBase = Color(0xFF8E2A2A);
  static const Color _kAllyBase = Color(0xFF2A4A8E);

  const NoteRowWidget({
    super.key,
    required this.data,
    this.gameState,
    this.settings,
  });

  final NoteRow data;
  final GameState? gameState;
  final Settings? settings;

  GameState get _gameState => gameState ?? getIt<GameState>();

  /// The target row, or null when unlinked / target absent.
  ListItemData? _target(String linkedId) => linkedId.isEmpty
      ? null
      : _gameState.currentList.firstWhereOrNull((e) => e.id == linkedId);

  /// The un-lightened base colour a note derives from: the player's class
  /// colour, a red/blue base for enemy/ally monsters, or (unlinked) the note's
  /// own colour.
  Color _baseColor(String linkedId, int fallback) {
    final target = _target(linkedId);
    if (target is Character) return target.characterClass.color;
    if (target is Monster) return target.isAlly ? _kAllyBase : _kEnemyBase;
    return Color(fallback);
  }

  Color _lighten(Color base, double amount) =>
      Color.lerp(base, Colors.white, amount) ?? base;

  @override
  Widget build(BuildContext context) {
    final double scale = getScaleByReference(context);
    // The list lays each row out in a Wrap with unbounded width, so — like the
    // character/monster rows — the note row must set an explicit width rather
    // than rely on Expanded, which would otherwise fail to lay out.
    final double listWidth = getMainListWidth(context);
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openDialog(
        context,
        NoteRowMenu(note: data, gameState: gameState, settings: settings),
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: data.color,
        builder: (context, colorValue, child) {
          return ValueListenableBuilder<String>(
            valueListenable: data.linkedId,
            builder: (context, linkedId, child) {
              final bool linked = linkedId.isNotEmpty;
              final double leftMargin =
                  (_kMarginH + (linked ? _kIndent : 0)) * scale;
              final double rightMargin = _kMarginH * scale;
              final Color base = _baseColor(linkedId, colorValue);
              final Color top = _lighten(base, 0.60);
              final Color bottom = _lighten(base, 0.30);
              final bool targetIsMonster = _target(linkedId) is Monster;
              // Contrast against the darker (top) part of the gradient.
              final Color fg =
                  ThemeData.estimateBrightnessForColor(bottom) == Brightness.dark
                      ? Colors.white
                      : Colors.black87;
              final Color fgFaint = fg.withValues(alpha: 0.6);
              return Container(
                height: _kHeight * scale,
                width: listWidth - leftMargin - rightMargin,
                margin: EdgeInsets.only(
                  left: leftMargin,
                  right: rightMargin,
                  bottom: 1 * scale,
                ),
                padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                decoration: BoxDecoration(
                  // Inverted gradient (darker at top) echoes the figure rows'
                  // framed, shaded look while reading as a distinct note.
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bottom, top],
                  ),
                  borderRadius: BorderRadius.circular(_kRadius * scale),
                  border: Border.all(
                    color: base.withValues(alpha: 0.8),
                    width: 1.3 * scale,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 3),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      linked ? Icons.subdirectory_arrow_right : Icons.notes,
                      size: 16 * scale,
                      color: fgFaint,
                    ),
                    SizedBox(width: 6 * scale),
                    // Monster notes are prefixed with the standee number (or
                    // "All"); a player note needs no label since the row is that
                    // one player.
                    if (linked && targetIsMonster)
                      ValueListenableBuilder<int>(
                        valueListenable: data.standeeNr,
                        builder: (context, standeeNr, child) => Padding(
                          padding: EdgeInsets.only(right: 6 * scale),
                          child: Text(
                            standeeNr > 0 ? '$standeeNr:' : '${l10n.noteRowAll}:',
                            style: TextStyle(
                              color: fg,
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: data.text,
                        builder: (context, text, child) => Text(
                          text.isEmpty ? l10n.noteRowHint : text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: text.isEmpty ? fgFaint : fg,
                            fontSize: 12 * scale,
                            fontStyle:
                                text.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
