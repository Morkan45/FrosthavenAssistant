# Build and release guide

The supported automation surface is GitHub Actions:

- `flutter.yml` generates code, analyzes, and runs the Flutter suite.
- `server.yml` validates the standalone Dart server.
- `release.yml` builds release artifacts.
- `static.yml` publishes the HTML documentation rooted at `docs/manual/index.html`.

Before a release, run the relevant checks in [testing.md](testing.md), verify
generated localization sources are current, and review the manual locally. The
archived room-data converter is not part of the build or release path.
