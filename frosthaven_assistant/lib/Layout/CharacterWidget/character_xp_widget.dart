import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Resource/app_constants.dart';
import 'package:frosthaven_assistant/Resource/commands/change_stat_commands/change_xp_command.dart';

import '../../Resource/game_methods.dart';
import '../../Resource/state/game_state.dart';
import '../../Resource/ui_utils.dart';
import '../../services/service_locator.dart';

class CharacterXPWidget extends StatelessWidget {
  static const double _kImageHeight = 16.0;

  const CharacterXPWidget({
    super.key,
    required this.character,
    required this.scale,
    required this.shadow,
    this.gameState,
  });
  final Character character;
  final double scale;
  final Shadow shadow;
  final GameState? gameState;
  @override
  Widget build(BuildContext context) {
    final gameState = this.gameState ?? getIt<GameState>();
    void changeXp(int amount) {
      if (amount < 0 && character.characterState.xp.value == 0) return;
      gameState.action(
        ChangeXPCommand(
          amount,
          character.id,
          character.id,
          gameState: gameState,
        ),
      );
    }

    return Semantics(
      label: 'Experience',
      value: '${character.characterState.xp.value}',
      increasedValue: '${character.characterState.xp.value + 1}',
      decreasedValue:
          '${(character.characterState.xp.value - 1).clamp(0, character.characterState.xp.value)}',
      hint: 'Tap to add one. Double tap to subtract one.',
      onIncrease: () => changeXp(1),
      onDecrease: () => changeXp(-1),
      child: GestureDetector(
        onTap: () {
          changeXp(1);
        },
        onDoubleTap: () {
          changeXp(-1);
        },
        child: Row(
          children: [
            Image(
              height: CharacterXPWidget._kImageHeight * scale,
              color: Colors.blue,
              colorBlendMode: BlendMode.modulate,
              image: const AssetImage("assets/images/psd/xp.png"),
            ),
            ValueListenableBuilder<int>(
              valueListenable: character.characterState.xp,
              builder: (context, value, child) {
                return Text(
                  character.characterState.xp.value.toString(),
                  style: getCardTitleStyle(
                    kFontSizeSmall * scale,
                    shadow,
                    GameMethods.isFrosthavenStyle(null),
                    color: Colors.blue,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
