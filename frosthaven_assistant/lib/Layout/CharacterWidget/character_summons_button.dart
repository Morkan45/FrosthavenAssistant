import 'package:flutter/material.dart';

import '../../Resource/app_constants.dart';
import '../../Resource/state/game_state.dart';
import '../../Resource/ui_utils.dart';
import '../menus/AddSummonMenu/add_summon_menu.dart';

class CharacterSummonsButton extends StatelessWidget {
  static const double _kSummonIconSize = 28;

  const CharacterSummonsButton({
    super.key,
    required this.scale,
    required this.character,
  });
  final double scale;
  final Character character;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kConditionButtonSize * scale,
      height: kConditionButtonSize * scale,
      child: IconButton(
        key: const Key('character-add-summon'),
        padding: EdgeInsets.zero,
        tooltip: 'Add Summon',
        icon: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Image.asset(
              'assets/images/summon/green.png',
              height: _kSummonIconSize * scale,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                Icons.add_circle,
                size: kIconSize * 0.5 * scale,
                color: Colors.white,
              ),
            ),
          ],
        ),
        onPressed: () {
          openDialog(context, AddSummonMenu(character: character));
        },
      ),
    );
  }
}
