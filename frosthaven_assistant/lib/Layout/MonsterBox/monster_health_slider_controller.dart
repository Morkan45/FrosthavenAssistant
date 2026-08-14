import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Resource/commands/change_stat_commands/change_health_command.dart';
import '../../Resource/game_methods.dart';
import '../../Resource/scaling.dart';
import '../../Resource/state/game_state.dart';
import '../../services/service_locator.dart';

/// Turns a monster standee tile into a tap target for a precise vertical
/// health picker.
///
/// The pan recognizer is intentional: it claims drags that begin on the tile
/// before the ancestor initiative reorder control can claim them. Initiative
/// rows remain draggable from the rest of the row.
class MonsterHealthSliderController extends StatefulWidget {
  const MonsterHealthSliderController({
    required this.figure,
    required this.figureId,
    required this.ownerId,
    required this.child,
    required this.onOpenDetails,
    super.key,
    this.gameState,
  });

  /// Required pointer travel for a one-hit-point change at scale 1.
  ///
  /// The existing horizontal health wheel can move one hit point in roughly
  /// 4-10 logical pixels. Keeping this constant substantially slows the
  /// monster picker and avoids making high-health monsters more sensitive.
  static const double dragExtentPerHealth = 36.0;

  final FigureState figure;
  final String figureId;
  final String? ownerId;
  final Widget child;
  final VoidCallback onOpenDetails;
  final GameState? gameState;

  @override
  State<MonsterHealthSliderController> createState() =>
      _MonsterHealthSliderControllerState();
}

class _MonsterHealthSliderControllerState
    extends State<MonsterHealthSliderController> {
  static const double _kOverlayWidth = 76.0;
  static const double _kOverlayHeight = 226.0;
  static const double _kOverlayGap = 8.0;
  static const double _kScreenMargin = 8.0;

  OverlayEntry? _entry;

  GameState get _gameState => widget.gameState ?? getIt<GameState>();

  @override
  void dispose() {
    _removeOverlay();
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

  void _handleTilePan(DragStartDetails _) {
    // A pan that starts on a standee belongs to the standee, not to the
    // ancestor ReorderableWrap. Closing any stale picker also gives this
    // recognizer a concrete action while it claims the gesture arena.
    _removeOverlay();
  }

  void _openDetails() {
    _removeOverlay();
    widget.onOpenDetails();
  }

  void _submitHealth(int selectedHealth) {
    _removeOverlay();
    final figure = GameMethods.getFigure(
      widget.ownerId,
      widget.figureId,
      gameState: _gameState,
    );
    if (figure == null) return;

    final change = selectedHealth - figure.health.value;
    if (change == 0) return;
    _gameState.action(
      ChangeHealthCommand(
        change,
        widget.figureId,
        widget.ownerId,
        gameState: _gameState,
      ),
    );
  }

  void _showOverlay() {
    if (_entry != null) {
      _removeOverlay();
      return;
    }

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
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: Key('monster-health-slider-dismiss-${widget.figureId}'),
              behavior: HitTestBehavior.opaque,
              onTap: _removeOverlay,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: overlayWidth,
            height: overlayHeight,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape):
                    _removeOverlay,
              },
              child: Focus(
                autofocus: true,
                child: _MonsterHealthSlider(
                  key: Key('monster-health-slider-${widget.figureId}'),
                  figureId: widget.figureId,
                  initialHealth: widget.figure.health.value,
                  maxHealth: widget.figure.maxHealth.value,
                  scale: scale,
                  onSubmitted: _submitHealth,
                  onOpenDetails: _openDetails,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    _entry = overlayEntry;
    overlay.insert(overlayEntry);
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final usesLongPressReorder =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;
    final target = InkWell(
      key: Key('monster-health-target-${widget.figureId}'),
      onTap: _showOverlay,
      // On touch platforms this child recognizer beats the ancestor's
      // LongPressDraggable without stealing ordinary vertical scrolls.
      onLongPress: usesLongPressReorder ? _showOverlay : null,
      child: widget.child,
    );
    if (usesLongPressReorder) return target;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _handleTilePan,
      child: target,
    );
  }
}

class _MonsterHealthSlider extends StatefulWidget {
  const _MonsterHealthSlider({
    required this.figureId,
    required this.initialHealth,
    required this.maxHealth,
    required this.scale,
    required this.onSubmitted,
    required this.onOpenDetails,
    super.key,
  });

  final String figureId;
  final int initialHealth;
  final int maxHealth;
  final double scale;
  final ValueChanged<int> onSubmitted;
  final VoidCallback onOpenDetails;

  @override
  State<_MonsterHealthSlider> createState() => _MonsterHealthSliderState();
}

class _MonsterHealthSliderState extends State<_MonsterHealthSlider> {
  static const double _kItemExtent = 30.0;
  static const double _kSelectedFontSize = 19.0;
  static const double _kUnselectedFontSize = 15.0;
  static const double _kHeaderFontSize = 13.0;
  static const double _kIconSize = 18.0;
  static const double _kBorderWidth = 1.0;
  static const double _kBorderRadius = 8.0;
  static const double _kElevation = 12.0;
  static const double _kWheelDiameterRatio = 1.35;

  FixedExtentScrollController? _scrollController;
  int _selected = 0;
  double _dragRemainder = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialHealth.clamp(0, widget.maxHealth);
    _scrollController = FixedExtentScrollController(initialItem: _selected);
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  void _select(int value) {
    final next = value.clamp(0, widget.maxHealth);
    if (next == _selected) return;
    setState(() => _selected = next);
    final controller = _scrollController;
    if (controller?.hasClients == true) controller?.jumpToItem(next);
  }

  void _handleDragStart(DragStartDetails _) {
    _dragRemainder = 0;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragRemainder -= details.delta.dy;
    final stepExtent =
        MonsterHealthSliderController.dragExtentPerHealth * widget.scale;
    final steps = (_dragRemainder / stepExtent).truncate();
    if (steps == 0) return;
    _dragRemainder -= steps * stepExtent;
    _select(_selected + steps);
  }

  void _handleDragEnd(DragEndDetails _) {
    widget.onSubmitted(_selected);
  }

  void _increase() {
    widget.onSubmitted((_selected + 1).clamp(0, widget.maxHealth));
  }

  void _decrease() {
    widget.onSubmitted((_selected - 1).clamp(0, widget.maxHealth));
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(_kBorderRadius * widget.scale);
    return Material(
      color: const Color(0xEE171717),
      elevation: _kElevation,
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.fromBorderSide(
            BorderSide(
              color: Colors.redAccent,
              width: _kBorderWidth * widget.scale,
            ),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 30 * widget.scale,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop,
                    color: Colors.redAccent,
                    size: _kIconSize * widget.scale,
                  ),
                  Text(
                    '$_selected/${widget.maxHealth}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _kHeaderFontSize * widget.scale,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: Key('monster-health-increase-${widget.figureId}'),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(height: 26 * widget.scale),
              color: Colors.white,
              disabledColor: Colors.white24,
              iconSize: _kIconSize * widget.scale,
              onPressed: _selected < widget.maxHealth ? _increase : null,
              icon: const Icon(Icons.keyboard_arrow_up),
            ),
            Expanded(
              child: Semantics(
                value: '$_selected/${widget.maxHealth}',
                increasedValue: '${min(_selected + 1, widget.maxHealth)}',
                decreasedValue: '${max(_selected - 1, 0)}',
                onIncrease: _selected < widget.maxHealth ? _increase : null,
                onDecrease: _selected > 0 ? _decrease : null,
                child: GestureDetector(
                  key: Key('monster-health-slider-drag-${widget.figureId}'),
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: _handleDragStart,
                  onVerticalDragUpdate: _handleDragUpdate,
                  onVerticalDragEnd: _handleDragEnd,
                  child: ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: _kItemExtent * widget.scale,
                    diameterRatio: _kWheelDiameterRatio,
                    physics: const NeverScrollableScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: widget.maxHealth + 1,
                      builder: (context, index) {
                        final isSelected = index == _selected;
                        return Center(
                          child: Text(
                            '$index',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.redAccent
                                  : Colors.white54,
                              fontSize:
                                  (isSelected
                                      ? _kSelectedFontSize
                                      : _kUnselectedFontSize) *
                                  widget.scale,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              key: Key('monster-health-decrease-${widget.figureId}'),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(height: 26 * widget.scale),
              color: Colors.white,
              disabledColor: Colors.white24,
              iconSize: _kIconSize * widget.scale,
              onPressed: _selected > 0 ? _decrease : null,
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
            IconButton(
              key: Key('monster-health-details-${widget.figureId}'),
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(height: 30 * widget.scale),
              color: Colors.white70,
              iconSize: _kIconSize * widget.scale,
              onPressed: widget.onOpenDetails,
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
      ),
    );
  }
}
