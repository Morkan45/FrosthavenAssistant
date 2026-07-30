# Performance Benchmarks

## Purpose

The checked-in benchmark tests catch large regressions in state size,
synchronous JSON serialization, full action handling, and main-list rebuilds.
They use the same loaded test data and commands as the application.

Run them from `frosthaven_assistant`:

```powershell
flutter test test\performance\performance_budget_test.dart --reporter expanded
```

## Fixtures

| Fixture | Characters | Monster groups | Standees per group | Summons |
| --- | ---: | ---: | ---: | ---: |
| Small | 1 | 1 | 1 | 0 |
| Medium | 4 | 5 | 2 | 1 |
| Stress | 4 | 5 | 10 | 12 |

## Windows Debug Baseline

Measured on 2026-07-30 using the Flutter test runner. Times are p95 values.

| Fixture | Snapshot | Serialization | Action | Main-list rebuild |
| --- | ---: | ---: | ---: | ---: |
| Small | 3,557 bytes | 0.50 ms | 0.55 ms | 34.63 ms |
| Medium | 10,981 bytes | 0.42 ms | 0.62 ms | 99.32 ms |
| Stress | 24,131 bytes | 0.85 ms | 0.63 ms | 147.21 ms |

The debug widget rebuild measurement is a regression proxy, not a production
frame-time claim. Asset decoding, test instrumentation, JIT warm-up, and host
load make it substantially noisier than a release/profile build on a target
device. Release-mode desktop and low-memory Android validation remains a device
test item.

## Optimization Decision

A trial changed the main-list build path to reuse one immutable list view per
rebuild. The first post-change run was faster for small and medium fixtures, but
the stress p95 varied from 152 ms to 213 ms versus the 146 ms baseline. Because
that was not a stable improvement, the production change was removed. Full
state encoding should remain on the UI isolate until profile-mode frame timing
shows that it is a user-visible bottleneck.
