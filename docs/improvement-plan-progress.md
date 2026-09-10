# Improvement plan implementation

The user authorized the full [2026-09-05 improvement plan](codebase-improvement-plan-2026-09-05.md) on 2026-09-05. Implement and validate one item at a time, commit it to the fork, then proceed. The original review remains the design and acceptance reference.

## Progress

| Item | Status | Evidence |
| --- | --- | --- |
| F01 | Complete (2026-09-06) | CI mock generation precedes analysis. Broad overflow/asset filters removed; strict viewport suite, bundled fonts, valid fixture assets, and bounded layout repairs added. Clean source codegen and analysis pass; full suite: 1,693 passed, 1 existing connection test skipped. |
| F02 | Complete (2026-09-06) | Shared synchronous received transitions, detached validation, immediate per-index snapshots, completed-transition UI revision, and mismatch branch invalidation. Analysis passes; full suite: 1,704 passed, 1 existing connection test skipped. |
| F03 | Complete (2026-09-08) | Validated settings codec, latest-value persistence with observable/retryable failure, protected corrupt-save recovery, staged startup, desktop close recovery, and guarded role changes. Analysis passes; full suite: 1,746 passed, 1 existing connection test skipped. |
| F04 | Complete (2026-09-08) | Standalone server retains a bounded, byte-capped absolute-index history; evicted rollback receives an authoritative correction. Socket/health cleanup is idempotent and safe during broadcast. Server analysis passes; 14 server tests pass. |
| F05 | Complete (2026-09-10) | The app no longer excludes its accessibility tree or overrides system text scale. Core Draw/Next round, scenario level, initiative, health, and element controls provide accessible labels, values, and actions. Phone shell passes 100/150/200% system text tests; analysis passes; full suite: 1,750 passed, 1 existing connection test skipped. |
| F06 | Complete (2026-09-10) | A shared, group-aware `ColumnPlan` now keeps each target and its linked notes in the same `ReorderableWrap` column, and the automatic layout fit check uses the identical plan. Focused layout tests: 29 passed; analysis passes; full suite: 1,752 passed, 1 existing connection test skipped. |
| F07 | In progress | The first concrete injection defect is fixed: `UnlockSpecialCommand` now mutates its injected game state, with a two-state isolation regression test. The scenario/round pilot remains. |
| F08–F15 | Pending | Follow the dependencies and acceptance criteria in the plan. |

## Decisions pending

- F11: Android profiling skipped by user decision (no Android device available). Windows profiling remains in scope.
- F14: user delegated the maintain/archive decision to the implementation agent; decide from actual usage and source quality.
- F15: recommended artifact is the existing `docs/manual` HTML manual with `docs/screenshots/manual`; user asked which manual and has been given its location.
- Physical screen reader checks and the five-person usability exercise require external participation; automated tests cannot certify those outcomes.

## Baseline

Work started on `codex/windows-android-releases`, HEAD `f73e6e2c`, with `origin` pointing to the Morkan45 fork. The four character-health files reported as modified had no content diff after Git line-ending normalization; the substantive health changes were already in HEAD. Existing untracked artifacts, worktrees, and screenshot tooling are outside the implementation commits.

## F01 verification notes

Removing global exception filters exposed fixture assets that did not exist and real layout constraints. Tests now use bundled fonts and valid loot images. The synthetic boss fixture uses plain `damage` to match the existing Frosthaven conversion grammar; already-tokenized `%damage%` is double-expanded by that converter and remains a specific F12 robustness case.

Layout repairs keep operational controls reachable through flexible labels, wrapping, and scrolling. Card rule rows and boss stat graphics scale down only to fit their existing graphical bounds. The bottom bar preserves Draw/modifier control sizes and placement while fitting its center details.

The strict suite covers five viewports with a mixed character/monster board, status/settings dialogs, explicit 1–3 character columns, and negative controls for overflow/missing images. 200% phone text still exposes status/settings layout issues and remains F05 work, not a passing F01 claim.

The final verification uses `artifacts/f01-clean-source`, copied only from versioned source paths plus the new strict test and documentation, without generated mocks, `.dart_tool`, or build output. Local logs are `artifacts/f01-clean-{pub-get,codegen,analyze,test}.log`; large generated verification artifacts are not versioned.

## F02 transition contract

Client and Flutter host apply accepted states synchronously through `applyReceivedTransition`. A detached graph validates the incoming snapshot before live notifier-backed objects are updated. Each accepted index receives its own exact snapshot and persistence is queued immediately. History UI listens for the completed transition revision, including same-index corrections.

Ordinary host rollback preserves redo history. An explicit `Mismatch:` correction discards the rejected future branch; the next received step starts a new branch. Invalid client state is rejected by the host without consuming an index or broadcasting. A client receiving invalid server state disconnects while retaining its last accepted state and history. The 100 ms client snapshot callback has been removed.

Validation targets include two envelopes in one fake-clock tick, disconnect/reset, late malformed data and nested figure identity, host plus two wire clients, mismatch/rollback/retry, and a mounted history panel that can restore the earlier received state. Full observer atomicity and a versioned save codec remain outside F02.

## F03 persistence and recovery contract

Settings are decoded completely before application. Missing or invalid individual fields use constructor defaults, preserving platform defaults. Scale limits match the existing controls: main list 0.2–3, bars 0.8–3, menus 0.7–1.5; columns accept 0–3, and enum/locale values must be supported. Invalid save-map fields use an empty map. Malformed JSON or a non-object root is a recoverable load failure, and saving is refused until a successful read or an explicit reset. The JSON format is unchanged.

Settings and game writes retain the latest pending value, serialize disk access, and expose writing/error status. Explicit save/flush reports thrown errors and rejected writes, including an already-settled failed write. A successful later write clears the status. Background scheduling owns error futures; Retry retains the latest failed snapshot. A batch containing a failed write reports failure to its awaiters even if its later pending write succeeds.

Startup renders game controls only after required initialization succeeds. Retry preserves completed stages; reset removes only the affected preference. Reset settings also removes named game and character saves, which the recovery screen explains. Reconnection and shortcuts cannot run while recovery is pending. Address discovery stays in the background so internet access is not a startup prerequisite.

Network policy: starting a client or host requires successful game and settings persistence; rejected endpoint changes are restored and replaced in the settings queue. Stopping an active client or host is always allowed. Desktop close captures the current state and offers Retry, Close anyway, or Cancel on failure. Mobile/background lifecycle callbacks make a best-effort save attempt and report failures; they cannot guarantee completion before the operating system terminates the app.
