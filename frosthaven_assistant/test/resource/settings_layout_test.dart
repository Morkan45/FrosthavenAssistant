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
}
