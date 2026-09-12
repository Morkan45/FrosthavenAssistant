import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/Resource/ui_utils.dart';

import 'view_models/global_hotkeys_view_model.dart';
import 'view_models/display_controls_view_model.dart';

// Wraps a SingleActivator so it only fires when no text field is focused.
// CallbackShortcuts consumes key events before calling callbacks, so the
// focus check must live in accepts() rather than in the callback itself.
class _NoTextFieldActivator implements ShortcutActivator {
  const _NoTextFieldActivator(this._inner);

  final SingleActivator _inner;

  static bool _isTextInputFocused() {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext == null) return false;
    return focusedContext.widget is EditableText ||
        focusedContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) {
    if (_isTextInputFocused()) return false;
    return _inner.accepts(event, state);
  }

  @override
  String debugDescribeKeys() => _inner.debugDescribeKeys();

  @override
  Iterable<LogicalKeyboardKey>? get triggers => _inner.triggers;
}

class GlobalHotkeys extends StatelessWidget {
  const GlobalHotkeys({
    required this.child,
    super.key,
    this.gameState,
    this.settings,
  });

  final Widget child;
  final GameState? gameState;
  final Settings? settings;

  @override
  Widget build(BuildContext context) {
    final vm = GlobalHotkeysViewModel(gameState: gameState);
    final display = DisplayControlsViewModel(settings: settings);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        for (final key in [
          LogicalKeyboardKey.equal,
          LogicalKeyboardKey.add,
          LogicalKeyboardKey.numpadAdd,
        ])
          for (final shifted in [false, true])
            _NoTextFieldActivator(
              SingleActivator(key, control: true, shift: shifted),
            ): display.zoomIn,
        for (final key in [
          LogicalKeyboardKey.minus,
          LogicalKeyboardKey.numpadSubtract,
        ])
          _NoTextFieldActivator(SingleActivator(key, control: true)):
              display.zoomOut,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): vm.undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): vm.undo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): vm.redo,
        const SingleActivator(LogicalKeyboardKey.keyY, meta: true): vm.redo,
        const _NoTextFieldActivator(SingleActivator(LogicalKeyboardKey.tab)):
            vm.advanceActivation,
        const _NoTextFieldActivator(
          SingleActivator(LogicalKeyboardKey.tab, shift: true),
        ): vm.undoActivation,
        const _NoTextFieldActivator(
          SingleActivator(LogicalKeyboardKey.space),
        ): () {
          final msg = vm.invokeDrawOrNextRound();
          if (msg != null) showToast(context, msg);
        },
        const _NoTextFieldActivator(
          SingleActivator(LogicalKeyboardKey.digit1),
        ): () =>
            vm.toggleElement(Elements.fire),
        const _NoTextFieldActivator(
          SingleActivator(LogicalKeyboardKey.digit2),
        ): () =>
            vm.toggleElement(Elements.ice),
        const _NoTextFieldActivator(
          SingleActivator(LogicalKeyboardKey.digit3),
        ): () =>
            vm.toggleElement(Elements.air),
        const _NoTextFieldActivator(
          SingleActivator(LogicalKeyboardKey.digit4),
        ): () =>
            vm.toggleElement(Elements.earth),
        const _NoTextFieldActivator(
          SingleActivator(LogicalKeyboardKey.digit5),
        ): () =>
            vm.toggleElement(Elements.light),
        const _NoTextFieldActivator(
          SingleActivator(LogicalKeyboardKey.digit6),
        ): () =>
            vm.toggleElement(Elements.dark),
      },
      child: child,
    );
  }
}
