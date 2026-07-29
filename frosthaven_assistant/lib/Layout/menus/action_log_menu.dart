import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Resource/ui_utils.dart';
import 'package:frosthaven_assistant/l10n/app_localizations.dart';

import '../../Resource/state/game_state.dart';
import '../../services/service_locator.dart';
import '../widgets/modal_background.dart';

/// Viewer for the most recent actions, newest first.
class ActionLogMenu extends StatelessWidget {
  static const double _kMenuWidth = 360.0;
  static const double _kMaxHeight = 420.0;
  static const int _kMaxEntries = 500;

  const ActionLogMenu({super.key, this.gameState});

  final GameState? gameState;

  /// Confirms, then rolls the game back so [targetIndex] is the most recent
  /// applied action, undoing the [count] actions after it. The history restore
  /// is applied once and the undone actions remain redoable.
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
    if (!gs.rollbackToHistoryIndex(targetIndex)) return;
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
          final appliedEntries = gs.historyEntries
              .where((entry) => entry.index <= index)
              .toList(growable: false);
          final start = appliedEntries.length > _kMaxEntries
              ? appliedEntries.length - _kMaxEntries
              : 0;
          final entries = appliedEntries.sublist(start).reversed.toList();

          return Padding(
            padding: EdgeInsets.all(14 * scale),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.actionLogTitle,
                    style: getTitleTextStyle(scale),
                    textAlign: TextAlign.center),
                if (entries.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2 * scale),
                    child: Text(l10n.actionLogRollbackHint,
                        style: getButtonTextStyle(scale)
                            .copyWith(color: Colors.white54),
                        textAlign: TextAlign.center),
                  ),
                SizedBox(height: 10 * scale),
                if (entries.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20 * scale),
                    child: Text(l10n.actionLogEmpty,
                        style: getButtonTextStyle(scale),
                        textAlign: TextAlign.center),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: _kMaxHeight * scale),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      itemBuilder: (context, rowIndex) {
                        final entry = entries[rowIndex];
                        final isCurrent = entry.index == index;
                        final count = index - entry.index;
                        return InkWell(
                          onTap: count <= 0 || !entry.canRestore
                              ? null
                              : () => _confirmRollback(
                                  context,
                                  gs,
                                  entry.index,
                                  count,
                                  entry.description,
                                  l10n,
                                ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 3 * scale),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 28 * scale,
                                  child: Text(
                                    '${entry.index + 1}.',
                                    style: getButtonTextStyle(scale)
                                        .copyWith(color: Colors.white54),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.description,
                                    style: getButtonTextStyle(scale).copyWith(
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
