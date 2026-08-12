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

enum _LayoutScalePreset { compact, standard, large }

class SettingsDisplaySection extends StatelessWidget {
  static const double _barWidthBase = 40;
  static const double _barWidthMultiplier = 6.5;
  static const double _scaleMin = 0.2;
  static const double _scaleMax = 3;
  static const double _barScaleMin = 0.8;
  static const double _menuScaleMin = 0.7;
  static const double _menuScaleMax = 1.5;
  static const double _compactMainScale = 0.75;
  static const double _compactBarScale = 1;
  static const double _compactMenuScale = 0.85;
  static const double _standardMainScale = 1;
  static const double _standardDesktopBarScale = 1.6;
  static const double _standardMobileBarScale = 1;
  static const double _standardMenuScale = 1;
  static const double _largeMainScale = 1.5;
  static const double _largeBarScale = 2;
  static const double _largeMenuScale = 1.2;

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

  double get _standardBarScale =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS
      ? _standardDesktopBarScale
      : _standardMobileBarScale;

  Set<_LayoutScalePreset> _selectedPreset(double maxBarScale) {
    bool matches(double actual, double expected) =>
        (actual - expected).abs() < 0.01;

    if (matches(settings.userScalingMainList.value, _compactMainScale) &&
        matches(
          settings.userScalingBars.value,
          min(_compactBarScale, maxBarScale),
        ) &&
        matches(settings.userScalingMenus.value, _compactMenuScale)) {
      return const {_LayoutScalePreset.compact};
    }
    if (matches(settings.userScalingMainList.value, _standardMainScale) &&
        matches(
          settings.userScalingBars.value,
          min(_standardBarScale, maxBarScale),
        ) &&
        matches(settings.userScalingMenus.value, _standardMenuScale)) {
      return const {_LayoutScalePreset.standard};
    }
    if (matches(settings.userScalingMainList.value, _largeMainScale) &&
        matches(
          settings.userScalingBars.value,
          min(_largeBarScale, maxBarScale),
        ) &&
        matches(settings.userScalingMenus.value, _largeMenuScale)) {
      return const {_LayoutScalePreset.large};
    }
    return const {};
  }

  void _applyPreset(_LayoutScalePreset preset, double maxBarScale) {
    switch (preset) {
      case _LayoutScalePreset.compact:
        settings.userScalingMainList.value = _compactMainScale;
        settings.userScalingBars.value = min(_compactBarScale, maxBarScale);
        settings.userScalingMenus.value = _compactMenuScale;
      case _LayoutScalePreset.standard:
        settings.userScalingMainList.value = _standardMainScale;
        settings.userScalingBars.value = min(_standardBarScale, maxBarScale);
        settings.userScalingMenus.value = _standardMenuScale;
      case _LayoutScalePreset.large:
        settings.userScalingMainList.value = _largeMainScale;
        settings.userScalingBars.value = min(_largeBarScale, maxBarScale);
        settings.userScalingMenus.value = _largeMenuScale;
    }
    setMaxWidth();
    gameState.updateList.notify();
    settings.saveToDisk();
    onLayoutChanged();
  }

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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(child: Text(l10n.settingsPowerModeLabel)),
              SettingsInfoButton(
                infoTitle: l10n.settingsPowerModeInfoTitle,
                infoText: l10n.settingsPowerModeInfo,
              ),
            ],
          ),
        ),
        RadioGroup<PowerMode>(
          groupValue: settings.powerMode.value,
          onChanged: (value) {
            if (value == null) return;
            settings.powerMode.value = value;
            settings.saveToDisk();
            gameState.updateAllUI();
            onLayoutChanged();
          },
          child: Column(
            children: [
              RadioListTile<PowerMode>(
                value: PowerMode.normal,
                title: Text(l10n.powerModeNormal),
                visualDensity: VisualDensity.compact,
              ),
              RadioListTile<PowerMode>(
                value: PowerMode.dimWhenIdle,
                title: Text(l10n.powerModeDimWhenIdle),
                visualDensity: VisualDensity.compact,
              ),
              RadioListTile<PowerMode>(
                value: PowerMode.reducePower,
                title: Text(l10n.settingsReducePower),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.settingsMainListColumns),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: SegmentedButton<int>(
                    key: const Key('main-list-columns-selector'),
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: 0,
                        label: Text(l10n.settingsMainListColumnsAuto),
                      ),
                      const ButtonSegment(value: 1, label: Text('1')),
                      const ButtonSegment(value: 2, label: Text('2')),
                      const ButtonSegment(value: 3, label: Text('3')),
                    ],
                    selected: {settings.mainListColumns.value},
                    onSelectionChanged: (selection) {
                      settings.mainListColumns.value = selection.first;
                      settings.saveToDisk();
                      gameState.updateList.notify();
                      onLayoutChanged();
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.settingsLayoutScalePreset),
              const SizedBox(height: 6),
              SegmentedButton<_LayoutScalePreset>(
                key: const Key('layout-scale-presets'),
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _LayoutScalePreset.compact,
                    icon: const Icon(Icons.compress),
                    label: Text(l10n.settingsScalePresetCompact),
                  ),
                  ButtonSegment(
                    value: _LayoutScalePreset.standard,
                    icon: const Icon(Icons.crop_free),
                    label: Text(l10n.settingsScalePresetDefault),
                  ),
                  ButtonSegment(
                    value: _LayoutScalePreset.large,
                    icon: const Icon(Icons.zoom_out_map),
                    label: Text(l10n.settingsScalePresetLarge),
                  ),
                ],
                selected: _selectedPreset(maxBarScale),
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) return;
                  _applyPreset(selection.first, maxBarScale);
                },
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
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
