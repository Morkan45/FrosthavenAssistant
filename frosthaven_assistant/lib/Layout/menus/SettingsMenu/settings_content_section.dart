import 'package:flutter/material.dart';

import '../../../Resource/settings.dart';
import '../../../Resource/state/game_state.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_checkbox.dart';

class SettingsContentSection extends StatelessWidget {
  const SettingsContentSection({
    required this.settings,
    required this.gameState,
    super.key,
  });

  final Settings settings;
  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SettingsCheckbox(
          title: l10n.settingsHideLootDeck,
          notifier: settings.hideLootDeck,
          onChanged: (value) {
            settings.hideLootDeck.value = value;
            _saveAndRefresh();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsShimmer,
          notifier: settings.shimmer,
          onChanged: (value) {
            settings.shimmer.value = value;
            _saveAndRefresh();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsShowScenarioNames,
          notifier: settings.showScenarioNames,
          onChanged: (value) {
            settings.showScenarioNames.value = value;
            _saveAndRefresh();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsShowBattleGoalReminder,
          notifier: settings.showBattleGoalReminder,
          onChanged: (value) {
            settings.showBattleGoalReminder.value = value;
            settings.saveToDisk();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsShowCustomContent,
          notifier: settings.showCustomContent,
          onChanged: (value) {
            settings.showCustomContent.value = value;
            _saveAndRefresh();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsShowSections,
          notifier: settings.showSectionsInMainView,
          onChanged: (value) {
            settings.showSectionsInMainView.value = value;
            _saveAndRefresh();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsShowReminders,
          notifier: settings.showReminders,
          onChanged: (value) {
            settings.showReminders.value = value;
            _saveAndRefresh();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsShowAmdDeck,
          notifier: settings.showAmdDeck,
          onChanged: (value) {
            settings.showAmdDeck.value = value;
            if (!value) settings.showCharacterAMD.value = false;
            _saveAndRefresh();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsShowCharacterAmd,
          notifier: settings.showCharacterAMD,
          onChanged: (value) {
            settings.showCharacterAMD.value = value;
            if (value) settings.showAmdDeck.value = true;
            _saveAndRefresh();
          },
        ),
      ],
    );
  }

  void _saveAndRefresh() {
    settings.saveToDisk();
    gameState.updateAllUI();
  }
}
