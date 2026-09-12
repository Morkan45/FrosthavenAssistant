import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/view_models/display_controls_view_model.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'display controls clamp zoom and persist both display preferences',
    () async {
      SharedPreferences.setMockInitialValues({});
      final settings = Settings();
      final controls = DisplayControlsViewModel(settings: settings);
      settings.fitMainListToWidth.value = true;
      settings.mainListColumns.value = 2;
      settings.userScalingMainList.value = 2.95;
      controls.zoomIn();
      controls.zoomIn();
      expect(settings.userScalingMainList.value, 3);
      expect(controls.canZoomIn, isFalse);
      settings.userScalingMainList.value = 0.25;
      controls.zoomOut();
      controls.zoomOut();
      expect(settings.userScalingMainList.value, 0.2);
      expect(controls.canZoomOut, isFalse);
      controls.toggleOriginalValues();
      await settings.flushPersistence();

      final restored = Settings();
      await restored.loadFromDisk(reconnectOnStartup: false);
      expect(restored.userScalingMainList.value, 0.2);
      expect(restored.noCalculation.value, isTrue);
      expect(restored.fitMainListToWidth.value, isTrue);
      expect(restored.mainListColumns.value, 2);
    },
  );
}
