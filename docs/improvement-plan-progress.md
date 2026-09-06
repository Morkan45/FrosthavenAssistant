# Improvement plan implementation

The user authorized the full [2026-09-05 improvement plan](codebase-improvement-plan-2026-09-05.md) on 2026-09-05. Implement and validate one item at a time, commit it to the fork, then proceed. The original review remains the design and acceptance reference.

## Progress

| Item | Status | Evidence |
| --- | --- | --- |
| F01 | Complete (2026-09-06) | CI mock generation precedes analysis. Broad overflow/asset filters removed; strict viewport suite, bundled fonts, valid fixture assets, and bounded layout repairs added. Clean source codegen and analysis pass; full suite: 1,693 passed, 1 existing connection test skipped. |
| F02–F15 | Pending | Follow the dependencies and acceptance criteria in the plan. |

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
