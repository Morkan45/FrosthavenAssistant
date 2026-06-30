import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Resource/ui_utils.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';

import '../../Resource/state/game_state.dart';
import '../../services/service_locator.dart';
import '../widgets/modal_background.dart';

/// Read-only viewer for the most recent actions. The action history is already
/// tracked for undo/redo: [GameState.commandDescriptions] holds the localized
/// description of each action (captured when it ran) and [GameState.commandIndex]
/// marks the current position. This lists the applied actions, newest first.
class ActionLogMenu extends StatelessWidget {
  static const double _kMenuWidth = 360.0;
  static const double _kMaxHeight = 420.0;
  static const int _kMaxEntries = 20;

  const ActionLogMenu({super.key, this.gameState});

  final GameState? gameState;

  /// Confirms, then rolls the game back so [targetIndex] is the most recent
  /// applied action, undoing the [count] actions after it. Uses the existing
  /// undo path (so it stays in sync with multiplayer); the undone actions
  /// remain redoable until a new action is taken.
  Future<void> _confirmRollback(BuildContext context, GameState gs,
      int targetIndex, int count, String description, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.actionLogRollbackTitle),
        content: Text(l10n.actionLogRollbackBody(description, count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionLogRollbackConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    for (int k = 0; k < count; k++) {
      gs.undo();
    }
    // Close the log so the rolled-back board is visible.
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final gs = gameState ?? getIt<GameState>();
    final double scale = getModalMenuScale(context);
    final l10n = AppLocalizations.of(context)!;

    return ModalBackground(
      width: _kMenuWidth * scale,
      child: ValueListenableBuilder<int>(
        valueListenable: gs.commandIndex,
        builder: (context, index, child) {
          final descriptions = gs.commandDescriptions;
          // Applied actions are indices 0..index (inclusive); index == -1 means
          // nothing has happened yet.
          final int appliedCount = min(index + 1, descriptions.length);
          final int start = max(0, appliedCount - _kMaxEntries);

          final rows = <Widget>[];
          // Newest first.
          for (int i = appliedCount - 1; i >= start; i--) {
            final bool isCurrent = i == appliedCount - 1;
            // Rolling back to the current (top) entry is a no-op.
            final int count = index - i;
            rows.add(InkWell(
              onTap: count <= 0
                  ? null
                  : () => _confirmRollback(
                      context, gs, i, count, descriptions[i], l10n),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 3 * scale),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28 * scale,
                      child: Text(
                        '${i + 1}.',
                        style: getButtonTextStyle(scale)
                            .copyWith(color: Colors.white54),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        descriptions[i],
                        style: getButtonTextStyle(scale).copyWith(
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
          }

          return Padding(
            padding: EdgeInsets.all(14 * scale),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.actionLogTitle,
                    style: getTitleTextStyle(scale),
                    textAlign: TextAlign.center),
                if (rows.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2 * scale),
                    child: Text(l10n.actionLogRollbackHint,
                        style: getButtonTextStyle(scale)
                            .copyWith(color: Colors.white54),
                        textAlign: TextAlign.center),
                  ),
                SizedBox(height: 10 * scale),
                if (rows.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20 * scale),
                    child: Text(l10n.actionLogEmpty,
                        style: getButtonTextStyle(scale),
                        textAlign: TextAlign.center),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: _kMaxHeight * scale),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: rows,
                      ),
                    ),
                  ),
                SizedBox(height: 8 * scale),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.close, style: getButtonTextStyle(scale)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
