// `powerMode` replaced an older `reducePower` bool. Every existing install has
// the old key on disk, so the migration in Settings.loadFromDisk is what stops
// upgrades from silently reverting to `normal` — which would re-acquire the
// wakelock a user had deliberately released.
import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Resource/enums.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefsKey = 'settingsState';

Future<PowerMode> loadWith(String json) async {
  SharedPreferences.setMockInitialValues({_prefsKey: json});
  final settings = Settings();
  await settings.loadFromDisk();
  return settings.powerMode.value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('powerMode migration from the legacy reducePower bool', () {
    test('legacy reducePower:true becomes PowerMode.reducePower', () async {
      expect(await loadWith('{"reducePower": true}'), PowerMode.reducePower);
    });

    test('legacy reducePower:false becomes PowerMode.normal', () async {
      expect(await loadWith('{"reducePower": false}'), PowerMode.normal);
    });

    test('a payload with neither key defaults to PowerMode.normal', () async {
      expect(await loadWith('{"darkMode": true}'), PowerMode.normal);
    });

    test('powerMode wins over a stale legacy reducePower value', () async {
      // Written by a newer build: the enum is authoritative, and the legacy bool
      // is only kept in the payload for older peers.
      expect(
        await loadWith('{"powerMode": 1, "reducePower": false}'),
        PowerMode.dimWhenIdle,
      );
    });

    test('every tier round-trips through save and load', () async {
      for (final mode in PowerMode.values) {
        SharedPreferences.setMockInitialValues({});
        final saved = Settings();
        saved.powerMode.value = mode;
        await saved.saveToDisk();

        final prefs = await SharedPreferences.getInstance();
        final loaded = Settings();
        await loaded.loadFromDisk();
        expect(loaded.powerMode.value, mode,
            reason: '$mode did not survive a save/load round trip; '
                'payload was ${prefs.getString(_prefsKey)}');
      }
    });

    test('an out-of-range index falls back rather than throwing', () async {
      expect(await loadWith('{"powerMode": 99}'), PowerMode.normal);
      expect(await loadWith('{"powerMode": -1, "reducePower": true}'),
          PowerMode.reducePower);
    });
  });
}
