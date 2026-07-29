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

## Performance and maintainability backlog

### P1: Bounded, scalable action history

**Current constraint:** The action log displays 20 descriptions, while undo
retains up to 250 full JSON game-state snapshots. Description and command lists
continue to grow, and selecting an older action repeatedly calls `undo()`. A
500-entry log is cheap; 500 full snapshots and hundreds of sequential restores
are not.

**Proposed change:**

- Introduce a `HistoryEntry` containing index, description, event, timestamp,
  and optional snapshot reference.
- Retain 500 lightweight entries in a ring buffer.
- Make the log a virtualized `ListView.builder` with newest/oldest navigation.
- Add `restoreToHistoryIndex()` that performs one state load, one persistence
  write, one UI refresh, and at most one network broadcast.
- Keep snapshots under an explicit memory budget. Start with a measured bounded
  count, then consider periodic checkpoints plus deltas only if profiling shows
  a benefit.

**Acceptance criteria:** 500 actions are browseable; jumping to any retained
state does not loop through intermediate actions; history memory has a tested
upper bound; low-memory Android hardware remains responsive.

### P1: Serialize persistence writes

**Current constraint:** Every action starts an asynchronous full-state
SharedPreferences write. Rapid input can leave several writes in flight and
does unnecessary work on slower storage.

**Proposed change:** Use a latest-state-wins persistence queue with no more than
one active write and one pending replacement. Flush immediately for app pause,
window close, explicit save, and network role changes.

**Acceptance criteria:** writes cannot complete out of order; rapid action tests
persist the newest state; crash recovery behavior is unchanged.

### P2: Profile state serialization and rebuilds

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

### P2: Clarify command-history and network indexing

**Current constraint:** Commands, descriptions, snapshots, and the network
command index are parallel collections with different baseline offsets. Existing
guards prevent known crashes, but the model remains difficult to reason about.

**Proposed change:** Make one history owner responsible for branching, eviction,
undo/redo availability, and network reconciliation. Replace nullable holes with
explicit retained-index bounds.

**Acceptance criteria:** branch-after-undo, reconnect, stale client, eviction,
and direct rollback are covered by table-driven tests.

### P3: Split high-complexity modules

Prioritize `line_builder.dart`, `modifier_deck.dart`, `game_methods.dart`,
`loot_deck_state.dart`, and `settings_menu.dart`. Extract by existing domain
boundaries, keep public behavior stable, and require focused tests before each
move. Do not combine these splits with feature changes.

## GUI improvement backlog

### P1: Desktop-native list reordering

**Current constraint:** Main-list reordering always requires a long press, which
is discoverable on touch but feels broken with a mouse.

**Proposed change:** On mouse/trackpad platforms, provide an immediate drag
handle and a grab cursor. Keep long-press dragging for touch. Ensure controls
inside a character or monster row remain clickable without starting a reorder.

**Acceptance criteria:** a desktop user can reorder with one press-drag-release;
touch still requires a long press; keyboard users can move the focused row; all
three input modes have widget tests.

### P1: Expand the action log into a history panel

Build this on the bounded-history work above. Use a scrollable virtualized list,
show the current point clearly, disable unavailable future/past actions, and ask
for confirmation only when jumping across a large number of actions. Keep Undo
and Redo as one-step commands.

### P1: Reorganize settings for desktop and mobile

**Current constraint:** Settings is one narrow, long scrolling column even on a
large desktop display. Related display controls are separated from the viewport
they affect.

**Proposed change:** Group settings into Display, Gameplay, Content, Network,
and Advanced views. Use a wider desktop dialog with persistent category
navigation and a single-column mobile presentation. Put main-list scale,
automatic/manual columns, fit-to-width, bar scale, menu scale, and fullscreen in
Display with live preview behavior.

**Acceptance criteria:** no desktop settings view requires scrolling through
unrelated categories; every setting remains available on mobile; current saved
values migrate without reset.

### P2: Make responsive layout controls understandable

Replace the raw column count with an Auto/1/2/3 mode selector. In Auto, keep the
fewest columns that fit vertically and horizontally. In manual modes, cap scale
to the viewport and explain the cap through control state rather than allowing
content to leave the field of view. Add Compact, Default, and Large presets while
retaining the fine-grained scale slider.

### P2: Improve desktop command access

Add consistent hover states and tooltips for icon-only controls, predictable
Escape-to-close behavior, visible keyboard focus, and a compact overflow menu
for infrequent commands. Audit existing shortcuts before assigning new ones so
Undo, Redo, fullscreen, scenario setup, and round progression do not conflict.

### P2: Improve row scanning and targeting

Keep initiative, name, health, conditions, and turn state aligned to stable
columns within each row at every supported scale. Increase the distinction
between selected/current/completed states without relying only on color. Reserve
animation for state changes and avoid layout movement during hover or updates.

### P3: Consolidate visual and interaction tokens

Centralize spacing, target sizes, typography roles, focus/hover states, modal
widths, and responsive breakpoints. Apply this incrementally to the main list,
settings, status menus, and deck views. Preserve the game artwork while making
operational controls visually consistent.

## Recommended implementation order

1. Desktop drag handle with pointer-appropriate behavior.
2. Unified bounded history model and direct rollback.
3. Virtualized 500-action history panel.
4. Settings information architecture and responsive presentation.
5. Layout presets, keyboard/focus audit, and row-alignment refinement.
6. Module splits and measured serialization/rebuild optimizations.

## Verification baseline

For each GUI change, test 1280x720, 1920x1080, and 2560x1440 desktop layouts,
plus a representative phone and tablet viewport. Verify 1-3 columns, minimum and
maximum scaling, mouse and touch input, long localized labels, and a populated
scenario with characters, summons, and multiple monster groups.
