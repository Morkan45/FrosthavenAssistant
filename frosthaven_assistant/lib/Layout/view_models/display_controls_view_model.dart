import '../../Resource/settings.dart';
import '../../services/service_locator.dart';

/// Shared toolbar and keyboard actions for local display preferences.
class DisplayControlsViewModel {
  DisplayControlsViewModel({Settings? settings})
    : settings = settings ?? getIt<Settings>();

  static const double minimumScale = 0.2;
  static const double maximumScale = 3.0;
  static const double scaleStep = 0.1;

  final Settings settings;

  bool get canZoomIn => settings.userScalingMainList.value < maximumScale;
  bool get canZoomOut => settings.userScalingMainList.value > minimumScale;

  void zoomIn() => _zoom(scaleStep);
  void zoomOut() => _zoom(-scaleStep);

  void _zoom(double delta) {
    final current = settings.userScalingMainList.value;
    final next = (double.parse(
      (current + delta).toStringAsFixed(3),
    )).clamp(minimumScale, maximumScale);
    if (next == current) return;
    settings.userScalingMainList.value = next;
    settings.saveToDisk();
  }

  void toggleOriginalValues() {
    settings.noCalculation.value = !settings.noCalculation.value;
    settings.saveToDisk();
  }
}
