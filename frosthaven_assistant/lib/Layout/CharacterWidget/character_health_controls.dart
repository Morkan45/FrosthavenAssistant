import 'package:flutter/material.dart';

import '../../Resource/commands/change_stat_commands/change_health_command.dart';
import '../../Resource/state/game_state.dart';
import '../../services/service_locator.dart';
import '../../Resource/commands/command_l10n.dart';

class CharacterHealthControls extends StatelessWidget {
  static const double buttonSize = 50;
  static const double _iconSize = 30;

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
  Widget build(BuildContext context) {
    final state = gameState ?? getIt<GameState>();
    return ValueListenableBuilder<int>(
      valueListenable: character.characterState.health,
      builder: (context, health, _) => ValueListenableBuilder<int>(
        valueListenable: character.characterState.maxHealth,
        builder: (context, maxHealth, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HealthButton(
              key: const Key('character-health-decrease'),
              icon: Icons.remove,
              tooltip: commandL10n.cmdDecreaseHealth(character.id, 1),
              scale: scale,
              enabled: health > 0,
              onPressed: () => state.action(
                ChangeHealthCommand(
                  -1,
                  character.id,
                  character.id,
                  gameState: state,
                ),
              ),
            ),
            _HealthButton(
              key: const Key('character-health-increase'),
              icon: Icons.add,
              tooltip: commandL10n.cmdIncreaseHealth(character.id, 1),
              scale: scale,
              enabled: health < maxHealth,
              onPressed: () => state.action(
                ChangeHealthCommand(
                  1,
                  character.id,
                  character.id,
                  gameState: state,
                ),
              ),
            ),
          ],
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
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final double scale;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CharacterHealthControls.buttonSize * scale,
      height: CharacterHealthControls.buttonSize * scale,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          icon,
          size: _HealthButton._scaledIconSize(scale),
          color: enabled ? Colors.white70 : Colors.white24,
        ),
      ),
    );
  }

  static double _scaledIconSize(double scale) =>
      CharacterHealthControls._iconSize * scale;
}
