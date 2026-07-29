import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/scaling.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';

import '../CharacterWidget/character_widget.dart';
import '../MonsterWidget/monster_widget.dart';
import '../view_models/main_list_item_view_model.dart';

class MainListItem extends StatelessWidget {
  static const double _stateMarkerInset = 3;
  static const double _stateMarkerSize = 18;
  static const double _stateMarkerIconSize = 13;

  const MainListItem({super.key, required this.data});

  final ListItemData data;

  @override
  Widget build(BuildContext context) {
    final layout = getMainListLayout(context);
    final double scale = layout.scale;
    final double listWidth = layout.columnWidth;
    final vm = MainListItemViewModel(
      data: data,
      scale: scale,
      listWidth: listWidth,
    );

    Widget child;
    if (data is Character) {
      final character = data as Character;
      child = CharacterWidget(
        key: Key(character.id),
        characterId: character.id,
        initPreset: vm.initPreset,
      );
    } else if (data is Monster) {
      final monster = data as Monster;
      child = MonsterWidget(key: Key(monster.id), data: monster);
    } else {
      child = const SizedBox.shrink();
    }

    final row = AnimatedContainer(
      key: child.key,
      width: listWidth,
      height: vm.height,
      duration: layout.fitsScreenWidth
          ? Duration.zero
          : const Duration(milliseconds: 500),
      child: child,
    );

    return ValueListenableBuilder<TurnsState>(
      valueListenable: data.turnState,
      child: row,
      builder: (context, turnState, child) {
        return RepaintBoundary(
          child: Stack(
            children: [
              child!,
              if (turnState != TurnsState.notDone)
                _buildStateMarker(turnState, scale),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStateMarker(TurnsState turnState, double scale) {
    final isCurrent = turnState == TurnsState.current;
    return Positioned(
      key: Key('turn-state-${isCurrent ? 'current' : 'done'}-${data.id}'),
      left: _stateMarkerInset * scale,
      top: _stateMarkerInset * scale,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.68),
            border: Border.all(
              color: isCurrent ? Colors.tealAccent : Colors.white70,
              width: 1.5 * scale,
            ),
            borderRadius: BorderRadius.circular(3 * scale),
          ),
          child: SizedBox.square(
            dimension: _stateMarkerSize * scale,
            child: Icon(
              isCurrent ? Icons.play_arrow_rounded : Icons.check_rounded,
              color: isCurrent ? Colors.tealAccent : Colors.white,
              size: _stateMarkerIconSize * scale,
            ),
          ),
        ),
      ),
    );
  }
}
