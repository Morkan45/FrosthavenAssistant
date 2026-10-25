import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../Resource/enums.dart';
import 'view_models/desktop_conditions_view_model.dart';

/// Keeps Flutter's drag avatar alive while the secondary mouse button is held.
class ConditionDragSource extends StatefulWidget {
  const ConditionDragSource({
    super.key,
    required this.condition,
    required this.controls,
    required this.feedback,
    required this.child,
  });

  final Condition condition;
  final DesktopConditionsViewModel controls;
  final Widget feedback;
  final Widget child;

  @override
  State<ConditionDragSource> createState() => _ConditionDragSourceState();
}

class _ConditionDragSourceState extends State<ConditionDragSource> {
  int? _pointer;
  int _buttons = 0;
  bool _dragging = false;
  bool _trackingPointer = false;

  void _startDrag() {
    _dragging = true;
    widget.controls.beginDrag(widget.condition);
    if (_pointer != null) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_trackButtons);
      _trackingPointer = true;
    }
  }

  void _trackButtons(PointerEvent event) {
    if (event.pointer != _pointer || event is! PointerMoveEvent) return;
    final leftReleased =
        (_buttons & kPrimaryButton) != 0 &&
        (event.buttons & kPrimaryButton) == 0;
    final rightHeld = (event.buttons & kSecondaryButton) != 0;
    _buttons = event.buttons;

    // Global routes run after Flutter updates the drag's hovered target.
    if (widget.controls.isStickyDrag && !rightHeld) {
      widget.controls.cancelDrag();
    } else if (leftReleased && rightHeld) {
      widget.controls.stickyDrop();
    }
  }

  void _endDrag() {
    _stopTracking();
    _dragging = false;
    _pointer = null;
    _buttons = 0;
    widget.controls.endDrag();
  }

  void _stopTracking() {
    if (!_trackingPointer) return;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_trackButtons);
    _trackingPointer = false;
  }

  @override
  void dispose() {
    _stopTracking();
    if (_dragging) widget.controls.cancelDrag(deferNotification: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controls = widget.controls;
    return Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kPrimaryButton &&
            !_dragging) {
          _pointer = event.pointer;
          _buttons = event.buttons;
        }
      },
      onPointerMove: (event) {
        // The drag avatar will identify the current target during routing.
        // Clear first so a removed target cannot receive a stale sticky drop.
        if (_dragging && event.pointer == _pointer) controls.clearHoverTarget();
      },
      child: Draggable<Condition>(
        data: widget.condition,
        maxSimultaneousDrags: controls.draggedCondition == null || _dragging
            ? 1
            : 0,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: _startDrag,
        onDragEnd: (_) => _endDrag(),
        feedback: ListenableBuilder(
          listenable: controls,
          builder: (context, _) {
            if (controls.isDragCancelled) return const SizedBox.shrink();
            return Stack(
              clipBehavior: Clip.none,
              children: [
                widget.feedback,
                if (controls.isStickyDrag)
                  const Positioned(
                    right: -3,
                    bottom: -3,
                    child: DecoratedBox(
                      key: Key('sticky-condition-drag'),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(
                          Icons.push_pin,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: widget.child),
        child: widget.child,
      ),
    );
  }
}
