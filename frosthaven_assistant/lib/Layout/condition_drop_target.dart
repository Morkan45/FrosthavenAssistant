import 'package:flutter/material.dart';

import '../Resource/enums.dart';
import 'desktop_condition_scope.dart';

class ConditionDropTarget extends StatelessWidget {
  const ConditionDropTarget({
    super.key,
    required this.figureId,
    required this.ownerId,
    required this.child,
    this.enabled = true,
  });

  final String figureId;
  final String? ownerId;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final controls = DesktopConditionScope.maybeOf(context);
    if (controls == null || !enabled) return child;

    return DragTarget<Condition>(
      onWillAcceptWithDetails: (details) =>
          controls.canApply(details.data, figureId, ownerId),
      onAcceptWithDetails: (details) =>
          controls.acceptDrop(details.data, figureId, ownerId),
      onMove: (_) => controls.hoverTarget(figureId, ownerId),
      onLeave: (_) => controls.leaveTarget(figureId, ownerId),
      builder: (context, accepted, rejected) {
        final condition = accepted.firstOrNull ?? rejected.firstOrNull;
        final hovering = condition is Condition && !controls.isDragCancelled;
        final color = hovering
            ? controls.canApply(condition, figureId, ownerId)
                  ? Colors.greenAccent.shade400
                  : Colors.redAccent
            : Colors.transparent;
        return DecoratedBox(
          key: ValueKey('condition-target-$ownerId-$figureId'),
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: child,
        );
      },
    );
  }
}
