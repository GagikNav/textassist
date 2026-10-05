# Text Assist — Visual Parity PRD (v2 design ⇄ shipped app)

_Status: Draft for review · Owner: agent workflow · 2026-10-05_

**Purpose.** All v2 functionality ships and the milestones M0–M5 are done, but the
application does **not** look like the approved design. This PRD documents every
visual delta between the shipped app and the approved v2 design
(`Docs/design/v2/text-assist-v2-mockup.html`, `README.md`, `IMPLEMENTATION.md`),
and breaks the work into issue-ready tasks (Epic P, tasks **P1–P10**, milestone
**M6 — Visual parity**). It changes **appearance only** — no flows, no behavior, no
renames, no refactors of unrelated code.

---

## 1. Sources of truth

1. `Docs/design/v2/text-assist-v2-mockup.html` — the visual baseline. Its CSS
   `:root` block is the token source of truth.
2. `Docs/design/v2/README.md` — token contract (palette, appearance, type,
   spacing, radius, shadows, component definitions, panel sizes). Wins over the
   mockup where the two differ.
3. `Docs/design/v2/IMPLEMENTATION.md` — the SwiftUI translation (drop-in values).
   Adds no new design decisions.
4. `tickets/PRD-v2.md` — behavior contract. Wins over the mockup where the two
   differ (see §6 decisions).

The mockup has a Light/Dark switch in its board header. That is **review-board
chrome**, not a product surface. The app follows the system appearance — do not
build an in-app appearance switcher. The mockup's fake menu bar / beak / traffic
lights are likewise presentation chrome; the app's real chrome is drawn by
macOS.

## 2. Audit summary — the headline finding

The approved design was specified in `Docs/design/v2/*`, but **none of it was
applied to the UI**. A workspace-wide audit found:

| Check | Finding |
|:--|:--|
| `TextAssist/UI/Shared/Palette.swift` (spec'd in IMPLEMENTATION §1–4) | **Does not exist.** No `Ramp` / `Tok` / `Metric` anywhere. |
| Use of design tokens in any view | **Zero.** Every view uses system defaults (`.primary`, `.secondary`, `Color.accentColor`, system red/green). |
| `AccentColor.colorset` | **Empty** (`idiom: universal`, no color). Accent renders Apple **blue**. Design accent is violet-600 `#9634C9` with white text. |
| Panel chrome | All panels use `NSColor.windowBackgroundColor` + default window corners. Design: 18pt continuous corners, 0.5px hairline, plum-tinted vibrancy (light) / near-black screen (dark). |
| Typography | Result body 16pt (design 13), chat Markdown 15pt (design 13), elapsed 14pt proportional (design mono 12), picker keys 13pt mono (design 12.5). |
| Radii | `cornerRadius(10/8/6)` scattered ad hoc; no 8/12/18 tier, no `.continuous`. |
| Diff colors | System `.red`/`.green`. Design: terracotta `#b3452c` / forest `#2e7d46` with 15%/18% backgrounds (dark: `#e07a5f` / `#5fbf7a`). |
| Buttons | System default bordered/prominent styles with SF-Symbol labels. Design: 26pt text-only buttons, radius 8, violet prominent, ⌘-glyph captions. |

So the work is not "tweak a few colors" — it is **lay down the token layer and
restyle all six surfaces against it**. Every task below starts from the drop-in
values already written in `IMPLEMENTATION.md`; the implementer does not design.

## 3. Token checklist (foundation)

The mockup's `:root` block binds these; `IMPLEMENTATION.md` §1–4 gives the exact
Swift. Build once in P1 and reference everywhere.

| Axis | Key values |
|:--|:--|
| Brand anchors | ink `#2E073F` · plum `#7A1CAC` · violet `#AD49E1` · lavender `#EBD3F8` |
| Accent | fill `violet-600 #9634C9` (both appearances), white on fill; accent-as-text `violet-700` light / `violet-400` dark; tint `violet-500 @20%` light / `@26%` dark |
| Text | Apple gray: `#1d1d1f / #424245 / #6e6e73 / #86868b`; dark inverse `#f5f5f7 / #c7c7cc / #a1a1a6` |
| Surfaces | light: panel plum-50@88%, raised plum-50→white, sunk plum-100→white, hair plum-200, line ink-950@13%, hover plum-100/plum-200 · dark: near-black screens (`#100217` screen, `#15031E` raised, `#0A010E` sunk), white hairlines @12/17%, hover white@10/22% |
| Semantic | ok `#2e7d46`, bad `#b3452c`, unknown plum-500 · dark `#5fbf7a / #e07a5f / mauve-400` |
| Diff | added/removed = semantic green/red, bg 18%/15% light, 22%/20% dark |
| Type | title 13.5/620 (chat 13/620), body & result 13/400, caption 11/400, picker group 10.5/600 uppercase, mono 12 (tabular numerics) |
| Spacing | 4 · 8 · 12 · 16 · 20; row padding 5–8 |
| Radius | control 8 · card/popover/field/menu 12 · panel/window 18, all `.continuous`; circles 50%, capsules 999 |

## 4. Per-surface delta analysis

### 4.1 Panels (AppKit chrome) — all four

| Element | Mockup / design | Current | Change |
|:--|:--|:--|:--|
| Corner radius | 18 continuous | default window corners | round content layer, `cornerRadius: 18, .continuous` |
| Background | plum vibrancy (blur 34 + plum-50@88%) light / near-black `--screen` dark | `NSColor.windowBackgroundColor` (gray) | `NSVisualEffectView` + tint layer per appearance, opaque token fallback |
| Border | 0.5px hairline (ink-950@13% / white@17%) | none (picker) or system | 0.5pt stroke `Tok.line` |
| Title bar | none on result/chat (content ✕); Settings keeps traffic lights + centered title | `.titled` with system title + traffic lights on result/chat/settings | transparent titlebar, hidden title; hide traffic lights on result/chat, keep on Settings |
| Closable behavior | ⌘W / ✕ closes | ✓ | keep `.closable` mask; content ✕ already exists on result/chat |
| Sizes | Result 460×auto · Chat 520×560 · Settings 520×400 · Picker auto (≈240) | Result 600×420 · Chat 520×560 ✓ · Settings 420×400 · Picker fitting ✓ | Result default → 460×auto; Settings → 520×400 |
| Shadow | native panel shadow (IMPLEMENTATION §4) | `hasShadow = true` ✓ | keep |

### 4.2 Style picker (`StylePickerView`)

| Element | Mockup | Current | Change |
|:--|:--|:--|:--|
| Container | padding 8 | padding 12 | 8 |
| Group label | 10.5/600 uppercase, `--panel-dim` #6e6e73, pad 9/8/4 | `.caption2` semibold `.secondary` | size + token color |
| Row | pad 5/8, gap 10, radius 8 | pad vertical 2, gap 8 | exact values |
| Key glyph | mono 12.5, width 20, dim | body mono 13, secondary | mono 12.5 dim |
| Hover | `--panel-fill` plum-100 | none | `.onHover` fill |
| Selected (last used) | whole row `--accent-tint`, check + key in accent-strong | bare blue checkmark only | tint + token check |
| Separator | plum-200, margins 7/6 | default `Divider` | token color/margins |
| Cancel | name in panel-mut | secondary ✓ | token color |

### 4.3 Result popup (`SummaryPopupView`)

| Element | Mockup | Current | Change |
|:--|:--|:--|:--|
| Layout | header → tools row → body → footer | toolbar → divider → body → footer (close in toolbar) | header owns title + ✕; tools row owns style chip + segmented + elapsed |
| Title | 13.5/620 | panel window title (`panel.title`) | in-content title |
| Style switcher | chip h24 r8 (panel-solid, hairline, caret) → menu with ✓ + mono kbd | native `.menu` Picker, 15pt | chip-styled trigger (native menu popup is acceptable) |
| Clean/Diff | custom segmented: sunk track r12, 2px pad, btn 11.5 r8, active = raised + shadow | native segmented, width 130 | custom segmented |
| Body text | 13/1.58 (diff 1.75) | **16pt** | 13 |
| Disclosure | 11.5 panel-mut "Original · n words" | `DisclosureGroup` caption-ish, system | 11.5 token color |
| Original box | sunk bg, r12, pad 10/12, 12.5/1.5, max-height 120 | plain secondary text in group | sunk card |
| Streaming | "Generating …" spinner note in body | empty body + footer `ProgressView` "Streaming…" | gen-note in body |
| Buttons | text-only: Copy · Regenerate (bordered 26/h8) · Replace (prominent + ⌘↩) · Chat (borderless + ⌘T) | SF-Symbol labels, system styles | text-only, token styles, keep keyboard shortcuts |
| Elapsed | mono 10.5 dim in tools row | footer 14pt "1.2 s" | mono 12 "1.2s" in tools row |
| Error banner | (not in mockup — keep, restyle) | system red, 15pt | `Tok.bad` bg 15% + border 40%, r8, 13pt |
| Diff tokens | del/ins with 15/18% bg, r3 | system red/green | tokens + scheme (see P9) |
| Padding | 13 horizontal / 9–11 vertical | 16 / 10 | match |

### 4.4 Chat (`ChatPopupView`)

| Element | Mockup | Current | Change |
|:--|:--|:--|:--|
| Header | icon accent-strong, title 13/620, hairline | SF icon default color, `.headline` | token icon + 13/620 + hairline |
| Context row | disclosure 11.5, "· n words · from App" (n bold), box sunk r12 max 140 | `DisclosureGroup` with `text.quote` icon, callout | restyle, drop icon, sunk card |
| Starter chips | 2-col grid, panel-solid r12, shadow-sm, 12pt | adaptive grid, `.bordered` | chip style |
| User bubble | right, accent-tint bg, r12, 12.5/1.45 | `Color.accentColor.opacity(0.25)`, r10 | token tint, r12 |
| Assistant | "ASSISTANT" mono 10 dim caption, hover Copy/Regenerate, Markdown 12.5, blinking caret while streaming | no caption, always-visible buttons, 15pt, no caret | caption + hover actions + 12.5 + caret |
| Input | field h32 r12 panel-solid hairline, placeholder dim; send = 28pt circle accent `↑`; stop = circle panel-fill2 `■` | plain TextField, r8 border, `arrow.up.circle.fill` 22 / `stop.circle.fill` | field + circle buttons |
| Panel size | 520×560 (README) | ✓ 520×560 | keep |

### 4.5 Menu-bar popover (`MenuBarStatusView`)

System popover chrome (menu-bar strip, beak, vibrancy) is drawn by
`MenuBarExtra` — restyle the **content** only.

| Element | Mockup | Current | Change |
|:--|:--|:--|:--|
| Status dot | 8pt ok/bad/unknown token colors | system `.green/.red/.gray` | token colors |
| Status text | "Ollama · model" 12.5 + sub-line 11 ("Local model ready." / "Not running. …" / "Checking…") | `.subheadline`, sub-line only when offline | sizes + all three sub-lines |
| Model control | mini chip h24 r8 panel-solid + caret | native menu Picker | chip-styled trigger (native menu acceptable) |
| Rows | 12.5, pad 7/10, hover fill, kbd right mono 11 | plain rows, pad 6/12 | paddings + hover + kbd |
| Recent | two-line rows (title + dim preview) | single truncated "Style · 40 chars" | two-line rows |
| Quit | with ⌘Q right-aligned mono ✓ | ✓ | token paddings |
| "Assist with Selection" | in mockup, **canceled by PRD-v2 §4.5** | "Open TextAssist" placeholder | keep placeholder (see §6) |
| Clear history | not in mockup | present | keep, restyled (see §6) |

### 4.6 Settings (`ProviderSettingsView` + `SettingsPanel`)

| Element | Mockup | Current | Change |
|:--|:--|:--|:--|
| Tabs | General \| Provider (active = raised r8) | single Form, sections General + Ollama | tab row + two tab bodies |
| Window | 520×400, traffic lights, centered "Settings" title | 420×400, title "Text Assist Settings" | size, chrome per §4.1 |
| Fieldset | card r12, `--field-bg`, fs-title 10.5/600 uppercase dim, rows pad 9/14 with hairlines | grouped `Section` | card style |
| Row label | 12.5 + sub-line 11 mut | Form default | sizes + sub-lines |
| Recorder | mono 12 chip, panel-solid r8, min-width 64, center; recording = accent-strong | default `KeyboardShortcuts.Recorder` | wrap recorder in chip styling |
| Toggle | accent-filled switch | system Toggle (blue) | `.toggleStyle(.switch).tint(Tok.accent)` |
| Inputs | tinput 210×26 panel-solid r8 | `.roundedBorder` TextFields | styled fields |
| Footer | right-aligned Revert (bordered) + Save (prominent) | none | add footer buttons (Save = no-op write-through is acceptable; settings persist live) |
| Provider tab | "Provider tab unchanged" (README) | Ollama section with Refresh | move controls into Provider tab, restyle, keep Refresh |

### 4.7 Custom prompt + shared bits

Not in the mockup; must still speak the token language: title 13.5/620, editor
well r12 (currently r6), Cancel bordered + Submit prominent (currently plain),
panel chrome per §4.1, width 360 keep.

## 5. Semantics that move

| Thing | Design token | Current | Where |
|:--|:--|:--|:--|
| Diff add/del text + bg | `Tok.add/del` + `addBg/delBg` | system red/green | `TextDiffer.attributed` |
| Status dot ok/bad/unknown | `Tok.ok/bad/unknown` | system | `MenuBarStatusView` |
| User bubble / selected row tint | `Tok.accentTint` | `Color.accentColor @25%` | chat + picker |
| Error banners | `Tok.bad` bg/border | system red | result + chat |

`TextDiffer.attributed` is computed in the view model and needs a `ColorScheme`
for token resolution — pass `colorScheme` into `recomputeDiff` (view supplies
`@Environment(\.colorScheme)`) or resolve tokens to concrete `NSColor`s at the
call site. Implementation detail; do not re-architect the differ.

## 6. Decisions (mockup ⇄ PRD-v2 ⇄ app conflicts)

1. **Menu-bar "Assist with Selection"** — the mockup shows it, PRD-v2 §4.5
   canceled it (placeholder "Open TextAssist" remains). **PRD wins.**
2. **Clear history** — app-only P1 extra not in the mockup. Keep, restyled.
3. **Button icons** — mockup buttons are text-only. Match the mockup; keyboard
   shortcuts already render ⌘-glyph captions on macOS 13.
4. **Error banners** — mockup has no error state; the shipped banner stays but
   must use tokens.
5. **Panel sizes where mockup ≠ README** (chat frames 430 wide in mockup vs
   520 in README): **README wins**; the mockup frames are laid out for the
   review board.
6. **"Provider tab unchanged"** (README) means: keep the app's provider controls
   (base URL, model, refresh) and their behavior — just restyle and place in a
   Provider tab.
7. **Appearance** — no in-app Light/Dark switch; follow the system appearance.
   Every token already resolves per `ColorScheme`.
8. **No new design decisions.** Any judgment call defaults to `README.md`, then
   the mockup, then `IMPLEMENTATION.md`.

## 7. Constraints (unchanged, from AGENTS.md)

- Never edit `TextAssist.xcodeproj/project.pbxproj`. New files under `TextAssist/`
  compile automatically. Editing `Assets.xcassets/AccentColor.colorset/Contents.json`
  is allowed.
- `MainActor` default isolation; macOS 13.0 API only; Swift 5 mode.
- Sandbox off; panels stay non-activating (`KeyablePanel`).
- One task = one reviewable change; run the build check before declaring done.
- Preserve `///` doc-comment style on new types.

## 8. File map

**New**

```
TextAssist/UI/Shared/Palette.swift     (P1 — Ramp / Tok / Metric, IMPLEMENTATION §1–4)
TextAssist/UI/Shared/PanelChrome.swift (P2 — shared panel styling helper)
```

**Changed**

```
Assets.xcassets/AccentColor.colorset/Contents.json  (P1 — violet-600)
UI/StylePicker/StylePickerView.swift      (P5)
UI/StylePicker/StylePickerPanel.swift     (P2)
UI/Popup/SummaryPopup.swift               (P2)
UI/Popup/SummaryPopupView.swift           (P3)
UI/Popup/SummaryPopupViewModel.swift      (P3, P9 — elapsed format, diff scheme)
UI/Chat/ChatPopup.swift                   (P2)
UI/Chat/ChatPopupView.swift               (P4)
UI/MenuBar/MenuBarStatusView.swift        (P6)
UI/Settings/SettingsPanel.swift           (P2, P7)
UI/Settings/ProviderSettingsView.swift    (P7)
UI/CustomPrompt/CustomPromptPanel.swift   (P2)
UI/CustomPrompt/CustomPromptView.swift    (P8)
Utilities/TextDiffer.swift                (P9)
```

## 9. Task breakdown — Epic P

Issue-ready: every task lists **Depends on / Size / Files / Done when**. Visual
"Done when" is always checked by hand in the running app against the mockup
frame named (open `Docs/design/v2/text-assist-v2-mockup.html` in a browser; use
its Light/Dark switch for both appearances).

### P1 Foundation — palette, tokens, metrics, accent asset
- **Depends on:** — · **Size:** M
- **Files:** new `UI/Shared/Palette.swift`; edit `Assets.xcassets/AccentColor.colorset/Contents.json`
- Implement `Ramp`, `Tok`, `Metric` verbatim from `IMPLEMENTATION.md` §1–4
  (hex values, appearance-resolving functions, radius/spacing constants).
  Set the accent asset to universal `violet-600 #9634C9`.
- **Done when:** builds; a scratch `Color.red = Tok.accent` check removed;
  `borderedProminent`/`.tint(Tok.accent)` render violet with white text in both
  appearances; tokens resolve in light and dark.

### P2 Panel chrome — radius, hairline, vibrancy, titlebars, sizes
- **Depends on:** P1 · **Size:** M
- **Files:** new `UI/Shared/PanelChrome.swift`; edit `StylePickerPanel.swift`, `SummaryPopup.swift`, `ChatPopup.swift`, `SettingsPanel.swift`, `CustomPromptPanel.swift`
- Shared helper applies to every `KeyablePanel` hosting view: 18pt continuous
  rounded content layer, 0.5px `Tok.line` hairline, plum-tinted vibrancy (light)
  / near-black `Tok.screen` (dark) via `NSVisualEffectView` + tint (opaque token
  fallback). Result/Chat: transparent titlebar, hidden title, hidden traffic
  lights (content ✕ stays). Settings: transparent titlebar, hidden title text,
  traffic lights stay, centered "Settings". Picker/CustomPrompt: borderless
  panels get the same rounded/hairline treatment. Sizes: Result default 460×auto
  (keep min 360×280), Settings 520×400. Keep non-activating masks, shadows,
  fittingSize picker sizing.
- **Done when:** all panels render rounded + hairline + plum/near-black in both
  appearances; result opens 460 wide; settings 520×400; ✕/⌘W still work.

### P3 Result popup restyle (Transform + Write)
- **Depends on:** P1, P2 · **Size:** L
- **Files:** `SummaryPopupView.swift`, `SummaryPopupViewModel.swift` (elapsed format)
- Rebuild per mockup frames 03/04: header (title 13.5/620 + ✕) → tools row
  (style chip h24 r8 with caret + native menu; Write adds custom Clean/Diff
  segmented — sunk r12 track, active raised) → body (13pt, disclosure 11.5,
  Original sunk card r12 max 120, "Generating …" note while streaming, diff
  1.75) → footer (text-only Copy/Regenerate bordered, Replace prominent ⌘↩,
  Chat borderless ⌘T, elapsed mono 12 dim at tools right). Token error banner.
  Paddings 13 horizontal. Keep all existing disabled-state logic.
- **Done when:** side-by-side match with mockup frames 03 + 04 in light and dark;
  streaming state shows the gen-note; all shortcuts/disabled rules unchanged.

### P4 Chat restyle
- **Depends on:** P1, P2 · **Size:** M
- **Files:** `ChatPopupView.swift`
- Rebuild per mockup frames 05/06: header (accent icon, 13/620 title, hairline);
  context disclosure 11.5 with bold word count, sunk card max 140; starter chips
  2-col r12 raised; user bubble accent-tint r12 12.5; assistant rows with
  "ASSISTANT" mono caption + hover Copy/Regenerate + Markdown 12.5 + blinking
  caret while streaming; input field h32 r12 + 28pt circle accent send `↑` /
  stop `■`; token error banner.
- **Done when:** side-by-side match with frames 05 + 06 in light and dark;
  streaming caret blinks; Stop/disabled rules unchanged.

### P5 Picker restyle
- **Depends on:** P1, P2 · **Size:** S
- **Files:** `StylePickerView.swift`
- Apply §4.2 verbatim: padding 8, group labels 10.5/600 dim, rows pad 5/8 gap 10
  r8, keys mono 12.5 dim w20, hover fill, last-used row accent-tint with
  accent-strong check + key, plum-200 separators, Cancel in panel-mut.
- **Done when:** side-by-side match with mockup frame 02 in light and dark;
  shortcut keys, `esc`, auto-size unchanged.

### P6 Menu-bar popover restyle
- **Depends on:** P1 · **Size:** S
- **Files:** `MenuBarStatusView.swift`
- Apply §4.5: token dots + all three status sub-lines, model chip trigger,
  row paddings 7/10 with hover fill, Recent as two-line rows, Quit ⌘Q, keep
  "Open TextAssist" placeholder and Clear history (restyled).
- **Done when:** side-by-side match with frames 07 + 08 in light and dark;
  status cycling (ok/unknown/offline) reads correctly.

### P7 Settings restyle
- **Depends on:** P1, P2 · **Size:** M
- **Files:** `ProviderSettingsView.swift`, `SettingsPanel.swift`
- Apply §4.6: General/Provider tab row, fieldset cards (fs-title 10.5/600
  uppercase dim, rows 9/14 with hairlines, 12.5 labels + 11 sub-lines), recorder
  chips (mono 12, r8, min-width 64, recording accent-strong), accent-tinted
  switch, styled 26pt inputs, footer Revert + Save (bordered/prominent).
  Provider tab holds base URL / model / refresh, restyled only.
- **Done when:** side-by-side match with mockup frame 09 in light and dark;
  recorders/toggle/URL still function.

### P8 Custom prompt restyle
- **Depends on:** P1, P2 · **Size:** S
- **Files:** `CustomPromptView.swift`
- Title 13.5/620, instruction caption 11, editor well r12 sunk, Cancel
  bordered + Submit prominent; width 360 keep.
- **Done when:** matches the token language (no mockup frame); manual check in
  both appearances.

### P9 Diff and semantic token wiring
- **Depends on:** P1 · **Size:** S
- **Files:** `Utilities/TextDiffer.swift`, `SummaryPopupViewModel.swift`
- `TextDiffer.attributed` takes the resolved add/del colors + backgrounds
  (15/18% light, 20/22% dark); `recomputeDiff` receives the scheme from the
  view. No behavior change.
- **Done when:** Write diff renders token red/green in both appearances with
  correct backgrounds and strikethrough.

### P10 Holistic light/dark parity pass
- **Depends on:** P3, P4, P5, P6, P7, P8, P9 · **Size:** S
- **Files:** any residuals found
- Walk every surface in light + dark against the mockup (toggle the mockup's
  header switch). Fix only visual residuals; no scope creep.
- **Done when:** all six surfaces match in both appearances; build check green;
  handoff written.

## 10. Milestones & parallelism

| Milestone | Tasks | Gate |
|:--|:--|:--|
| **M6 — Visual parity** | P1–P10 | App is visually indistinguishable from the mockup in light + dark |

P1 is the single root. P2–P9 fan out after it; P2 must land before P3/P4/P7
(panel chrome). P3/P4/P5/P6/P8 are parallelizable. P9 and P3 share
`SummaryPopupViewModel.swift` (P3 edits elapsed formatting, P9 edits
`recomputeDiff`) — run them sequentially or fold P9 into P3's branch. P10 runs
last. Orchestrator edits follow the existing sequential rule (AGENTS.md).

## 11. Verification checklist (per task, by hand)

1. Build check (AGENTS.md command) — green.
2. Open the mockup in a browser; toggle Light/Dark in its header; flip the Mac
   between Light and Dark appearance.
3. Compare each surface at rest, hover, selected, streaming, disabled, and
   empty states.
4. Re-run the manual flows from `PRD-v2.md` §4 (⌥⇧S → pick → result; write +
   diff + replace; chat + continue in chat; menu bar; settings) to confirm no
   behavior regression.
