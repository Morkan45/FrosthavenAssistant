import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fit-width layout preferences persist', () async {
    SharedPreferences.setMockInitialValues({});
    final source = Settings();
    source.fitMainListToWidth.value = true;
    source.mainListColumns.value = 3;

    await source.saveToDisk();

    final restored = Settings();
    await restored.loadFromDisk();
    expect(restored.fitMainListToWidth.value, isTrue);
    expect(restored.mainListColumns.value, 3);
  });

  test(
    'status effect size persists independently of app bar scaling',
    () async {
      SharedPreferences.setMockInitialValues({});
      final source = Settings();
      source.statusEffectScale.value = 2.75;
      source.userScalingBars.value = 1.2;
      await source.saveToDisk();

      final restored = Settings();
      await restored.loadFromDisk();
      expect(restored.statusEffectScale.value, 2.75);
      expect(restored.userScalingBars.value, 1.2);
    },
  );

  for (final value in [null, 'large', -1, 0, 3.5]) {
    test(
      'missing or invalid status effect size $value uses the larger default',
      () async {
        SharedPreferences.setMockInitialValues({
          'settingsState': jsonEncode({'statusEffectScale': ?value}),
        });
        final settings = Settings();
        await settings.loadFromDisk();
        expect(settings.statusEffectScale.value, 2.0);
      },
    );
  }

  test('text settings with JSON characters persist', () async {
    SharedPreferences.setMockInitialValues({});
    final source = Settings();
    source.lastKnownConnection = 'host "table"\\desktop';
    source.lastKnownHostIP = '(Desk "A")';

    await source.saveToDisk();

    final restored = Settings();
    await restored.loadFromDisk();
    expect(restored.lastKnownConnection, source.lastKnownConnection);
    expect(restored.lastKnownHostIP, source.lastKnownHostIP);
  });
}
