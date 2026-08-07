import 'package:flutter/material.dart';

import '../../Resource/enums.dart';
import '../../Resource/scaling.dart';
import '../../Resource/settings.dart';
import '../../Resource/state/game_state.dart';
import '../../Resource/ui_utils.dart';
import '../menus/numpad_menu.dart';
import '../view_models/character_widget_internal_view_model.dart';
import 'character_background_widget.dart';
import 'character_health_controls.dart';
import 'character_health_widget.dart';
import 'character_icon_widget.dart';
import 'character_level_widget.dart';
import 'character_xp_widget.dart';
import 'initiative_widget.dart';

class CharacterWidgetInternal extends StatefulWidget {
  static const double _kScaledHeight = 60.0;
  static const double _kXPTop = 10.0;
  static const double _kXPLeft = 260.0;
  static const double _kLevelTop = 28.0;
  static const double _kLevelLeft = 262.0;
  static const double _kHealthControlsRightInset = 6.0;
  static const double _kHealthControlsLeft =
      referenceWidth -
      _kHealthControlsRightInset -
      CharacterHealthControls.buttonSize * 2;
  static const double _kHealthControlsTop = 5.0;
  static const double _kInkwellWidth = 70.0;
  static const double _kIconColumnWidth = 62.0;
  static const double _kInitiativeColumnWidth = 45.0;
  static const double _kDetailsColumnWidth = 145.0;
  static const int _kInitMaxLength = 2;

  const CharacterWidgetInternal({
    super.key,
    required this.character,
    required this.isCharacter,
    required this.characterId,
    this.initPreset,
    this.gameState,
    this.settings,
  });

  final Character character;
  final bool isCharacter;
  final String characterId;
  final int? initPreset;

  static final Set<String> localCharacterInitChanges = {};

  final GameState? gameState;
  // injected for testing
  final Settings? settings;

  @override
  CharacterInternalWidgetState createState() => CharacterInternalWidgetState();
}

class CharacterInternalWidgetState extends State<CharacterWidgetInternal> {
  CharacterWidgetInternalViewModel? _vmInstance;
  CharacterWidgetInternalViewModel get _vm =>
      _vmInstance ??= CharacterWidgetInternalViewModel(
        widget.character,
        gameState: widget.gameState,
        settings: widget.settings,
      );
  bool isCharacter = true;
  final _initTextFieldController = TextEditingController();
  List<MonsterInstance> lastList = [];
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final character = widget.character;
    lastList = character.characterState.summonList.toList();

    if (widget.initPreset != null) {
      _initTextFieldController.text = widget.initPreset.toString();
    }
    _initTextFieldController.addListener(_textFieldControllerListener);

    isCharacter = !_vm.isObjectiveOrEscort;
    if (isCharacter) {
      _initTextFieldController.clear();
    }
    if (_vm.roundState.index >= 0) {
      // clear on playTurns
      if (_vm.roundState == RoundState.playTurns) {
        CharacterWidgetInternal.localCharacterInitChanges.clear();
      }
    }
  }

  void _textFieldControllerListener() {
    final text = _initTextFieldController.value.text;
    if (_vm.handleInitTextChange(text)) {
      CharacterWidgetInternal.localCharacterInitChanges.add(
        widget.character.id,
      );
    }
  }

  @override
  void dispose() {
    _initTextFieldController.removeListener(_textFieldControllerListener);
    _initTextFieldController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double scale = getScaleByReference(context);
    double scaledHeight = CharacterWidgetInternal._kScaledHeight * scale;

    final shadow = textShadow(scale);

    final character = widget.character;
    return SizedBox(
      width: getMainListWidth(context),
      height: CharacterWidgetInternal._kScaledHeight * scale,
      child: Stack(
        children: [
          CharacterBackgroundWidget(
            character: character,
            scale: scale,
            shadow: shadow,
          ),
          Row(
            children: [
              SizedBox(
                key: const Key('character-icon-column'),
                width: CharacterWidgetInternal._kIconColumnWidth * scale,
                child: CharacterIconWidget(
                  character: character,
                  scale: scale,
                  shadow: shadow,
                  scaledHeight: scaledHeight,
                  isCharacter: isCharacter,
                ),
              ),
              SizedBox(
                key: const Key('character-initiative-column'),
                width: CharacterWidgetInternal._kInitiativeColumnWidth * scale,
                child: InitiativeWidget(
                  scale: scale,
                  scaledHeight: scaledHeight,
                  shadow: shadow,
                  isCharacter: isCharacter,
                  character: character,
                  initTextFieldController: _initTextFieldController,
                  focusNode: _focusNode,
                ),
              ),
              SizedBox(
                key: const Key('character-details-column'),
                width: CharacterWidgetInternal._kDetailsColumnWidth * scale,
                child: CharacterHealthWidget(
                  character: character,
                  scale: scale,
                  shadow: shadow,
                  scaledHeight: scaledHeight,
                ),
              ),
            ],
          ),
          if (isCharacter)
            Positioned(
              top: CharacterWidgetInternal._kXPTop * scale,
              left: CharacterWidgetInternal._kXPLeft * scale,
              child: CharacterXPWidget(
                character: character,
                scale: scale,
                shadow: shadow,
              ),
            ),
          if (isCharacter)
            Positioned(
              top: CharacterWidgetInternal._kLevelTop * scale,
              left: CharacterWidgetInternal._kLevelLeft * scale,
              child: CharacterLevelWidget(
                character: character,
                scale: scale,
                shadow: shadow,
              ),
            ),
          if (isCharacter)
            Positioned(
              left: CharacterWidgetInternal._kHealthControlsLeft * scale,
              top: CharacterWidgetInternal._kHealthControlsTop * scale,
              child: CharacterHealthControls(
                character: character,
                scale: scale,
                gameState: widget.gameState,
              ),
            ),
          if (_vm.isAlive)
            InkWell(
              onTap: () {
                if (_vm.isChooseInitiative) {
                  if (_vm.softNumpadInput) {
                    openDialog(
                      context,
                      NumpadMenu(
                        controller: _initTextFieldController,
                        maxLength: CharacterWidgetInternal._kInitMaxLength,
                      ),
                    );
                  } else {
                    _focusNode.requestFocus();
                  }
                } else {
                  _vm.endTurn();
                }
              },
              child: SizedBox(
                height: CharacterWidgetInternal._kScaledHeight * scale,
                width: CharacterWidgetInternal._kInkwellWidth * scale,
              ),
            ),
        ],
      ),
    );
  }
}
