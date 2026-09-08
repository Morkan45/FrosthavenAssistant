import 'dart:convert';

import 'enums.dart';

/// A settings payload whose fields have all been validated before application.
class SettingsSnapshot {
  SettingsSnapshot(Map<String, Object> values)
    : _values = Map<String, Object>.unmodifiable(values);

  final Map<String, Object> _values;

  T value<T>(String key) => _values[key] as T;
}

/// Decodes the existing settings JSON format without exposing partial results.
///
/// Missing and invalid fields use the constructor defaults supplied by
/// [SettingsSnapshot] values passed as defaults. Invalid JSON or a non-object
/// root is rejected so callers can retain the corrupt payload for an explicit
/// recovery decision.
class SettingsCodec {
  const SettingsCodec();

  static const double _minimumMainScale = 0.2;
  static const double _minimumBarScale = 0.8;
  static const double _minimumMenuScale = 0.7;
  static const double _maximumMainAndBarScale = 3.0;
  static const double _maximumMenuScale = 1.5;
  static const int _maximumColumns = 3;
  static const Set<String> _supportedLocales = {
    'de',
    'en',
    'es',
    'fr',
    'ko',
    'pl',
    'ru',
    'th',
    'zh',
    'zh_Hant',
  };

  SettingsSnapshot decode(String source, {required SettingsSnapshot defaults}) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Settings JSON must contain an object.');
    }

    final values = <String, Object>{};
    for (final key in _boolKeys) {
      values[key] = _bool(decoded[key], defaults.value<bool>(key));
    }
    values['userScalingMainList'] = _scale(
      decoded['userScalingMainList'],
      defaults.value<double>('userScalingMainList'),
      minimum: _minimumMainScale,
      maximum: _maximumMainAndBarScale,
    );
    values['userScalingBars'] = _scale(
      decoded['userScalingBars'],
      defaults.value<double>('userScalingBars'),
      minimum: _minimumBarScale,
      maximum: _maximumMainAndBarScale,
    );
    values['userScalingMenus'] = _scale(
      decoded['userScalingMenus'],
      defaults.value<double>('userScalingMenus'),
      minimum: _minimumMenuScale,
      maximum: _maximumMenuScale,
    );

    values['mainListColumns'] = _columns(
      decoded['mainListColumns'],
      defaults.value<int>('mainListColumns'),
    );
    values['style'] = _enumValue(
      decoded['style'],
      Style.values,
      defaults.value<Style>('style'),
    );
    values['powerMode'] = _enumValue(
      decoded['powerMode'],
      PowerMode.values,
      defaults.value<PowerMode>('powerMode'),
    );
    for (final key in _stringKeys) {
      values[key] = _string(decoded[key], defaults.value<String>(key));
    }
    values['locale'] = _locale(
      decoded['locale'],
      defaults.value<String>('locale'),
    );
    values['saves'] = _stringMap(
      decoded['saves'],
      defaults.value<Map<String, String>>('saves'),
    );
    values['characterSaves'] = _stringMap(
      decoded['characterSaves'],
      defaults.value<Map<String, String>>('characterSaves'),
    );

    return SettingsSnapshot(values);
  }

  static const List<String> _boolKeys = [
    'fitMainListToWidth',
    'fullScreen',
    'softNumpadInput',
    'darkMode',
    'noInit',
    'noStandees',
    'randomStandees',
    'noCalculation',
    'expireConditions',
    'hideLootDeck',
    'shimmer',
    'showScenarioNames',
    'showCustomContent',
    'showSectionsInMainView',
    'showReminders',
    'autoAddStandees',
    'autoAddSpawns',
    'showAmdDeck',
    'showBattleGoalReminder',
    'fhHazTerrainCalcInOGGloom',
    'showCharacterAMD',
    'enableHeathWheel',
    'connectClientOnStartup',
  ];

  static const List<String> _stringKeys = [
    'lastKnownConnection',
    'lastKnownPort',
    'lastKnownHostIP',
  ];

  bool _bool(Object? value, bool fallback) => value is bool ? value : fallback;

  double _scale(
    Object? value,
    double fallback, {
    required double minimum,
    required double maximum,
  }) {
    if (value is! num) return fallback;
    final result = value.toDouble();
    return result.isFinite && result >= minimum && result <= maximum
        ? result
        : fallback;
  }

  int _columns(Object? value, int fallback) =>
      value is int && value >= 0 && value <= _maximumColumns ? value : fallback;

  T _enumValue<T>(Object? value, List<T> values, T fallback) =>
      value is int && value >= 0 && value < values.length
      ? values[value]
      : fallback;

  String _string(Object? value, String fallback) =>
      value is String ? value : fallback;

  String _locale(Object? value, String fallback) =>
      value is String && _supportedLocales.contains(value) ? value : fallback;

  Map<String, String> _stringMap(Object? value, Map<String, String> fallback) {
    if (value is! Map<String, dynamic> ||
        value.values.any((entry) => entry is! String)) {
      return Map<String, String>.of(fallback);
    }
    return value.map((key, entry) => MapEntry(key, entry as String));
  }
}
