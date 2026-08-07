// `powerMode` is persisted as an enum index, so a malformed or absent value
// must not throw or land on an arbitrary tier — a wrong value here silently
// changes whether the app holds the wakelock.
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

  group('powerMode persistence', () {
    test('a payload without the key defaults to PowerMode.normal', () async {
      expect(await loadWith('{"darkMode": true}'), PowerMode.normal);
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
      expect(await loadWith('{"powerMode": -1}'), PowerMode.normal);
    });
  });
}
