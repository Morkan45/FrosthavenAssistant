# Mobile fork builds

The fork uses app version `1.15.1+65` and application identifier
`com.morkan45.xhavenassistant`. This keeps development builds separate from the
official X-haven Assistant installation.

## Android

Build an installable test APK from Windows, macOS, or Linux:

```text
cd frosthaven_assistant
flutter pub get
flutter build apk --debug
```

The APK is written to
`build/app/outputs/flutter-apk/app-debug.apk`.

## iPhone

An iPhone build requires macOS, Xcode, and an Apple signing team. The GitHub
Actions mobile smoke workflow compiles the iOS release without code signing,
which verifies the project but does not produce an app that can be installed on
an iPhone.

To run on a physical iPhone:

1. Clone the fork on a Mac and run `flutter pub get` in
   `frosthaven_assistant`.
2. Open `ios/Runner.xcworkspace` in Xcode.
3. Select the Runner target, choose your Apple team under Signing &
   Capabilities, and let Xcode manage signing automatically.
4. Connect and trust the iPhone, select it as the run destination, and run the
   Runner target.

The bundle identifier is already unique to this fork. Change it in Xcode if it
is not available for the selected Apple team.
