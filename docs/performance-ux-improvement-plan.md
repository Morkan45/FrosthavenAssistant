# Performance and UX Improvement Plan

## Scope

This review covers the Flutter application and server after the reliability and
responsive desktop layout work. It separates low-risk cleanup from changes that
need profiling, interaction design, or a data-model migration.

## Completed in this review

- Reuse the undo snapshot when sending a network action. Connected actions now
  serialize the full game state once instead of once for history and again for
  transport.
- Evaluate command descriptions and events once per action.
- Dispose transient text, focus, scroll, animation, and value-notifier resources
  owned by menus and list widgets.
- Reuse stable scroll controllers instead of allocating them during `build()`.
- Encode settings with `jsonEncode` so quotes and backslashes in user-entered
  values cannot invalidate all saved settings.
- Add regression coverage for settings containing JSON control characters.
- Make main-list rows immediately draggable with a mouse while preserving
  long-press dragging on touch devices.
- Replace parallel command, description, and snapshot lists with one bounded
  history owner. Retain 500 lightweight entries and at most 251 snapshots.
- Virtualize the action log and restore a selected retained state in one local
  operation and at most one network broadcast.

## Performance and maintainability backlog

### Completed: Bounded, scalable action history

**Previous constraint:** The action log displayed 20 descriptions, while undo
retains up to 250 full JSON game-state snapshots. Description and command lists
continue to grow, and selecting an older action repeatedly calls `undo()`. A
500-entry log is cheap; 500 full snapshots and hundreds of sequential restores
are not.

**Implemented change:**

- Introduce a `HistoryEntry` containing index, description, timestamp, optional
  command, and optional snapshot reference.
- Retain 500 lightweight entries in a ring buffer.
- Make the log a virtualized `ListView.builder` with newest/oldest navigation.
- Add `restoreToHistoryIndex()` that performs one state load, one persistence
  write, one UI refresh, and at most one network broadcast.
- Keep snapshots under an explicit memory budget. Start with a measured bounded
  count, then consider periodic checkpoints plus deltas only if profiling shows
  a benefit.

**Acceptance criteria:** 500 actions are browseable; jumping to any retained
state does not loop through intermediate actions; history memory has a tested
upper bound. Responsiveness on low-memory Android hardware remains a device
validation item.

### Completed: Serialize persistence writes

**Current constraint:** Every action starts an asynchronous full-state
SharedPreferences write. Rapid input can leave several writes in flight and
does unnecessary work on slower storage.

**Proposed change:** Use a latest-state-wins persistence queue with no more than
one active write and one pending replacement. Flush immediately for app pause,
window close, explicit save, and network role changes.

**Acceptance criteria:** writes cannot complete out of order; rapid action tests
persist the newest state; crash recovery behavior is unchanged.

**Implemented change:** Game-state snapshots now pass through a latest-value
queue with at most one active write and one replaceable pending value. App
pause, desktop window close, explicit save, and network role changes await the
queue. Deterministic tests hold a write open and verify that only the newest
pending snapshot reaches storage.

### Completed baseline: Profile state serialization and rebuilds

**Current constraint:** Full-state JSON encoding runs on the UI isolate, and
immutable collection getters copy mutable state on access. The current game
sizes may make this acceptable, so an architectural rewrite is not justified
without measurements.

**Proposed change:** Add benchmarks for snapshot size, action latency, and main
list frame time at representative small, medium, and stress-test scenarios.
Cache immutable views per state revision where repeated copying is measurable.
Move encoding off the UI isolate only if frame timings demonstrate a problem.

**Acceptance criteria:** benchmark fixtures and thresholds are checked in; no
optimization is merged without before/after numbers.

**Implemented change:** Small, medium, and stress fixtures now enforce snapshot
size, serialization, action-latency, and 2560x1440 main-list rebuild budgets.
The first baseline showed serialization and action p95 near 1 ms even for the
stress fixture. An attempted main-list copy reduction was not retained because
repeated rebuild measurements did not show a stable improvement. See
`docs/performance-benchmarks.md` for results and measurement limitations.

### Completed: Clarify command-history and network indexing

**Previous constraint:** Commands, descriptions, snapshots, and the network
command index are parallel collections with different baseline offsets. Existing
guards prevent known crashes, but the model remains difficult to reason about.

**Implemented change:** One history owner is responsible for branching, eviction,
undo/redo availability, and network reconciliation. Replace nullable holes with
explicit retained-index bounds.

**Acceptance criteria:** branch-after-undo, reconnect, stale client, eviction,
and direct rollback are covered by table-driven tests.

### P3: Split high-complexity modules

Prioritize `line_builder.dart`, `modifier_deck.dart`, `game_methods.dart`,
`loot_deck_state.dart`, and `settings_menu.dart`. Extract by existing domain
boundaries, keep public behavior stable, and require focused tests before each
move. Do not combine these splits with feature changes.

**Progress:** `settings_menu.dart` now owns only state, keyboard behavior, and
orchestration. Responsive desktop/mobile layout and page construction live in
separate modules, with the existing focused settings suite covering both modes.
The remaining prioritized modules stay in the backlog for similarly scoped
extractions.

## GUI improvement backlog

### Completed for pointer and touch: Desktop-native list reordering

**Previous constraint:** Main-list reordering always required a long press, which
is discoverable on touch but feels broken with a mouse.

**Implemented change:** Mouse/trackpad platforms use immediate dragging and a
grab cursor. Touch retains long-press dragging.

**Acceptance criteria:** a desktop user can reorder with one press-drag-release
and touch still requires a long press. Keyboard reordering remains a follow-up.

### Completed core: Expand the action log into a history panel

The action log now uses a scrollable virtualized list of up to 500 entries,
marks the current point, disables entries whose snapshots have expired, and
performs direct confirmed rollback. Undo and Redo remain one-step commands.

### Completed: Reorganize settings for desktop and mobile

**Previous constraint:** Settings was one narrow, long scrolling column even on a
large desktop display. Related display controls are separated from the viewport
they affect.

**Implemented change:** Settings are grouped into Display, Gameplay, Content,
Network, and Advanced sections. Desktop uses a wider dialog with persistent
category navigation and independently scrolling content. Mobile and tablet keep
all sections in one scrollable column. Display now includes main-list scale,
automatic/manual columns, fit-to-width, bar scale, menu scale, fullscreen,
language, theme, and visual style.

**Acceptance criteria:** no desktop settings view requires scrolling through
unrelated categories; every setting remains available on mobile; current saved
values migrate without reset.

### Completed: Make responsive layout controls understandable

The raw column dropdown is now an Auto/1/2/3 segmented selector. Auto keeps the
fewest columns that fit vertically and horizontally, while manual modes retain
the viewport scale cap. Compact, Default, and Large presets adjust the main
list, app bars, and menus together while retaining all fine-grained sliders.

### Completed: Improve desktop command access

Add consistent hover states and tooltips for icon-only controls, predictable
Escape-to-close behavior, visible keyboard focus, and a compact overflow menu
for infrequent commands. Audit existing shortcuts before assigning new ones so
Undo, Redo, fullscreen, scenario setup, and round progression do not conflict.
Settings closes predictably with Escape and participates in focus traversal.
Focused main-list rows have a visible outline and can be reordered with
Alt+Up/Down. The top-bar menu is keyboard operable, element controls expose
localized tooltips and hover/focus states, and wide desktop layouts provide a
compact overflow menu for Action Log, Settings, and Fullscreen.

### Completed: Improve row scanning and targeting

Character rows now keep icon, initiative, and character details in stable
tracks at every supported scale. Names remain on one line and condition icons
fit within the details track instead of shifting later content. Current and
completed rows add play/check markers alongside the existing color and grayscale
treatment, while keyboard focus remains a separate full-row outline. None of
these states changes row geometry.

### Completed foundation: Consolidate visual and interaction tokens

Centralize spacing, target sizes, typography roles, focus/hover states, modal
widths, and responsive breakpoints. Apply this incrementally to the main list,
settings, status menus, and deck views. Preserve the game artwork while making
operational controls visually consistent.

**Implemented change:** A structured token layer now owns the shared spacing
scale, compact targets, typography roles, focus/hover treatment, card radii,
modal dimensions, and desktop breakpoints. Legacy constants remain compatible.
The first migration covers the main-list focus outline, settings layouts,
shared menu cards, status spacing, top-bar interaction states, and loot/modifier
deck stack radii without changing their existing numeric values.

## Recommended implementation order

1. Desktop dragging with pointer-appropriate behavior. Completed.
2. Unified bounded history model and direct rollback. Completed.
3. Virtualized 500-action history panel. Core completed.
4. Settings information architecture and responsive presentation. Completed.
5. Layout presets, desktop command access, and row alignment. Completed.
6. Module splits and measured serialization/rebuild optimizations.

## Verification baseline

For each GUI change, test 1280x720, 1920x1080, and 2560x1440 desktop layouts,
plus a representative phone and tablet viewport. Verify 1-3 columns, minimum and
maximum scaling, mouse and touch input, long localized labels, and a populated
scenario with characters, summons, and multiple monster groups.
