# Text Assist — PRD v7: Picker v3 (cascading sections)

**Draft** — Turn the flat 16-row style list into four sections that slide out to the
right, drive the whole menu from the keyboard, and cut the catalogue down to the styles
that are actually used.

| | |
|:--|:--|
| Status | Draft for review |
| Builds on | PRD v2 (implemented); supersedes the picker parts of PRD v6 and Epic #82 |
| Platform | macOS 13+, Swift 5 language mode, SwiftUI + AppKit, `MainActor` default |
| Testing | **None.** Verification is "builds + manual check in the running app" |
| Milestone | **M8 — Picker v3** (M6 = PRD v3, M7 = PRD v6) |
| Task prefix | **MN** (MN1–MN7) |

**Purpose.** The picker opens as one 240pt column with sixteen rows in four groups. It is
long, it shows styles nobody picks, and it can only be driven by pressing a style's
single-character key. This PRD turns it into a **two-level cascading menu**: four sections
in the root column, each section's styles in a column that slides out to the right. `↑`/`↓`
move, `→`/`Return` open and run, `←` goes back, `esc` dismisses. Seven unused styles are
retired from the catalogue and Custom Prompt is hidden, both without deleting any code.

Behaviour of the styles themselves does not change. This is the menu's structure and
input model only.

---

## 1. Summary

1. **Root column**: `Transform ›`, `Write ›`, `Chat ›`, `Translations ›`. Nothing else.
2. **Section column** slides out to the right on hover, click, or `→`, showing only that
   section's styles; it mirrors to the left near the screen edge.
3. **Keyboard navigation** becomes the primary input: arrows + `Return` + `←` + `esc`,
   with the current row highlighted. The single-character keys survive as accelerators
   but stop being the only way in.
4. **Catalogue cut**: Transform keeps Short Summary, Bullet Points, ELI5, Chat Thread;
   Write keeps Fix Grammar, Improve Writing, Professional Tone; Chat keeps Chat with
   Selection; Translations keeps the two PRD v6 entries. Detailed Summary, Key Takeaways
   & Action Items, Friendly/Casual/Confident tone, Shorter and Longer leave the menu.
5. **Custom Prompt is hidden, not deleted.** Its style, panel and view stay in the code
   behind one flag, re-enabled with a one-line change.

---

## 2. Goals, non-goals, success criteria

### Goals

- `⌥⇧S` opens a four-row menu; every style is at most two keystrokes away.
- The whole picker is operable without touching the mouse: move, open, run, back, dismiss.
- The catalogue matches what people actually use, so the menu stops being a wall of text.
- No style is deleted from the codebase; retirements are a catalogue change.
- Zero regression in what a style does: the same prompts, the same popups, the same
  Replace/Diff/Copy behaviour, the same direct-action hotkeys.

### Non-goals

- Restyling. Panel chrome, colors, typography and radii belong to PRD v3 (Epic P). This PRD
  builds the structure with today's system styling; P5 restyles it afterwards.
- Reordering or rewording the prompts of any style.
- User-editable sections, pinning favourites, or reordering rows. (Open question 3.)
- The menu-bar dropdown (`MenuBarStatusView`) — unchanged.
- Search/filter ("type to filter styles"). (Open question 2.)
- New global hotkeys. `⌥⇧S`, `⌥⇧C` and `⌥⇧G` stay as they are.

### Success criteria (manual)

| # | Check | Expected |
|:--|:--|:--|
| 1 | `⌥⇧S` with text selected | A four-row menu: Transform, Write, Chat, Translations |
| 2 | Hover **Transform** | A second column slides out to the right listing 4 styles, top-aligned |
| 3 | Click **Bullet Points** | Popup streams bullets; the menu is gone |
| 4 | `⌥⇧S` → `↓` `↓` `→` `↓` `Return` | Improve Writing runs (third section, second item) — no mouse |
| 5 | `⌥⇧S` → `→` then `←` | The section column closes, root keeps its highlight |
| 6 | `⌥⇧S` → `esc` | Everything closes, nothing runs, focus returns to the source app |
| 7 | Near the right screen edge, open a section | The section column renders to the left of the root and stays fully visible |
| 8 | Scan the menu | No Detailed Summary, Key Takeaways, tone styles, Shorter, Longer, or Custom Prompt |
| 9 | `⌥⇧G` while focused elsewhere | Fix Grammar still runs directly, skipping the picker |
| 10 | Translate a Dutch paragraph (`t` twice) | Translates — the Translations section is wired to PRD v6's styles |

---

## 3. Current state of the repo (read first)

### 3.1 What the picker is today

```
⌥⇧S → SummarizationOrchestrator.startSummarization()
        → TextCaptureService.captureSelection()
        → StylePickerPanel.show()                     ← KeyablePanel, borderless + nonactivating
             StylePickerView(styles: styleStore.styles, …)
               group "TRANSFORM"  1 Short Summary · 2 Bullet Points · 3 Detailed Summary
                                  4 Key Takeaways & Action Items · 5 ELI5 · 6 Chat Thread
               group "WRITE"      g Fix Grammar · i Improve Writing · p Professional tone
                                  f Friendly · c Casual · o Confident · s Shorter · l Longer
               group "CHAT"       a Chat with Selection
               row   Custom Prompt (0)
               row   esc Cancel
```

- One column, `.frame(width: 240)`, sized by `hostingController.view.fittingSize`
  ([StylePickerPanel.swift](../../TextAssist/UI/StylePicker/StylePickerPanel.swift)).
- Grouping is a `private struct PickerGroup` computed inside
  [StylePickerView.swift](../../TextAssist/UI/StylePicker/StylePickerView.swift) from
  `style.category`; `custom` renders untitled after a `Divider`.
- **There is no selection state.** Each row is a `Button` carrying
  `.keyboardShortcut(KeyEquivalent(Character(style.shortcutKey)), modifiers: [])`, so the
  only way in is pressing that character or clicking. `Esc` works through a hidden
  `.cancelAction` button row.
- The panel is centred on the cursor and clamped into `screen.visibleFrame`; there is no
  notion of a second column, a preferred opening side, or a stable anchor.
- Routing is by `category` in
  [SummarizationOrchestrator.swift](../../TextAssist/Core/SummarizationOrchestrator.swift):
  `.chat` opens `ChatPopup`, the `customPrompt.id` id opens `CustomPromptPanel`, everything
  else streams into `SummaryPopup`. The popup's style switcher is fed
  `styles.filter { $0.category == .transform || $0.category == .write }` (two call sites,
  `showSummaryPopup` and `reopen`).
- `SummaryPopupViewModel.isWriteMode` is `category == .write` and gates **both** the Diff
  view and Replace's availability.

### 3.2 Why the catalogue is being cut

Every row costs attention on every open, and only a handful are ever picked. The seven
styles being retired either overlap a kept style (Detailed Summary vs Short Summary,
Shorter/Longer vs Improve Writing) or were speculative tone presets nobody reached for
(Friendly, Casual, Confident). Key Takeaways did not earn its slot next to Bullet Points.

Custom Prompt is different: it is a *mechanism* (a free-text instruction panel) rather
than a preset, and it is the one thing that makes the app open-ended. It is hidden so the
menu stays short, not because it is broken.

### 3.3 What this PRD reuses

| Component | Reuse |
|:--|:--|
| `SummaryStyle`, `StyleStore` | One new layout property; catalogue ordered in one place. No persistence change. |
| `KeyablePanel`, `StylePickerPanel` | Still one borderless non-activating panel — it just gets wider. `cancelOperation` already gives us `esc`. |
| `SummaryPopup`, `ChatPopup`, `CustomPromptPanel` | Untouched, except the popup's replace/diff capability check. |
| `HotkeyManager` direct actions | Unchanged; all three styles they reference survive the cut. |

---

## 4. Target experience

### 4.1 Flow

```
⌥⇧S → capture → picker (one panel, one column)
                  ┌──────────────────────┐
                  │ Transform          › │──┐  hover / click / →
                  │ Write              › │  │
                  │ Chat               › │  │   ┌────────────────────────┐
                  │ Translations       › │  └──►│ TRANSFORM              │
                  │──────────────────────│      │  Short Summary      ✓  │
                  │ ↑↓ move · ⏎ run · esc│      │  Bullet Points         │
                  └──────────────────────┘      │  ELI5                  │
                                                │  Chat Thread           │
                                                │────────────────────────│
                                                │ ↑↓ move · ← back · ⏎   │
                                                └────────────────────────┘
```

The two columns are **one panel**, not two windows: the panel widens from 240pt to 461pt
when a section opens. See D-1 for why.

### 4.2 Root column

```
┌──────────────────────┐
│ Transform          › │
│ Write              › │
│ Chat               › │
│ Translations       › │
│──────────────────────│
│ ↑↓ move · ⏎ run · esc│
└──────────────────────┘
```

- Four rows, one per non-empty section, in fixed order: Transform, Write, Chat,
  Translations. A section whose style list is empty is not rendered — so this PRD is
  correct whether or not PRD v6 has landed.
- A section containing the last-used style shows a small dot after its title, so the user
  can find "where I was" in one glance. The checkmark stays on the style row itself.
- No shortcut columns, no counts, no dividers between rows.

### 4.3 Section column

```
┌────────────────────────┐
│ TRANSFORM              │   ← section title, same uppercase caption style as today
│  Short Summary      ✓  │
│  Bullet Points         │
│  ELI5                  │
│  Chat Thread           │
│────────────────────────│
│ ↑↓ move · ← back · ⏎   │
└────────────────────────┘
```

- Rendered only while a section is open. Width 220pt; top-aligned with the root column.
- Rows show name only (plus the last-used checkmark). **The single-character key is no
  longer rendered** — it is an accelerator, not the instruction.
- A section may carry one footer note under its rows: Translations shows
  `Chat answers in English`, and PRD v6's model warning appears here when applicable.
- Hovering a row selects it (same highlight as keyboard selection — never two highlights).
  Clicking a row runs it. Clicking the same section row again closes the column.

### 4.4 Opening side and growth

- The panel's **left edge is fixed** at the origin chosen when it opens, positioned so the
  root column sits where today's picker would.
- A section column opens to the **trailing** side by default. If
  `rootWidth + divider + submenuWidth` would leave the screen's `visibleFrame`, the column
  renders on the **leading** side instead, and the panel's left edge shifts left by that
  width so the root column does not move under the cursor.
- The panel is positioned with its top-left at the anchor and grows **downward and to the
  side**; it is never re-centred on the cursor after opening.
- Opening animation: the section column slides in from the divider edge and fades over
  120 ms while the panel width animates to its new size. Under
  `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` the column appears
  immediately. A plain appearance without the tween is an acceptable fallback if the
  window-resize animation flickers on macOS 13 — record which shipped in the handoff.

### 4.5 Keyboard model

One `focus` value: `.root` or `.submenu`.

| Focus | Key | Action |
|:--|:--|:--|
| root | `↓` / `↑` | Move the section highlight; wraps at both ends |
| root | `→` or `Return` | Open the highlighted section and move focus into it |
| root | `←` | No-op |
| root | `1`–`4` | Open that section (fourth = Translations) and focus it |
| root | any style's accelerator letter | Run that style immediately, from any level |
| submenu | `↓` / `↑` | Move the style highlight; wraps |
| submenu | `Return` or `→` | Run the highlighted style |
| submenu | `←` | Close the column, focus back to root |
| either | `esc` | Dismiss the whole picker (`KeyablePanel.cancelOperation`, unchanged) |

- Initial state: root focused; the highlight is the section containing `lastUsedStyleID`,
  else Transform. Opening a section highlights the last-used style when it belongs to that
  section, else its first row.
- `esc` **always closes everything**, at either level — matching every other window in the
  app (issues #65–#67). `←` is the way back one level.
- Accelerators are swallowed when they match and ignored (passed through) otherwise.
  Any key pressed with `⌘`/`⌥` is passed through untouched, so `⌘W`, `⌘Q` and the global
  hotkeys keep working.
- Arrow auto-repeat must move smoothly; holding `↓` may not skip rows or crash.
- VoiceOver: the highlighted row carries `.isSelected`; section rows are buttons named
  `"<Section> section"`; the list column is exposed with `.accessibilityElement(children:)`.

### 4.6 Mouse

- Hovering a root row opens its section after 120 ms of hover intent (a short delay keeps
  the column from flickering while the pointer travels diagonally toward it). Hovering a
  different root row swaps the open column's contents in place.
- Once the pointer is inside the section column it stays open; moving the pointer out of
  both columns does **not** close it (only a new section hover, a click, `←`, `esc` or an
  outside click does). This avoids the "menu vanishes on the way to it" failure.
- Clicking outside the panel closes the picker, as `NSPanel` already does.

---

## 5. Requirements

### 5.1 Structure

- **MN-FR1** The root column renders exactly the non-empty sections in the order
  Transform, Write, Chat, Translations. No style rows at the root.
- **MN-FR2** A section's styles render only in its section column; every style appears in
  exactly one section.
- **MN-FR3** Section membership is declared on the style (`SummaryStyle.section`), not
  inferred from `category`, so a style can live in Translations and still open the chat
  popup.
- **MN-FR4** The picker is still a single borderless, non-activating `KeyablePanel`; no
  second window, and the source app stays frontmost so Replace keeps working.
- **MN-FR5** The panel widens with the section column, keeps its left edge fixed, and
  mirrors the column to the leading side when the trailing side would leave
  `screen.visibleFrame`. It is never clipped and never re-centred after opening.
- **MN-FR6** The section column animates in over ≈120 ms, and appears instantly under
  Reduce Motion.

### 5.2 Keyboard

- **MN-FR7** `↑`/`↓` move a single highlight within the focused column, wrapping at both
  ends, and repeat while held.
- **MN-FR8** `→`/`Return` open a section or run a style, depending on the focused column;
  `←` closes the section column and returns focus to the root.
- **MN-FR9** `esc` dismisses the picker from either column, using the existing
  `KeyablePanel.cancelOperation` path (including its IME guard).
- **MN-FR10** `1`–`4` open a section; every style's accelerator letter runs it from any
  level. Accelerator letters are unique across the whole catalogue, digits are unique
  across sections, and a `#if DEBUG` assertion fails the build-preview if either is
  violated.
- **MN-FR11** Key handling ignores events carrying `⌘` or `⌥`, and the monitor is removed
  whenever the panel closes, so no other panel or window inherits the keys.
- **MN-FR12** Mouse hover and keyboard share one selection; only one row is highlighted at
  any time, and hovering never fires an action.

### 5.3 Catalogue

- **MN-FR13** The shipped catalogue is exactly:

  | Section | Key | Style |
  |:--|:--|:--|
  | Transform (`1`) | `s` | Short Summary |
  | | `b` | Bullet Points |
  | | `e` | ELI5 |
  | | `h` | Chat Thread |
  | Write (`2`) | `g` | Fix Grammar |
  | | `i` | Improve Writing |
  | | `p` | Professional Tone |
  | Chat (`3`) | `a` | Chat with Selection |
  | Translations (`4`) | `t` | Translate to English |
  | | `c` | Chat about this text |

- **MN-FR14** Retired from the menu, **retained in code** in `SummaryStyle.retired` with a
  comment: Detailed Summary, Key Takeaways & Action Items, Friendly tone, Casual tone,
  Confident tone, Shorter, Longer.
- **MN-FR15** Custom Prompt is not rendered anywhere in the picker, while
  `SummaryStyle.customPrompt`, `CustomPromptPanel`, `CustomPromptView` and the
  orchestrator's custom-prompt branch stay intact behind one flag.
- **MN-FR16** A stored `lastUsedStyleID` that is no longer in the catalogue is replaced at
  load time by the first catalogue style, so the checkmark and starting highlight always
  resolve.
- **MN-FR17** A history entry whose style was retired still opens: `reopen` already falls
  back to Short Summary; the popup must not dead-end, and Regenerate must work.
- **MN-FR18** Any plain-text style (Write and Translate) gets Diff and Replace in the
  popup. Capability is no longer inferred from `category == .write`.

### 5.4 Documentation

- **MN-FR19** The picker's doc comments describe the sections, the keys, and the catalogue
  rule; `README.md`'s usage step describes the two-level menu instead of "choose an
  action".

---

## 6. Copy deck (exact strings)

| Key | String |
|:--|:--|
| Section · transform | `Transform` |
| Section · write | `Write` |
| Section · chat | `Chat` |
| Section · translations | `Translations` |
| Section column header | the section name, uppercased |
| Root hint | `↑↓ move · ⏎ run · esc close` |
| Section hint | `↑↓ move · ← back · ⏎ run` |
| Translations note | `Chat answers in English` (PRD v6 §6.3) |
| Accessibility · section row | `"Transform section"`, `"Write section"`, … |
| Accessibility · hint | `"Use the arrow keys to move, Return to choose, Escape to close"` |

The `esc Cancel` row disappears; the hint replaces it.

---

## 7. Technical design

### 7.1 Models

```swift
// Models/StyleSection.swift (new)
/// A top-level group in the picker. Membership is explicit on each style.
enum StyleSection: String, CaseIterable, Identifiable, Sendable {
    case transform, write, chat, translations

    var id: String { rawValue }
    var title: String { … }        // "Transform", "Write", "Chat", "Translations"
    var accelerator: Character { … } // "1", "2", "3", "4"
}

/// A rendered section: its styles, in order, plus an optional footer note.
struct StyleSectionGroup: Identifiable {
    let section: StyleSection
    let styles: [SummaryStyle]
    let note: String?
    var id: String { section.id }
}
```

```swift
// Models/SummaryStyle.swift (edit)
/// Picker section this style appears in. Layout only — routing still uses `category`.
var section: StyleSection = .transform
```

`category` keeps its present meaning (`.chat` → chat popup, `.custom` → custom panel,
`.write`/`.transform`/`.translation` → result popup). Keeping the two axes separate is
deliberate (D-2): PRD v6's "Chat about this text" is `category: .chat` but belongs to the
Translations section, and that combination is only expressible with two properties.

Catalogue construction lives in one place:

```swift
enum StyleCatalog {
    /// Styles shown in the picker, in render order, grouped by section.
    static func groups(from styles: [SummaryStyle]) -> [StyleSectionGroup]

    /// Whether the hidden Custom Prompt row is offered. Flip to `true` to restore it.
    static let showsCustomPrompt = false
}
```

`SummaryStyle.builtIn` becomes the curated ten-style list of MN-FR13. The retired seven
move to `SummaryStyle.retired` (same file, no other call sites) so they stay compilable and
re-enable by moving one line. `ShortcutKey` values are reassigned per MN-FR13; the retired
styles keep their old keys, which now collide with live ones but are never read.

`StyleStore` gains the MN-FR16 migration in `init` and a `groups` convenience property, and
`StylePickerView`/`StylePickerPanel` stop filtering by category.

### 7.2 View structure

```
KeyablePanel
 └─ NSHostingController → StylePickerView
      HStack(alignment: .top, spacing: 0) {
        rootColumn        // 240pt: 4 section rows + hint bar
        if let open { Divider(); sectionColumn.frame(width: 220) }
      }
```

- `StylePickerView` gains `@ObservedObject var state: PickerState`; it stays a pure view
  (no key handling, no window work).
- `PickerState` (new `@MainActor final class`, `ObservableObject`) owns
  `selectedSection`, `selectedStyleID`, `focus`, `isSubmenuOpen`, and the pure transitions
  `move(by:)`, `activate()`, `back()`, `hover(section:)`, `hover(style:)`,
  `accelerator(_:)`. Four rows of logic are far easier to get right than four key paths in
  a view body, and it can be exercised from a `#Preview`.
- The open section column is wrapped in
  `.transition(.move(edge: placement == .trailing ? .leading : .trailing).combined(with: .opacity))`
  with `.animation(.easeOut(duration: 0.12), value: state.isSubmenuOpen)`.

### 7.3 Panel geometry

`StylePickerPanel` becomes a small state machine around one panel:

1. **Show**: measure the root-only fitting size (240 × content), clamp the origin near the
   cursor exactly as today, order front.
2. **Open section**: compute `placement` by testing
   `origin.x + rootWidth + 1 + submenuWidth > screen.visibleFrame.maxX`.
   - trailing: frame becomes `(origin.x, top - height, total, height)`;
   - leading: `origin.x -= (submenuWidth + 1)` so the root column keeps its screen position.
   Then update `hostingController.view.frame`, apply the new panel frame, and let the
   SwiftUI transition run.
3. **Close section**: restore the root-only frame (`origin.x` restored on the leading
   side).
4. **Close**: remove the key monitor, close the panel, release state.

Panel facts stay as they are: `styleMask: [.borderless, .nonactivatingPanel]`,
`level = .floating`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`,
`hasShadow = true`, `becomesKeyOnlyIfNeeded = false`. The panel background stays opaque
(`NSColor.windowBackgroundColor`) with a `Divider()` between columns — PRD v3's P2/P5 own
the rounded chrome, hairline, and vibrancy.

### 7.4 Key monitor

New `UI/StylePicker/PickerKeyMonitor.swift`:

```swift
@MainActor
final class PickerKeyMonitor {
    init(onKey: @escaping (KeyEvent) -> Bool)   // true = consumed
    func start()   // NSEvent.addLocalMonitorForEvents(matching: .keyDown)
    func stop()    // removeMonitor; idempotent
}
```

- Installed by `StylePickerPanel.show()`, removed in `close()` **and** before any style is
  handed to the orchestrator, so the popup never inherits arrow keys.
- Passes through any event with `.command` or `.option` in `modifierFlags`, and any key it
  does not handle. Returns `nil` for handled events so nothing beeps.
- Uses `event.charactersIgnoringModifiers` for letters/digits and `keyCode` (or the
  `NSUpArrowFunctionKey…` constants) for arrows and `Return`.
- Rationale over five hidden `.keyboardShortcut` buttons: the arrows now have
  level-dependent meaning (`→` opens *or* runs), which a flat set of key equivalents cannot
  express. Issue #79 already allows this fallback explicitly. If a monitor turns out not to
  receive events in a non-activating `KeyablePanel` on macOS 13, fall back to hidden
  zero-size buttons for `↑ ↓ →` and keep the rest in the monitor.

### 7.5 Popup capability fix

`SummaryPopupViewModel.isWriteMode` (`category == .write`) currently gates Replace and Diff,
so PRD v6's translate style would arrive with Replace disabled. Replace it with

```swift
/// True when the style rewrites the selection in place, so diff and Replace apply.
var supportsReplacement: Bool { currentStyle.outputFormat == .plainText }
```

and keep the name out of the view: one property, one meaning. Both call sites
(`canReplace`, `recomputeDiff`) switch to it. `.plainText` holds for every Write style and
for Translate to English, and for no Transform style.

### 7.6 Orchestrator

- The picker callback becomes `onSelect(style:)` plus `onCancel`, unchanged in shape — the
  section column hands back a `SummaryStyle`, so routing, `recordSelection` and history are
  untouched.
- The `SummaryStyle.customPrompt.id` branch and `showCustomPromptPanel` stay, guarded by
  `StyleCatalog.showsCustomPrompt`.
- The two `availableStyles` filters become `StyleCatalog.groups(from: styles)`-flattened
  styles (or a `styleStore.resultStyles` convenience), so the popup's style switcher matches
  the new catalogue instead of re-deriving it from categories.

---

## 8. File map

**New**

| File | Contents |
|:--|:--|
| `TextAssist/Models/StyleSection.swift` | `StyleSection`, `StyleSectionGroup`, `StyleCatalog` (§7.1) |
| `TextAssist/UI/StylePicker/PickerState.swift` | Selection, focus and transitions; no AppKit |
| `TextAssist/UI/StylePicker/PickerKeyMonitor.swift` | `NSEvent` local key monitor (§7.4) |

**Edited**

| File | Change |
|:--|:--|
| `TextAssist/Models/SummaryStyle.swift` | `section` property; curated `builtIn`; `retired`; keys per MN-FR13 |
| `TextAssist/Stores/StyleStore.swift` | Stale `lastUsedStyleID` migration; `groups` convenience |
| `TextAssist/UI/StylePicker/StylePickerView.swift` | Two columns, section rows, hints, no key caps |
| `TextAssist/UI/StylePicker/StylePickerPanel.swift` | Growth, leading/trailing placement, key monitor lifecycle |
| `TextAssist/Core/SummarizationOrchestrator.swift` | Catalogue-based `availableStyles`; custom-prompt flag |
| `TextAssist/UI/Popup/SummaryPopupViewModel.swift` | `supportsReplacement` (§7.5) |
| `README.md` | Usage step describes the two-level menu |
| `AGENTS.md` | Read order already lists this PRD; no further change |

No change to `project.pbxproj` (synchronized group), no new dependency, no new store on
disk.

---

## 9. Task breakdown — Milestone M8

Each task lists **Depends on / Size / Files / Done when**. "Done when" is checked by hand
in the running app.

### MN1 — Style tree, curated catalogue, retirement
- **Depends on:** — · **Size:** M
- **Files:** `Models/StyleSection.swift` (new), `Models/SummaryStyle.swift`,
  `Stores/StyleStore.swift`
- **Changes:** `StyleSection` + `StyleSectionGroup` + `StyleCatalog`; `SummaryStyle.section`;
  `builtIn` reduced to the ten styles of MN-FR13 with their new keys; `retired` holds the
  seven; `StyleStore` migration and `groups`.
- **Done when:** the app builds; `StyleCatalog.groups(from: StyleStore().styles)` returns
  four groups with 4/3/1/2 styles; no key or digit collides (debug assertion passes); a
  `UserDefaults` `lastUsedStyleID` pointing at `detailed-summary` opens with Short Summary
  highlighted instead of no checkmark. Nothing in the UI has changed yet.

### MN2 — Two-column shell, root column, panel growth
- **Depends on:** MN1 · **Size:** L
- **Files:** `UI/StylePicker/PickerState.swift` (new), `StylePickerView.swift`,
  `StylePickerPanel.swift`
- **Changes:** root column with four rows and a dot on the last-used section; section column
  rendering + `Divider`; panel widening with a fixed left edge; leading-side mirror near the
  screen edge; slide-in transition and Reduce Motion.
- **Done when:** `⌥⇧S` shows exactly Transform, Write, Chat, Translations; clicking a
  section widens the panel and lists that section's styles; opening a different section
  swaps contents without changing the panel's left edge; near the right screen edge the
  column appears on the left and is fully visible; the panel is never clipped; the source
  app stays frontmost (Replace still works afterwards).

### MN3 — Mouse interaction
- **Depends on:** MN2 · **Size:** S
- **Files:** `PickerState.swift`, `StylePickerView.swift`
- **Changes:** hover intent (120 ms) to open a section, hover selects a row, one shared
  highlight, click-to-run, click-the-same-section-to-close, no close on pointer exit.
- **Done when:** moving the pointer down the root column swaps sections without flicker;
  travelling diagonally into the column keeps it open; the highlight never appears twice;
  clicking a row runs exactly that style.

### MN4 — Keyboard navigation
- **Depends on:** MN2 · **Size:** M
- **Files:** `PickerState.swift`, `PickerKeyMonitor.swift` (new), `StylePickerView.swift`,
  `StylePickerPanel.swift`
- **Changes:** the §4.5 map, the §7.4 monitor and its lifecycle, accent-color highlight,
  hint bars, accessibility traits.
- **Done when:** every row of §4.5 works in the running app; holding `↓` moves smoothly;
  `esc` closes from either column and nothing runs; `⌘W`/`⌘Q` and the global hotkeys still
  work with the picker open; after the picker closes, arrow keys no longer reach it (open
  the chat popup and press `↓` — no effect); VoiceOver announces the highlighted row as
  selected.

### MN5 — Popup, history and custom-prompt aftermath
- **Depends on:** MN1 · **Size:** S
- **Files:** `UI/Popup/SummaryPopupViewModel.swift`, `Core/SummarizationOrchestrator.swift`
- **Changes:** `supportsReplacement` (§7.5); catalogue-based `availableStyles` in both call
  sites; `StyleCatalog.showsCustomPrompt` guard around the custom-prompt branch.
- **Done when:** a Write style shows Diff and Replace; a Transform style shows neither; a
  Translate style shows both; the popup's style menu lists the ten catalogue styles in
  section order; reopening a history entry whose style was retired opens in Short Summary
  with the stored text and Regenerate works.

### MN6 — Documentation
- **Depends on:** MN4, MN5 · **Size:** S
- **Files:** `README.md`, doc comments in `StylePickerView.swift` / `StyleSection.swift` /
  `StylePickerPanel.swift`
- **Changes:** describe the two-level menu, the keys, and how to restore a retired style or
  re-enable Custom Prompt. While editing the README usage step, drop its stale
  "**Assist with Selection** from the menu-bar popover" sentence — that menu item was
  replaced by a placeholder in #64.
- **Done when:** the README matches what the app does; each new public type keeps a `///`
  doc comment; the "restore a retired style" recipe is one copy-pasteable line.

### MN7 — Manual parity pass
- **Depends on:** MN1–MN6 · **Size:** S
- **Changes:** only residual fixes found while walking §11.
- **Done when:** every row of §11 passes, on Dutch and English selections, in Light and
  Dark, with Reduce Motion both on and off.

---

## 10. Milestones, parallelism, issue filing

- Everything targets **M8 — Picker v3**. Filing needs `.agents/config.json` to gain the
  `M8` milestone and an `epic:9` entry (PRD v3 reserves `M6`/`epic:7`, PRD v6 reserves
  `M7`/`epic:8`). File that config change together with the issue set.
- Parallel: MN1 first, then MN2. MN3 and MN4 both extend `PickerState`/`StylePickerView`
  and should land sequentially — MN3 then MN4 — or be folded into one change if MN2's
  shell is small. MN5 touches no picker file and can run in parallel with MN3/MN4.
- MN6 after MN4/MN5. MN7 last.
- **Supersedes:** Epic #82 and its tasks #79 (navigation), #80 (highlight + hint), #81
  (document + verify). Close them into MN4/MN6 rather than running both.

---

## 11. Verification checklist (by hand)

1. **Build check** from `AGENTS.md` passes; deployment target still 13.0; no
   `project.pbxproj` edit.
2. **Root**: `⌥⇧S` shows four rows and nothing else; the section holding the last-used style
   carries a dot; the hint bar is fully visible and not truncated.
3. **Sections**: each of the four lists exactly the styles in MN-FR13 — Transform 4, Write
   3, Chat 1, Translations 2; a retired style name never appears.
4. **Mouse**: hover opens a section; diagonal travel into the column does not close it;
   hovering another root row swaps contents; clicking a style runs it and closes the panel.
5. **Keyboard**: `↓`×3 `→` `↓` `Return` runs the second item of the fourth section; `←`
   closes the column and keeps the root highlight; `esc` closes everything from either
   column.
6. **Wrap**: `↑` on the first root row moves to the last; `↓` on the last item wraps.
7. **Auto-repeat**: hold `↓` for two seconds in the root and in a section column — no skip,
   no stall, no crash.
8. **Accelerators**: `g` runs Fix Grammar from the root; `2` opens Write; `c` inside the
   Translations column runs Chat about this text; unrelated letters are ignored.
9. **Modifiers**: with the picker open, `⌘W` closes the source app's window (not the
   picker), and `⌥⇧S` re-captures.
10. **Screen edges**: open near the right edge (column mirrors left, fully visible), near the
    bottom edge (clamped upward), and on a second display.
11. **Reduce Motion**: with it enabled, the column appears without animation.
12. **Replace**: pick a Write style with `Return` in TextEdit — the selection is replaced,
    so the panel really stayed non-activating.
13. **Regression**: `⌥⇧C` and `⌥⇧G` skip the picker; Custom Prompt never appears; the result
    popup's style switcher lists the ten styles; history, Recent, and Settings are unchanged.
14. **Retired history**: reopen an entry recorded with Detailed Summary before this change —
    it opens with its stored text and Regenerate works.
15. **Appearance**: repeat 2, 4, 5 and 10 in Light and Dark.

---

## 12. Constraints (unchanged from v2/v5/v6)

1. **Never edit `TextAssist.xcodeproj/project.pbxproj`.** New `.swift` files under
   `TextAssist/` are compiled automatically.
2. **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`**, Swift 5 mode; mark pure parsing/formatting
   helpers `nonisolated`.
3. **Deployment target macOS 13.0.** No `@Observable`, `onKeyPress`, two-parameter
   `.onChange(of:)`, `Inspector`. `NSEvent` monitors, `NSAnimationContext`, `PreferenceKey`
   and `HStack` transitions are all fine.
4. **App Sandbox stays off**; **panels stay non-activating** — `KeyablePanel` and
   `.nonactivatingPanel` are load-bearing for Replace.
5. Preserve the `///` doc-comment style on new public types and methods.
6. One task = one reviewable change; no unrelated refactors. `StyleCategory` is not renamed;
   `SummaryStyle.section` is additive.
7. Never call `activate(ignoringOtherApps:)` from the picker; the source app must stay
   frontmost.

---

## 13. Coordination with the other PRDs and issues

| Item | Overlap | Rule |
|:--|:--|:--|
| **PRD v6** (translations) | Its §4.2 nested `Translations ›` submenu becomes a top-level section here | **This PRD supersedes v6's TR2** (the separate submenu panel and its geometry). v6 keeps TR1 (styles + prompts), TR5 (capability probe), TR6 (warning surfaces, now rendered inside the Translations section), TR7, TR8. v6 §7.3 (two-panel geometry) is void; §7.6's `t`/`c` keys survive as accelerators. |
| **PRD v3** (visual parity) | P5 restyles `StylePickerView`; P2 owns panel chrome | **Land v7 before v3's P5.** P5 then restyles the finished two-column picker instead of a 16-row list that is about to disappear. v7 ships system styling only — no token names, no `Palette.swift`. |
| **PRD v4** (multi-provider) | `availableStyles`, settings | No interaction. The catalogue filter is centralised in `StyleCatalog`, so v4's provider work does not touch the picker. |
| **#106** (Foundation Models) | Same menu, same picker | No interaction; the section tree is provider-agnostic. |
| **#79 / #80 / #81 / #82** (picker keyboard epic) | Exactly this work | Superseded. Close as not-planned and implement MN4 + MN6 against the section model; do not run both. |

---

## 14. Risks

| Risk | Impact | Mitigation |
|:--|:--|:--|
| Widening an `NSPanel` mid-session jumps or flickers on macOS 13 | Menu feels broken | Compute placement before applying the frame, animate once, keep the left edge fixed; ship without the tween if it still flickers (MN-FR6 fallback) and record it |
| A local `NSEvent` monitor does not see keys in a non-activating panel | Keyboard nav dead | §7.4's documented fallback to hidden key-equivalent buttons; verify in MN4 before building on it |
| Two-level navigation makes the common case slower | Users who knew the letters lose speed | Accelerators keep working from any level (§4.5); the section highlight starts on the last-used section |
| Key reassignment breaks muscle memory (`s`, `c` change meaning) | Surprise | Deliberate and listed in MN-FR13; the keys are no longer rendered, so the old mapping is not advertised anywhere |
| Retiring a style loses data | History entries dead-end | Definitions stay in `SummaryStyle.retired`; MN-FR16/17 cover fallbacks; verified in §11.14 |
| A hidden Custom Prompt looks like a removed feature | Users think it was dropped | Its re-enable recipe is documented in MN6; the panel and style remain compiled and tested by their previews |
| Mouse and keyboard fight over the highlight | Two highlights, wrong row runs | Single `PickerState.selectedStyleID`; hover and arrows both write it (§5.2 MN-FR12) |
| Section column is short and looks detached from the root | Visual disconnect | Top-aligned, shared opaque panel, divider, same row metrics; PRD v3's P5 finishes the look |

---

## 15. Open questions

1. **Key caps or not?** This PRD stops rendering `1`/`g`/`a` in the rows and lets the hint
   bar teach navigation. The alternative is to keep a dim key cap on the right of each row —
   more discoverable, noisier, and 20pt wider. Decide after using MN4 for a day.
2. **Type-to-filter.** With ten styles in four sections, filtering is arguably unnecessary.
   If the catalogue grows again, a `/` filter row at the root would scale better than a
   fifth section.
3. **User-curated sections.** Should the user be able to pin two or three styles into a
   "Favourites" section? Requires per-user ordering persistence and a manager UI; not now.
4. **Where Custom Prompt belongs if restored.** A `Custom…` footer row at the root (its
   current position), a fifth section, or a `⌘↩` in the section column.
5. **Should `Esc` from a section column close the column first?** This PRD says `esc`
   always dismisses (§4.5, for consistency with #65–#67). If testing shows people expect a
   one-level back-out, `esc` becomes `←` and the picker needs a different "close" affordance.

---

## 16. Changelog

- **rev 1 (2026-10-31)** — Initial draft: four cascading sections, keyboard-first
  navigation, curated catalogue (7 styles retired, Custom Prompt hidden), `supportsReplacement`
  popup fix, tasks MN1–MN7, milestone M8. Supersedes Epic #82 and PRD v6's submenu task.
