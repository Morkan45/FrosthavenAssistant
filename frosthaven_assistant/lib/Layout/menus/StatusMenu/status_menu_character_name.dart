import 'package:flutter/material.dart';

import '../../../Resource/commands/change_name_command.dart';
import '../../../Resource/state/game_state.dart';
import '../../../l10n/app_localizations.dart';

class StatusMenuCharacterName extends StatefulWidget {
  const StatusMenuCharacterName({
    required this.character,
    required this.gameState,
    required this.style,
    super.key,
  });

  final Character character;
  final GameState gameState;
  final TextStyle style;

  @override
  State<StatusMenuCharacterName> createState() =>
      _StatusMenuCharacterNameState();
}

class _StatusMenuCharacterNameState extends State<StatusMenuCharacterName> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _finishEditing();
    }
  }

  void _startEditing(String displayName) {
    _controller.text = displayName == widget.character.characterClass.name
        ? ''
        : displayName;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    setState(() => _isEditing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _finishEditing() {
    if (!_isEditing) return;

    final name = _controller.text.trim();
    final currentName = widget.character.characterState.display.value;
    setState(() => _isEditing = false);
    if (name.isNotEmpty && name != currentName) {
      widget.gameState.action(
        ChangeNameCommand(
          name,
          widget.character.id,
          gameState: widget.gameState,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.character.characterState.display,
      builder: (context, displayName, child) {
        if (_isEditing) {
          return TextField(
            key: const Key('status-character-name-field'),
            controller: _controller,
            focusNode: _focusNode,
            maxLines: 1,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            style: widget.style,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) => _finishEditing(),
          );
        }

        final isUnnamed = displayName == widget.character.characterClass.name;
        final visibleName = isUnnamed
            ? AppLocalizations.of(context)?.characterNamePlaceholder ?? 'Name'
            : displayName;
        return Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _startEditing(displayName),
            child: Text(
              visibleName,
              key: const Key('status-character-name'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: widget.style,
            ),
          ),
        );
      },
    );
  }
}
