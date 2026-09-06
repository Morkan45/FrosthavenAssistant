# Verification

Run commands from `frosthaven_assistant` in this order on a clean checkout:

```sh
flutter pub get
dart run build_runner build
flutter analyze --no-fatal-infos
flutter test --concurrency=4
```

Mockito output is ignored by Git, so generation must precede analysis as well as tests. The Flutter CI workflow follows this order before its platform build and test steps. The reviewed local baseline uses Flutter 3.44.8 / Dart 3.12.2.

`flutter analyze` runs Dart analysis and the configured `flutter_lints` rules. The `dart_code_metrics` section in `analysis_options.yaml` is historical configuration: installing `dart_code_metrics_presets` does not run DCM, and no workflow currently invokes a DCM executable. Do not describe those rules as a CI gate.

Run the strict UI matrix with `flutter test test/strict_ui`. It renders a mixed character/monster list and status/settings dialogs at 360×800, 800×1280, 1280×720, 1920×1080, and 2560×1440, plus explicit one-, two-, and three-column layouts. The fixture uses bundled fonts and images. Negative controls deliberately generate an overflow and a missing image and assert that Flutter reports each error; all ordinary view tests require no framework exceptions.

Do not install broad `FlutterError.onError` filters for layout or asset errors. Correct fixture paths and load the app's fonts before evaluating layout. Intentional error tests must consume and assert the specific expected exception locally. Text scaling at 150/200%, physical screen readers, and profile-mode performance have separate acceptance criteria in the improvement plan; passing this matrix does not certify them.

For comparable performance results, run `flutter test test/performance --concurrency=1` separately from other tests and analysis. Widget-test timings are debug measurements and do not certify profile-mode frame performance on target devices.
