import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../Resource/enums.dart';
import '../../../Resource/scaling.dart';
import '../../../Resource/settings.dart';
import '../../../Resource/state/game_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/service_locator.dart';
import '../../../services/translation_service.dart';
import 'settings_checkbox.dart';

class SettingsDisplaySection extends StatelessWidget {
  static const double _barWidthBase = 40;
  static const double _barWidthMultiplier = 6.5;
  static const double _scaleMin = 0.2;
  static const double _scaleMax = 3;
  static const double _barScaleMin = 0.8;
  static const double _menuScaleMin = 0.7;
  static const double _menuScaleMax = 1.5;

  static const Map<String, String> _locales = {
    'en': 'English',
    'de': 'Deutsch',
    'fr': 'Fran\u00e7ais',
    'es': 'Espa\u00f1ol',
    'pl': 'Polski',
    'ko': '\ud55c\uad6d\uc5b4',
    'ru': '\u0420\u0443\u0441\u0441\u043a\u0438\u0439',
    'zh': '\u4e2d\u6587',
    'zh_Hant': '\u4e2d\u6587 (\u7e41\u9ad4)',
    'th': '\u0e20\u0e32\u0e29\u0e32\u0e44\u0e17\u0e22',
  };

  const SettingsDisplaySection({
    required this.settings,
    required this.gameState,
    required this.onLayoutChanged,
    super.key,
  });

  final Settings settings;
  final GameState gameState;
  final VoidCallback onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final referenceMinBarWidth = _barWidthBase * _barWidthMultiplier;
    final maxBarScale = screenWidth / referenceMinBarWidth;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Text(l10n.settingsLanguage)),
              DropdownButton<String>(
                value: settings.locale.value,
                items: _locales.entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (newLocale) {
                  if (newLocale == null) return;
                  settings.locale.value = newLocale;
                  getIt<TranslationService>().load(newLocale);
                  settings.saveToDisk();
                  onLayoutChanged();
                },
              ),
            ],
          ),
        ),
        SettingsCheckbox(
          title: l10n.settingsDarkMode,
          notifier: settings.darkMode,
          onChanged: (value) {
            settings.darkMode.value = value;
            settings.saveToDisk();
          },
        ),
        if (!Platform.isIOS)
          SettingsCheckbox(
            title: l10n.settingsFullscreen,
            notifier: settings.fullScreen,
            onChanged: (value) {
              settings.setFullscreen(value);
              settings.saveToDisk();
            },
          ),
        SettingsCheckbox(
          title: l10n.settingsFitMainListWidth,
          notifier: settings.fitMainListToWidth,
          onChanged: (value) {
            settings.fitMainListToWidth.value = value;
            settings.saveToDisk();
            gameState.updateList.notify();
            onLayoutChanged();
          },
        ),
        if (settings.fitMainListToWidth.value)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Text(l10n.settingsMainListColumns)),
                DropdownButton<int>(
                  key: const Key('main-list-columns-dropdown'),
                  value: settings.mainListColumns.value,
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(l10n.settingsMainListColumnsAuto),
                    ),
                    const DropdownMenuItem(value: 1, child: Text('1')),
                    const DropdownMenuItem(value: 2, child: Text('2')),
                    const DropdownMenuItem(value: 3, child: Text('3')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    settings.mainListColumns.value = value;
                    settings.saveToDisk();
                    gameState.updateList.notify();
                    onLayoutChanged();
                  },
                ),
              ],
            ),
          ),
        _SettingsSlider(
          label: l10n.settingsMainListScaling,
          value: settings.userScalingMainList.value,
          min: _scaleMin,
          max: _scaleMax,
          onChanged: (value) {
            settings.userScalingMainList.value = value;
            setMaxWidth();
            onLayoutChanged();
          },
          onChangeEnd: settings.saveToDisk,
        ),
        _SettingsSlider(
          label: l10n.settingsAppBarScaling,
          value: min(settings.userScalingBars.value, maxBarScale),
          min: min(_barScaleMin, maxBarScale),
          max: min(maxBarScale, _scaleMax),
          onChanged: (value) {
            settings.userScalingBars.value = value;
            onLayoutChanged();
          },
          onChangeEnd: settings.saveToDisk,
        ),
        _SettingsSlider(
          label: l10n.settingsMenuScaling,
          value: settings.userScalingMenus.value.clamp(
            _menuScaleMin,
            _menuScaleMax,
          ),
          min: _menuScaleMin,
          max: _menuScaleMax,
          onChanged: (value) {
            settings.userScalingMenus.value = value;
            onLayoutChanged();
          },
          onChangeEnd: settings.saveToDisk,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(l10n.settingsStyleLabel),
        ),
        RadioGroup<Style>(
          groupValue: settings.style.value,
          onChanged: (value) {
            if (value == null) return;
            settings.style.value = value;
            settings.saveToDisk();
            gameState.updateList.notify();
            onLayoutChanged();
          },
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Radio<Style>(value: Style.frosthaven),
                  Text(l10n.styleFrosthaven),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Radio<Style>(value: Style.original),
                  Text(l10n.styleOriginal),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSlider extends StatelessWidget {
  const _SettingsSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(label),
        ),
        Slider(
          min: min,
          max: max,
          value: value,
          onChanged: onChanged,
          onChangeEnd: (_) => onChangeEnd(),
        ),
      ],
    );
  }
}
