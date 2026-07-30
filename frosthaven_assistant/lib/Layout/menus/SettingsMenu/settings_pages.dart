import 'package:flutter/material.dart';

import '../../../Resource/settings.dart';
import '../../../Resource/state/game_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/network/client.dart';
import '../../../services/network/network.dart';
import 'settings_advanced_section.dart';
import 'settings_content_section.dart';
import 'settings_display_section.dart';
import 'settings_gameplay_section.dart';
import 'settings_layout.dart';
import 'settings_network_section.dart';

List<SettingsPage> buildSettingsPages({
  required AppLocalizations l10n,
  required Settings settings,
  required GameState gameState,
  required Network network,
  required Client client,
  required VoidCallback onLayoutChanged,
}) => [
  SettingsPage(
    category: SettingsCategory.display,
    label: l10n.settingsCategoryDisplay,
    icon: Icons.monitor_outlined,
    child: SettingsDisplaySection(
      settings: settings,
      gameState: gameState,
      onLayoutChanged: onLayoutChanged,
    ),
  ),
  SettingsPage(
    category: SettingsCategory.gameplay,
    label: l10n.settingsCategoryGameplay,
    icon: Icons.tune,
    child: SettingsGameplaySection(settings: settings, gameState: gameState),
  ),
  SettingsPage(
    category: SettingsCategory.content,
    label: l10n.settingsCategoryContent,
    icon: Icons.view_list_outlined,
    child: SettingsContentSection(settings: settings, gameState: gameState),
  ),
  SettingsPage(
    category: SettingsCategory.network,
    label: l10n.settingsCategoryNetwork,
    icon: Icons.lan_outlined,
    child: SettingsNetworkSection(
      settings: settings,
      network: network,
      client: client,
      gameState: gameState,
    ),
  ),
  SettingsPage(
    category: SettingsCategory.advanced,
    label: l10n.settingsCategoryAdvanced,
    icon: Icons.settings_suggest_outlined,
    child: SettingsAdvancedSection(gameState: gameState),
  ),
];
