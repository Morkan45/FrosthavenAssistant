# Windows performance baseline — 2026-09-11

Measured with the deterministic Flutter performance fixture on this Windows
workspace. Each state operation uses 30 samples after five warm-up iterations;
main-list rebuilds use 15 samples after three warm-up rebuilds at 2560×1440.
The fixture does not enable the `show_fps` overlay.

| Scenario | Snapshot bytes | Serialization p95 | Action p95 | Main-list rebuild p95 |
| --- | ---: | ---: | ---: | ---: |
| Small | 3,577 | 413 µs | 358 µs | 26.177 ms |
| Medium | 11,071 | 671 µs | 553 µs | 82.022 ms |
| Stress | 24,221 | 568 µs | 688 µs | 115.407 ms |

The state operations are well below their fixture budgets. The medium and
stress rebuild measurements exceed a 16.7 ms 60 Hz discussion target, so any
future virtualization or rebuild-scope experiment should compare against this
baseline and report the same fixture. Android-device profiling is intentionally
deferred because no Android device is available.

Run: `flutter test test/performance/performance_budget_test.dart --concurrency=1 --reporter=expanded`.
