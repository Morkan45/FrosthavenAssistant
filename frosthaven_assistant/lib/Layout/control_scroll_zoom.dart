import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Gives Ctrl+wheel zoom priority over scrolling descendants.
class ControlScrollZoom extends SingleChildRenderObjectWidget {
  const ControlScrollZoom({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required super.child,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  RenderControlScrollZoom createRenderObject(BuildContext context) =>
      RenderControlScrollZoom(onZoomIn: onZoomIn, onZoomOut: onZoomOut);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderControlScrollZoom renderObject,
  ) {
    renderObject
      ..onZoomIn = onZoomIn
      ..onZoomOut = onZoomOut;
  }
}

class RenderControlScrollZoom extends RenderProxyBox {
  RenderControlScrollZoom({required this.onZoomIn, required this.onZoomOut});

  VoidCallback onZoomIn;
  VoidCallback onZoomOut;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!HardwareKeyboard.instance.isControlPressed) {
      return super.hitTest(result, position: position);
    }
    if (!size.contains(position)) return false;
    // Pointer signals go to the first registered handler. Visit this wrapper
    // before the list so Ctrl+wheel zooms without also scrolling the list.
    result.add(BoxHitTestEntry(this, position));
    hitTestChildren(result, position: position);
    return true;
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is! PointerScrollEvent ||
        !HardwareKeyboard.instance.isControlPressed ||
        event.scrollDelta.dy == 0) {
      return;
    }
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      if (event.scrollDelta.dy < 0) {
        onZoomIn();
      } else {
        onZoomOut();
      }
      event.respond(allowPlatformDefault: false);
    });
  }
}
