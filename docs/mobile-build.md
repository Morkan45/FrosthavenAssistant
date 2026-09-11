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

## Windows, Android, and iOS releases

The `Windows, Android, and iOS release` GitHub Actions workflow builds a signed,
release-mode Android APK, a ZIP containing the complete Windows release
directory, and an unsigned iOS release app bundle. It publishes all three files
as assets on a GitHub Release in this fork.
The Windows executable is not Authenticode-signed, so Windows SmartScreen can
warn users until a trusted Windows code-signing certificate is configured.
The iOS ZIP is intended for development and downstream signing; Apple devices
cannot install it until it is signed with an Apple Developer certificate and a
matching provisioning profile.

### Configure Android signing once

Create and securely back up a release keystore. Losing this keystore or its
passwords prevents future APKs from updating an installed copy of the app.

```text
keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

If `keytool` is not on `PATH`, run `flutter doctor -v` to find the Java binary
and use the `keytool` executable from the same JDK. The command prompts for the
keystore and key passwords.

In the fork, open **Settings > Secrets and variables > Actions** and create
these repository secrets:

- `ANDROID_KEYSTORE_BASE64`: the keystore file encoded as Base64.
- `ANDROID_KEYSTORE_PASSWORD`: the keystore password.
- `ANDROID_KEY_ALIAS`: the alias used above (`upload`).
- `ANDROID_KEY_PASSWORD`: the key password.

On PowerShell, copy the Base64 value to the clipboard with:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path .\upload-keystore.jks))) | Set-Clipboard
```

Never commit the keystore or `android/key.properties`. Both paths are ignored
by Git.

### Publish a release

The release tag must match the version name in `pubspec.yaml`. For version
`1.15.1+65`, use tag `v1.15.1`; the `+65` build number is included in asset
file names but not in the tag.

Either push that tag:

```text
git tag v1.15.1
git push origin v1.15.1
```

Or, after the workflow is present on the default branch, open **Actions >
Windows, Android, and iOS release > Run workflow**, select `main`, and enter
`v1.15.1`. A manual run creates the tag at the selected commit if it does not
already exist.

The workflow generates Mockito files before analysis, runs the test suite,
builds all three platforms, and only then publishes the release. Rerunning the
same tag replaces its APK and ZIP assets. Short-lived Actions artifacts are
retained for seven days as a recovery copy.

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

## Release backlog

The following work is intentionally deferred while local manual builds are
used:

- [ ] Create and securely back up a permanent Android release keystore.
- [ ] Configure the four Android signing secrets in the fork.
- [ ] Merge the release workflow into the fork's default branch and publish a
      version tag matching `pubspec.yaml`.
- [ ] Add Authenticode signing for the Windows executable to reduce SmartScreen
      warnings.
