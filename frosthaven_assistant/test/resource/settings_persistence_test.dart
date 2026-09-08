import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Direct platform substitution is required to exercise legacy preference
// failure contracts; shared_preferences exposes no public failing fake.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const String _prefsKey = 'settingsState';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'malformed JSON leaves settings untouched and remains on disk',
    () async {
      const corruptPayload = '{"darkMode": true';
      SharedPreferences.setMockInitialValues({_prefsKey: corruptPayload});
      final settings = Settings()
        ..darkMode.value = true
        ..style.value = Style.gloomhaven;

      await expectLater(settings.loadFromDisk(), throwsFormatException);

      expect(settings.darkMode.value, isTrue);
      expect(settings.style.value, Style.gloomhaven);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_prefsKey), corruptPayload);
    },
  );

  test('corrupt settings block writes until explicitly reset', () async {
    const corruptPayload = '{corrupt';
    SharedPreferences.setMockInitialValues({_prefsKey: corruptPayload});
    final settings = Settings();

    await expectLater(settings.loadFromDisk(), throwsFormatException);
    settings.darkMode.value = true;
    await expectLater(settings.saveToDisk(), throwsStateError);
    await expectLater(settings.flushPersistence(), throwsStateError);
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_prefsKey), corruptPayload);

    await settings.resetSavedSettings();

    expect(settings.darkMode.value, isFalse);
    expect(settings.saves.value, isEmpty);
    await settings.saveToDisk();
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_prefsKey), isNot(corruptPayload));
  });

  test(
    'invalid fields use constructor defaults before any values are applied',
    () async {
      SharedPreferences.setMockInitialValues({
        _prefsKey: jsonEncode({
          'darkMode': true,
          'noInit': 'wrong type',
          'style': 999,
          'powerMode': -1,
          'userScalingMainList': 4.0,
          'userScalingBars': 0.1,
          'userScalingMenus': 'large',
          'mainListColumns': 4,
          'locale': 'unsupported',
          'saves': {'valid': 12},
          'characterSaves': ['wrong shape'],
        }),
      });
      final settings = Settings()
        ..noInit.value = false
        ..style.value = Style.frosthaven
        ..powerMode.value = PowerMode.reducePower
        ..userScalingMainList.value = 2.0
        ..mainListColumns.value = 2
        ..locale.value = 'de'
        ..saves.value = {'existing': 'value'};

      await settings.loadFromDisk();

      expect(settings.darkMode.value, isTrue);
      expect(settings.noInit.value, isTrue);
      expect(settings.style.value, Style.original);
      expect(settings.powerMode.value, PowerMode.normal);
      expect(settings.userScalingMainList.value, 1.0);
      expect(settings.userScalingBars.value, greaterThanOrEqualTo(1.0));
      expect(settings.userScalingMenus.value, 1.0);
      expect(settings.mainListColumns.value, 0);
      expect(settings.locale.value, 'en');
      expect(settings.saves.value, isEmpty);
      expect(settings.characterSaves.value, isEmpty);
    },
  );

  test(
    'settings writes are serialized and retain the latest pending snapshot',
    () async {
      final releaseFirstWrite = Completer<void>();
      final writes = <Map<String, dynamic>>[];
      final settings = Settings(
        writer: (value) async {
          writes.add(jsonDecode(value) as Map<String, dynamic>);
          if (writes.length == 1) await releaseFirstWrite.future;
        },
      );

      settings.darkMode.value = false;
      final first = settings.saveToDisk();
      settings.darkMode.value = true;
      final second = settings.saveToDisk();
      settings.darkMode.value = false;
      final third = settings.saveToDisk();

      expect(writes, hasLength(1));
      releaseFirstWrite.complete();
      await Future.wait([first, second, third]);

      expect(writes, hasLength(2));
      expect(writes.first['darkMode'], isFalse);
      expect(writes.last['darkMode'], isFalse);
    },
  );

  test('an explicitly awaited settings write reports writer failure', () async {
    final settings = Settings(
      writer: (_) async {
        throw StateError('write failed');
      },
    );

    await expectLater(settings.saveToDisk(), throwsStateError);
  });

  test('default writer reports a false SharedPreferences result', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = _FailingSetStore();
    final settings = Settings();

    try {
      await expectLater(settings.saveToDisk(), throwsStateError);
      expect(settings.persistenceStatus.value.hasError, isTrue);
    } finally {
      SharedPreferences.setMockInitialValues({});
    }
  });

  test(
    'SharedPreferences read failures propagate without applying values',
    () async {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = _FailingReadStore();
      final settings = Settings()..darkMode.value = true;

      try {
        await expectLater(settings.loadFromDisk(), throwsStateError);
        expect(settings.darkMode.value, isTrue);
      } finally {
        SharedPreferences.setMockInitialValues({});
      }
    },
  );

  test('loading can defer the configured startup reconnect', () async {
    SharedPreferences.setMockInitialValues({
      _prefsKey: jsonEncode({'connectClientOnStartup': true}),
    });
    final settings = Settings();

    await settings.loadFromDisk(reconnectOnStartup: false);

    expect(settings.connectClientOnStartup, isTrue);
    expect(settings.client.value.name, 'disconnected');
  });

  test('Traditional Chinese locale round-trips', () async {
    SharedPreferences.setMockInitialValues({});
    final source = Settings()..locale.value = 'zh_Hant';
    await source.saveToDisk();

    final restored = Settings();
    await restored.loadFromDisk(reconnectOnStartup: false);

    expect(restored.locale.value, 'zh_Hant');
  });

  test('every persisted field round-trips through the codec', () async {
    SharedPreferences.setMockInitialValues({});
    final source = Settings()
      ..userScalingMainList.value = 2.5
      ..fitMainListToWidth.value = true
      ..mainListColumns.value = 3
      ..userScalingBars.value = 2.25
      ..userScalingMenus.value = 1.4
      ..fullScreen.value = false
      ..softNumpadInput.value = true
      ..darkMode.value = true
      ..noInit.value = false
      ..noStandees.value = true
      ..randomStandees.value = true
      ..noCalculation.value = true
      ..expireConditions.value = false
      ..hideLootDeck.value = true
      ..style.value = Style.frosthaven
      ..shimmer.value = false
      ..powerMode.value = PowerMode.reducePower
      ..showScenarioNames.value = false
      ..showCustomContent.value = false
      ..showSectionsInMainView.value = false
      ..showReminders.value = false
      ..autoAddStandees.value = false
      ..autoAddSpawns.value = false
      ..showAmdDeck.value = false
      ..showBattleGoalReminder.value = false
      ..fhHazTerrainCalcInOGGloom.value = false
      ..showCharacterAMD.value = false
      ..enableHeathWheel.value = false
      ..locale.value = 'zh_Hant'
      ..saves.value = {'campaign': '{"round":2}'}
      ..characterSaves.value = {'banner spear': '{"hp":8}'}
      ..connectClientOnStartup = true
      ..lastKnownConnection = 'table.local'
      ..lastKnownPort = '9876'
      ..lastKnownHostIP = 'Table (10.0.0.2)';
    await source.saveToDisk();

    final restored = Settings();
    await restored.loadFromDisk(reconnectOnStartup: false);

    expect(jsonDecode(restored.toString()), jsonDecode(source.toString()));
  });
}

class _FailingSetStore extends InMemorySharedPreferencesStore {
  _FailingSetStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}

class _FailingReadStore extends InMemorySharedPreferencesStore {
  _FailingReadStore() : super.empty();

  @override
  Future<Map<String, Object>> getAll() async => throw StateError('read failed');
}
