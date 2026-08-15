import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../Resource/commands/change_stat_commands/change_health_command.dart';
import '../../Resource/game_methods.dart';
import '../../Resource/scaling.dart';
import '../../Resource/state/game_state.dart';
import '../../services/service_locator.dart';

/// Turns the HP portion of a monster standee into a precise vertical health
/// control.
///
/// The control appears as soon as the pointer goes down, follows that same
/// drag, and commits once when the pointer is released. Claiming the gesture
/// here also prevents the ancestor initiative row from being reordered when
/// the drag starts on monster HP.
class MonsterHealthSliderController extends StatefulWidget {
  const MonsterHealthSliderController({
    required this.figureId,
    required this.ownerId,
    required this.child,
    super.key,
    this.gameState,
  });

  /// Required pointer travel for a one-hit-point change at scale 1.
  ///
  /// The existing horizontal health wheel can move one hit point in roughly
  /// 4-10 logical pixels. Keeping this constant makes the monster control
  /// deliberately slower and predictable for monsters of every max health.
  static const double dragExtentPerHealth = 36.0;

  final String figureId;
  final String? ownerId;
  final Widget child;
  final GameState? gameState;

  @override
  State<MonsterHealthSliderController> createState() =>
      _MonsterHealthSliderControllerState();
}

class _MonsterHealthSliderControllerState
    extends State<MonsterHealthSliderController> {
  static const double _kOverlayWidth = 72.0;
  static const double _kOverlayHeight = 210.0;
  static const double _kOverlayGap = 8.0;
  static const double _kScreenMargin = 8.0;

  final ValueNotifier<int> _selectedDelta = ValueNotifier(0);
  OverlayEntry? _entry;
  double _dragDistance = 0;
  double _panStartY = 0;
  int _initialHealth = 0;
  int _maximumHealth = 0;

  GameState get _gameState => widget.gameState ?? getIt<GameState>();

  @override
  void dispose() {
    _removeOverlay();
    _selectedDelta.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    final overlayEntry = _entry;
    _entry = null;
    if (overlayEntry == null) return;
    // An inserted entry is not `mounted` until its first build, but Flutter
    // still requires remove() before dispose() in that same-frame window.
    overlayEntry.remove();
    overlayEntry.dispose();
  }

  void _beginGesture([double? globalY]) {
    final figure = GameMethods.getFigure(
      widget.ownerId,
      widget.figureId,
      gameState: _gameState,
    );
    if (figure == null) return;

    _dragDistance = 0;
    if (globalY != null) _panStartY = globalY;
    _initialHealth = figure.health.value;
    _maximumHealth = figure.maxHealth.value;
    _selectedDelta.value = 0;
    if (_entry == null) _showOverlay();
  }

  void _updateFromDistance(double verticalDistance, double scale) {
    _dragDistance = verticalDistance;
    final stepExtent =
        MonsterHealthSliderController.dragExtentPerHealth * scale;
    final requestedDelta = (-_dragDistance / stepExtent).truncate();
    _selectedDelta.value = requestedDelta.clamp(
      -_initialHealth,
      _maximumHealth - _initialHealth,
    );
  }

  void _updatePan(DragUpdateDetails details, double scale) {
    _updateFromDistance(details.globalPosition.dy - _panStartY, scale);
  }

  void _finishGesture() {
    final change = _selectedDelta.value;
    _removeOverlay();
    if (change == 0) return;

    final figure = GameMethods.getFigure(
      widget.ownerId,
      widget.figureId,
      gameState: _gameState,
    );
    if (figure == null) return;

    _gameState.action(
      ChangeHealthCommand(
        change,
        widget.figureId,
        widget.ownerId,
        gameState: _gameState,
      ),
    );
  }

  void _cancelGesture() {
    _removeOverlay();
  }

  void _showOverlay() {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final bounds = context.globalPaintBounds;
    if (overlay == null || bounds == null) return;

    final screenSize = MediaQuery.sizeOf(context);
    final scale = getScaleByReference(context);
    final margin = _kScreenMargin * scale;
    final overlayWidth = min(
      _kOverlayWidth * scale,
      max(0.0, screenSize.width - margin * 2),
    );
    final overlayHeight = min(
      _kOverlayHeight * scale,
      max(0.0, screenSize.height - margin * 2),
    );
    final maximumLeft = max(margin, screenSize.width - overlayWidth - margin);
    final maximumTop = max(margin, screenSize.height - overlayHeight - margin);
    final left = (bounds.center.dx - overlayWidth / 2).clamp(
      margin,
      maximumLeft,
    );
    final topAbove = bounds.top - overlayHeight - _kOverlayGap * scale;
    final preferredTop = topAbove >= margin
        ? topAbove
        : bounds.bottom + _kOverlayGap * scale;
    final top = preferredTop.clamp(margin, maximumTop);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        width: overlayWidth,
        height: overlayHeight,
        child: IgnorePointer(
          child: _MonsterHealthDeltaSlider(
            key: Key('monster-health-slider-${widget.figureId}'),
            figureId: widget.figureId,
            selectedDelta: _selectedDelta,
            minimumDelta: -_initialHealth,
            maximumDelta: _maximumHealth - _initialHealth,
            scale: scale,
          ),
        ),
      ),
    );
    _entry = overlayEntry;
    overlay.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    final scale = getScaleByReference(context);
    return GestureDetector(
      key: Key('monster-health-target-${widget.figureId}'),
      behavior: HitTestBehavior.opaque,
      onPanDown: (details) => _beginGesture(details.globalPosition.dy),
      onPanStart: (details) =>
          _updateFromDistance(details.globalPosition.dy - _panStartY, scale),
      onPanUpdate: (details) => _updatePan(details, scale),
      onPanEnd: (_) => _finishGesture(),
      onPanCancel: _cancelGesture,
      // On touch platforms this child long-press recognizer beats the
      // ancestor LongPressDraggable if the pointer is held before moving.
      onLongPressStart: (_) => _beginGesture(),
      onLongPressMoveUpdate: (details) =>
          _updateFromDistance(details.offsetFromOrigin.dy, scale),
      onLongPressEnd: (_) => _finishGesture(),
      child: widget.child,
    );
  }
}

class _MonsterHealthDeltaSlider extends StatelessWidget {
  const _MonsterHealthDeltaSlider({
    required this.figureId,
    required this.selectedDelta,
    required this.minimumDelta,
    required this.maximumDelta,
    required this.scale,
    super.key,
  });

  static const int _kVisibleDistance = 3;
  static const double _kSelectedFontSize = 20.0;
  static const double _kUnselectedFontSize = 15.0;
  static const double _kBorderWidth = 1.0;
  static const double _kBorderRadius = 8.0;
  static const double _kElevation = 12.0;

  final String figureId;
  final ValueListenable<int> selectedDelta;
  final int minimumDelta;
  final int maximumDelta;
  final double scale;

  String _formatDelta(int value) => value > 0 ? '+$value' : '$value';

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(_kBorderRadius * scale);
    return Material(
      color: const Color(0xEE171717),
      elevation: _kElevation,
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.fromBorderSide(
            BorderSide(color: Colors.redAccent, width: _kBorderWidth * scale),
          ),
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: selectedDelta,
          builder: (context, selected, child) => Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_kVisibleDistance * 2 + 1, (index) {
              final value = selected + _kVisibleDistance - index;
              final isSelected = value == selected;
              final isAvailable =
                  value >= minimumDelta && value <= maximumDelta;
              return Text(
                _formatDelta(value),
                key: Key('monster-health-delta-$figureId-$value'),
                style: TextStyle(
                  height: 1,
                  color: isSelected
                      ? Colors.redAccent
                      : isAvailable
                      ? Colors.white
                      : Colors.white24,
                  fontSize:
                      (isSelected ? _kSelectedFontSize : _kUnselectedFontSize) *
                      scale,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
