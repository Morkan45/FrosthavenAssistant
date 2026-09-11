import 'dart:async';

import 'package:flutter/material.dart';

import '../../Resource/commands/command_l10n.dart';
import '../../Resource/commands/change_stat_commands/change_health_command.dart';
import '../../Resource/state/game_state.dart';
import '../../services/service_locator.dart';

class CharacterHealthControls extends StatefulWidget {
  static const double buttonSize = 44;
  static const double _iconSize = 30;
  static const Duration _feedbackDuration = Duration(seconds: 4);
  static const Duration _feedbackFadeDuration = Duration(milliseconds: 300);

  const CharacterHealthControls({
    super.key,
    required this.character,
    required this.scale,
    this.gameState,
  });

  final Character character;
  final double scale;
  final GameState? gameState;

  @override
  State<CharacterHealthControls> createState() =>
      _CharacterHealthControlsState();
}

class _CharacterHealthControlsState extends State<CharacterHealthControls> {
  Timer? _dismissTimer;
  int _accumulatedDelta = 0;
  int _displayedDelta = 0;
  bool _showFeedback = false;

  @override
  void didUpdateWidget(CharacterHealthControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character.id != widget.character.id) {
      _dismissTimer?.cancel();
      _dismissTimer = null;
      _accumulatedDelta = 0;
      _displayedDelta = 0;
      _showFeedback = false;
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _changeHealth(GameState state, int delta) {
    state.action(
      ChangeHealthCommand(
        delta,
        widget.character.id,
        widget.character.id,
        gameState: state,
      ),
    );

    _dismissTimer?.cancel();
    setState(() {
      _accumulatedDelta += delta;
      _displayedDelta = _accumulatedDelta;
      _showFeedback = _displayedDelta != 0;
    });
    _dismissTimer = Timer(
      CharacterHealthControls._feedbackDuration,
      _dismissFeedback,
    );
  }

  void _dismissFeedback() {
    final hadActiveFeedback =
        _dismissTimer != null || _accumulatedDelta != 0 || _showFeedback;
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _accumulatedDelta = 0;
    if (!hadActiveFeedback || !mounted) return;
    setState(() => _showFeedback = false);
  }

  void _handleFadeEnd() {
    if (_showFeedback || _displayedDelta == 0 || !mounted) return;
    setState(() => _displayedDelta = 0);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.gameState ?? getIt<GameState>();
    return TapRegion(
      onTapOutside: (_) => _dismissFeedback(),
      child: ValueListenableBuilder<int>(
        valueListenable: widget.character.characterState.health,
        builder: (context, health, _) => ValueListenableBuilder<int>(
          valueListenable: widget.character.characterState.maxHealth,
          builder: (context, maxHealth, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HealthButton(
                key: const Key('character-health-decrease'),
                icon: Icons.remove,
                tooltip: commandL10n.cmdDecreaseHealth(widget.character.id, 1),
                scale: widget.scale,
                enabled: health > 0,
                feedbackDelta: _displayedDelta < 0 ? _displayedDelta : 0,
                showFeedback: _showFeedback,
                onFeedbackFadeEnd: _handleFadeEnd,
                onPressed: () => _changeHealth(state, -1),
              ),
              _HealthButton(
                key: const Key('character-health-increase'),
                icon: Icons.add,
                tooltip: commandL10n.cmdIncreaseHealth(widget.character.id, 1),
                scale: widget.scale,
                enabled: health < maxHealth,
                feedbackDelta: _displayedDelta > 0 ? _displayedDelta : 0,
                showFeedback: _showFeedback,
                onFeedbackFadeEnd: _handleFadeEnd,
                onPressed: () => _changeHealth(state, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthButton extends StatelessWidget {
  const _HealthButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.scale,
    required this.enabled,
    required this.feedbackDelta,
    required this.showFeedback,
    required this.onFeedbackFadeEnd,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final double scale;
  final bool enabled;
  final int feedbackDelta;
  final bool showFeedback;
  final VoidCallback onFeedbackFadeEnd;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CharacterHealthControls.buttonSize * scale,
      height: CharacterHealthControls.buttonSize * scale,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            tooltip: tooltip,
            onPressed: enabled ? onPressed : null,
            icon: Icon(
              icon,
              size: _HealthButton._scaledIconSize(scale),
              color: enabled ? Colors.white70 : Colors.white24,
            ),
          ),
          if (feedbackDelta != 0)
            IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: AnimatedOpacity(
                  key: Key(
                    feedbackDelta < 0
                        ? 'character-health-negative-feedback'
                        : 'character-health-positive-feedback',
                  ),
                  opacity: showFeedback ? 1 : 0,
                  duration: CharacterHealthControls._feedbackFadeDuration,
                  onEnd: onFeedbackFadeEnd,
                  child: _HealthFeedbackBadge(
                    delta: feedbackDelta,
                    scale: scale,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static double _scaledIconSize(double scale) =>
      CharacterHealthControls._iconSize * scale;
}

class _HealthFeedbackBadge extends StatelessWidget {
  static const double _fontSize = 12;

  const _HealthFeedbackBadge({required this.delta, required this.scale});

  final int delta;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final accentColor = delta < 0 ? Colors.redAccent : Colors.lightGreenAccent;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 1 * scale),
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: accentColor),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Text(
        delta > 0 ? '+$delta' : '$delta',
        style: TextStyle(
          color: accentColor,
          fontSize: _fontSize * scale,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}
