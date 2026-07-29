import 'package:flutter/material.dart';

import '../../../Resource/commands/clear_unlocked_classes_command.dart';
import '../../../Resource/state/game_state.dart';
import '../../../Resource/ui_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../save_menu.dart';
import '../special_unlocks_menu.dart';

class SettingsAdvancedSection extends StatelessWidget {
  const SettingsAdvancedSection({required this.gameState, super.key});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        ListTile(
          title: Text(l10n.settingsClearUnlocked),
          onTap: () => gameState.action(ClearUnlockedClassesCommand()),
        ),
        ListTile(
          title: Text(l10n.settingsUnlockSpecials),
          onTap: () => openDialog(context, SpecialUnlocksMenu()),
        ),
        ListTile(
          title: Text(l10n.settingsLoadSaveState),
          onTap: () => openDialog(context, const SaveMenu()),
        ),
      ],
    );
  }
}
