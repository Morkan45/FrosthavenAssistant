import 'package:flutter/material.dart';

import '../../../Resource/commands/set_ally_deck_in_og_gloom_command.dart';
import '../../../Resource/commands/track_standees_command.dart';
import '../../../Resource/settings.dart';
import '../../../Resource/state/game_state.dart';
import '../../../l10n/app_localizations.dart';
import 'settings_checkbox.dart';

class SettingsGameplaySection extends StatelessWidget {
  const SettingsGameplaySection({
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
          title: l10n.settingsSoftNumpad,
          notifier: settings.softNumpadInput,
          onChanged: (value) {
            settings.softNumpadInput.value = value;
            settings.saveToDisk();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsNoInit,
          notifier: settings.noInit,
          onChanged: (value) {
            settings.noInit.value = value;
            settings.saveToDisk();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsExpireConditions,
          notifier: settings.expireConditions,
          onChanged: (value) {
            settings.expireConditions.value = value;
            settings.saveToDisk();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsNoStandees,
          notifier: settings.noStandees,
          onChanged: (value) {
            gameState.action(
              TrackStandeesCommand(
                !value,
                gameState: gameState,
                settings: settings,
              ),
            );
            settings.saveToDisk();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsAutoAddStandees,
          notifier: settings.autoAddStandees,
          onChanged: (value) {
            settings.autoAddStandees.value = value;
            settings.saveToDisk();
            gameState.updateList.notify();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsAutoAddSpawns,
          notifier: settings.autoAddSpawns,
          onChanged: (value) {
            settings.autoAddSpawns.value = value;
            settings.saveToDisk();
            gameState.updateList.notify();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsRandomStandees,
          notifier: settings.randomStandees,
          onChanged: (value) {
            settings.randomStandees.value = value;
            settings.saveToDisk();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsNoCalculations,
          notifier: settings.noCalculation,
          onChanged: (value) {
            settings.noCalculation.value = value;
            settings.saveToDisk();
            gameState.updateAllUI();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsHealthWheel,
          notifier: settings.enableHeathWheel,
          onChanged: (value) {
            settings.enableHeathWheel.value = value;
            settings.saveToDisk();
            gameState.updateAllUI();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsFhHazTerrainCalc,
          notifier: settings.fhHazTerrainCalcInOGGloom,
          onChanged: (value) {
            settings.fhHazTerrainCalcInOGGloom.value = value;
            settings.saveToDisk();
            gameState.updateAllUI();
          },
        ),
        SettingsCheckbox(
          title: l10n.settingsAllyDeckOGGloom,
          notifier: gameState.allyDeckInOGGloom,
          onChanged: (value) {
            gameState.action(
              SetAllyDeckInOgGloomCommand(value, gameState: gameState),
            );
            gameState.updateAllUI();
          },
        ),
      ],
    );
  }
}
