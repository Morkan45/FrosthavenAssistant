# Toolbar and monster interaction improvement plan

Date: 2026-09-12
Status: Complete. Implemented, verified, and packaged for Windows.

## Requested behavior

1. Give the top bar's More actions control a centered circular target and extra
   space before the fire element, including when toolbar scaling is increased.
2. Prevent initiative-list reordering when a gesture starts on a monster's
   standee number or HP. The number opens that standee's condition/status menu;
   HP opens the existing vertical HP slider and retains its precise drag input.
3. Make the ability card and portrait use the same monster turn action, with
   the same eligibility rules. Card taps must no longer open deck selection.
4. Add a clearly labeled ability-deck button beside the condition controls in
   every monster standee's menu. Open that monster type's existing shared deck
   menu, preserving selection, reveal, shuffle, and reorder behavior.
5. Add main-list zoom-out and zoom-in buttons with magnifying-glass minus/plus
   icons. Both buttons and Ctrl+- / Ctrl++ update the existing persisted main
   list scaling setting in 0.1 steps, bounded to its existing 0.2–3.0 range.
   Support the main keyboard and numeric keypad, and avoid handling shortcuts
   while editing text.
6. Add a distinct outlined ability-card icon to the toolbar for original card
   values. Proposed behavior (clarification requested): toggle all currently
   visible ability cards between printed modifiers and calculated totals using
   the existing `noCalculation` setting. Show a selected state and a tooltip
   describing the next action. This is a display preference, not a game action.

## Implementation sequence

- [x] Toolbar: size the More actions hit target explicitly, center its icon,
  and reserve a scaled gap before the elements. Add quick controls at widths
  that accommodate them and an overflow route on narrower toolbars.
- [x] Shared display actions: centralize bounded zoom and original-value toggle
  behavior, persist settings, and rebuild affected views immediately. Reuse
  the same actions from the toolbar and keyboard shortcuts.
- [x] Monster gestures: preserve the existing local eager HP gesture fix;
  protect standee-number input from the ancestor row's immediate/long-press
  drag recognizer while retaining normal menu activation.
- [x] Monster card behavior: route portrait and ability-card taps through one
  turn callback. Remove the card's competing deck/zoom tap gestures so both
  areas respond consistently in every round/turn state.
- [x] Deck menu entry: add a condition-panel button only for monster standees,
  resolve the owning monster and its shared ability deck, and open the existing
  deck menu. Keep character/summon condition layouts compatible.
- [x] Card rendering: subscribe visible cards to the calculation preference so
  changing display mode takes effect without drawing a card or advancing a turn.
- [x] Add focused regression coverage, run analysis and the strict UI viewport
  suite, and record outcomes here. Update relevant manual interaction/shortcut
  descriptions. Produce a Windows release build after verification.

## Code touchpoints

- `frosthaven_assistant/lib/Layout/top_bar.dart`
- `frosthaven_assistant/lib/Layout/global_hotkeys.dart` and display-action model
- `frosthaven_assistant/lib/Layout/MonsterBox/monster_box.dart`
- `frosthaven_assistant/lib/Layout/MonsterWidget/monster_widget.dart`
- `frosthaven_assistant/lib/Layout/MonsterAbilityCardWidget/`
- `frosthaven_assistant/lib/Layout/menus/StatusMenu/`
- Existing localization ARBs/generated localizations and UI/widget tests
- `docs/manual/03-anatomy.html`, `docs/manual/05-round-step-by-step.html`, and
  shortcut references where their descriptions are affected

## Verification criteria

- More actions glyph is centered in its hit target; its circle and fire's
  strong/waning state remain separated at supported toolbar sizes.
- Mouse and touch drags beginning on HP or the number never reorder the list.
  Number taps open the correct standee menu; HP pointer-down displays the slider
  and a deliberate drag changes HP once, with cancellation committing nothing.
- Portrait and ability-card taps perform the same turn transition only when
  allowed; neither opens deck selection. Other row drag areas still reorder.
- Every monster standee exposes the correct shared deck through its condition
  menu, including multiple types sharing a deck; character menus do not gain it.
- Toolbar and keyboard zoom use the same persisted setting and limits; focused
  text inputs remain unaffected. Existing width-fit/column behavior is retained.
- Original-value mode changes rendered modifiers immediately, preserves the
  current card/deck/game state, and stays synchronized with the existing setting.
- English labels and matching localization keys are available, controls have
  tooltips/accessible names, and narrow/desktop/scaled layouts do not overflow.

## Starting state and decisions

The checkout already contains local modifications to the HP slider controller
and its main-list regression test. These changes are relevant and will be
preserved and extended only as needed. Other pre-existing files and generated
artifacts are outside this change.

No version bump is needed for this local improvement build. The original-card
control will use the proposed global toggle unless clarification selects a
separate preview before that part is implemented.

## Implementation results

- More actions has a square, centered target and an 8 × toolbar-scale gap before
  fire. Wide toolbars include zoom-out, zoom-in, and a custom vector ability-card
  icon; narrow toolbars expose the same actions in the overflow menu.
- Zoom uses the persisted scale in 0.1 steps with 0.2–3.0 bounds. Ctrl+=,
  Ctrl++ (including Shift), and numeric keypad +/- are supported. Text editing
  does not consume these shortcuts.
- Original-value mode is the proposed global toggle. It reuses `noCalculation`
  and updates card rule text immediately, with a selected toolbar indicator.
  All localization ARBs include matching keys; new labels use the repository's
  existing English-fallback convention outside English.
- Desktop number clicks eagerly claim the pointer and cancel menu activation
  after a drag. Touch retains its scroll and long-press menu behavior. The
  existing local HP slider fix remains intact.
- Card and portrait taps share the monster turn callback. The former card
  double-tap zoom is removed so the two areas have matching tap behavior.
  Deck browsing is now available next to the conditions in every monster menu.
- Resize verification found transient element-width and standee-height
  overflows. Element targets now reserve their new width immediately; rows do
  not animate between different scales, and standee size animations reset on
  zoom. Normal same-scale row/standee animations remain available.
- Relevant manual sections were updated. Visual review covered wide and narrow
  toolbar layouts, calculated/original card values, and the monster menu.
- Full app suite: **1,778 passed, 1 existing test skipped**.
- Static analysis: `flutter analyze --no-fatal-infos` exits successfully, with
  one pre-existing informational brace-style lint in
  `test/l10n/arb_parity_test.dart:20` and no errors or warnings.
- Strict viewport checks and focused mouse/touch, keyboard, persistence,
  rendering, and resize regressions pass. Screenshot rendering passes after
  explicitly loading the app artwork and Material icon font.
- A local Windows x64 release build succeeded. Its packaged runtime was checked
  against the build directory, including the executable, Flutter DLL, fresh
  `data/app.so`, ICU data, and asset manifest.
