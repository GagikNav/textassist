# Text Assist — PRD v3: Visual Parity (v2 design ⇄ shipped app)

_Status: Draft for review (rev 2) · Owner: agent workflow · 2026-10-05_

> **Rev 2 (review pass)** fixed two factual errors (elapsed placement, P3 file
> list), added the missing specs (§12–§21: non-goals, coordination with
> `PRD-v4-providers.md`, AppKit panel recipe, Markdown theme, interaction and
> accessibility states, copy deck, issue-filing metadata, risks, open questions),
> and added task **P11** (Markdown theme). See §21 for the full changelog.

**Purpose.** All v2 functionality ships and the milestones M0–M5 are done, but the
application does **not** look like the approved design. This PRD documents every
visual delta between the shipped app and the approved v2 design
(`Docs/design/v2/text-assist-v2-mockup.html`, `README.md`, `IMPLEMENTATION.md`),
and breaks the work into issue-ready tasks (Epic P, tasks **P1–P11**, milestone
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
| Elapsed | mono 10.5 dim — **tools row** in Transform (frame 03), **footer right** in Write (frame 04) | footer 14pt "1.2 s" | mono 12 "1.2s", placed per mode |
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

## 6a. Non-goals

- No flow, behavior, model, or provider changes — appearance only. If a restyle
  task finds itself editing `SummarizationOrchestrator` logic or provider code,
  it has left scope (P9's one-line call-site touch is the sanctioned exception).
- No new surfaces, no redesign of the approved flows, no renaming of existing
  types, no refactors of unrelated code.
- No custom-drawn window chrome beyond what §12 specifies (no custom shadows,
  no custom resize handles — the `NSPanel` keeps drawing those).
- No in-app appearance switcher; no bundled fonts; no new third-party
  dependencies.
- No automated tests (repo-wide rule); verification is the build check plus
  the §11 manual checklist.
- Not addressed here: the multi-provider work in `tickets/PRD-v4-providers.md`
  (see §6b for the seam).

## 6b. Coordination with `PRD-v4-providers.md` (multi-provider)

PRD v4 rewrites several of the same files. The two PRDs must be sequenced, not
run in parallel on the same files:

| Overlap | v3 (this PRD) | v4 (providers) |
|:--|:--|:--|
| `UI/Settings/ProviderSettingsView.swift` | P7 restyles into General/Provider tabs | FR-30 reworks into a provider-aware form (picker + per-provider sections) |
| `UI/Settings/SettingsPanel.swift` | P2/P7: 520×400, chrome | FR-32: taller panel (~320–360 content height) |
| `UI/MenuBar/MenuBarStatusView.swift` | P6: "Ollama · model" + status sub-lines | Provider-agnostic status line (provider name, not Ollama) |
| `UI/Popup/SummaryPopupView.swift` + VM | P3 restyle | FR-34 adds a `providerLabel` next to the timer |

**Sequencing rule:** land **v4 first, then v3** (restyle last, so the restyle
isn't thrown away by the v4 rework). If v3 lands first, P6/P7 must be re-based
onto v4's new Settings/menu-bar structure and the "Ollama ·" copy becomes
wrong. Whichever order is chosen, the second PRD's tasks must re-audit the
affected sections (§4.5, §4.6) against the then-current code before starting.
Also note v4's FR-34 adds a provider label to the result footer — P3's footer
layout must leave room for it (mono 12 dim, right of the elapsed).

## 6c. Copy deck (exact strings)

The mockup's strings are the product copy. Do not paraphrase:

| Surface | String |
|:--|:--|
| Result disclosure | `Original · N words` |
| Streaming note | `Generating <Style>…` |
| Result footer | `Copy` · `Regenerate` · `Replace` · `Chat` |
| Segmented | `Clean` · `Diff` |
| Chat header | `Chat with Selection` |
| Chat context | `Selected text · N words · from <App>` |
| Chat input placeholder | `Ask about the selected text…` |
| Starter chips | `What's the main point?` · `Find weaknesses` · `Draft a reply` · `Explain the jargon` |
| Assistant caption | `ASSISTANT` (mono 10, uppercase, dim) |
| Menu-bar status | `Ollama · <model>` + `Local model ready.` / `Not running. Start Ollama and try again.` / `Checking…` |
| Menu-bar rows | `Settings…` · `Recent` · `Quit` |
| Settings tabs | `General` · `Provider` |
| Settings footer | `Revert` · `Save` |
| Picker groups | `TRANSFORM` · `WRITE` · `CHAT` (uppercase) + `Custom Prompt` · `Cancel` |

(If PRD v4 has landed first, the menu-bar status line becomes
`<Provider> · <model>` — keep v4's wording, restyle only.)

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
TextAssist/UI/Shared/Palette.swift        (P1 — Ramp / Tok / Metric, IMPLEMENTATION §1–4)
TextAssist/UI/Shared/PanelChrome.swift    (P2 — shared panel styling helper)
TextAssist/UI/Shared/MarkdownTheme.swift  (P11 — shared MarkdownUI theme)
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
  Chat borderless ⌘T). Elapsed mono 12 dim — tools row in Transform, footer
  right in Write (per frames 03/04). Token error banner. Paddings 13
  horizontal. Keep all existing disabled-state logic.
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
- **Files:** `Utilities/TextDiffer.swift`, `SummaryPopupViewModel.swift`, `Core/SummarizationOrchestrator.swift` (call site)
- `TextDiffer.attributed` takes the resolved add/del colors + backgrounds
  (15/18% light, 20/22% dark); `recomputeDiff` receives the scheme from the
  view. No behavior change. Note `recomputeDiff()` is invoked by the
  orchestrator (stream completion), so the scheme must be threaded through the
  view model (e.g. a `var colorScheme` set from the view's
  `@Environment(\.colorScheme)`), not passed per call.
- **Done when:** Write diff renders token red/green in both appearances with
  correct backgrounds and strikethrough.

### P10 Holistic light/dark parity pass
- **Depends on:** P3, P4, P5, P6, P7, P8, P9 · **Size:** S
- **Files:** any residuals found
- Walk every surface in light + dark against the mockup (toggle the mockup's
  header switch). Fix only visual residuals; no scope creep.
- **Done when:** all six surfaces match in both appearances; build check green;
  handoff written.

### P11 Markdown theme (result + chat bodies)
- **Depends on:** P1 · **Size:** S
- **Files:** new `UI/Shared/MarkdownTheme.swift`; edit `SummaryPopupView.swift`, `ChatPopupView.swift` (swap `markdownTextStyle` for the shared theme)
- Build one token-based `MarkdownUI.Theme` per §13 (body 13 result / 12.5
  chat, headings, strong, lists, code, blockquote, links, streaming opacity
  55%) and apply it in both surfaces. No other task may touch MarkdownUI
  configuration.
- **Done when:** Markdown headings/lists/code/blockquotes render in token
  colors and system fonts in both surfaces and both appearances; streaming
  bodies render at reduced opacity; plain-body sizes unchanged from P3/P4.

## 10. Milestones & parallelism

| Milestone | Tasks | Gate |
|:--|:--|:--|
| **M6 — Visual parity** | P1–P11 | App is visually indistinguishable from the mockup in light + dark |

P1 is the single root. P2–P9 and P11 fan out after it; P2 must land before
P3/P4/P7 (panel chrome). P3/P4/P5/P6/P8/P11 are parallelizable. P9 and P3 share
`SummaryPopupViewModel.swift` (P3 edits elapsed formatting, P9 edits
`recomputeDiff`) — run them sequentially or fold P9 into P3's branch. P10 runs
last, after P11. Orchestrator edits follow the existing sequential rule
(AGENTS.md).

## 11. Verification checklist (per task, by hand)

1. Build check (AGENTS.md command) — green.
2. Open the mockup in a browser; toggle Light/Dark in its header; flip the Mac
   between Light and Dark appearance.
3. Compare each surface at rest, hover, selected, streaming, disabled, and
   empty states.
4. Re-run the manual flows from `PRD-v2.md` §4 (⌥⇧S → pick → result; write +
   diff + replace; chat + continue in chat; menu bar; settings) to confirm no
   behavior regression.

## 12. AppKit panel recipe (P2 implementation reference)

The mockup's `backdrop-filter: blur(34px) saturate(1.7)` + translucent plum is
a browser stand-in for macOS vibrancy. Do not hand-roll blurs. Per panel:

1. Keep the existing `KeyablePanel` subclass and style masks (`.nonactivatingPanel`
   stays on every panel; `.resizable` stays on result/chat; picker/custom-prompt
   stay `.borderless`).
2. **Titlebars (titled panels only):** `panel.titlebarAppearsTransparent = true`,
   `panel.titleVisibility = .hidden`, and `panel.standardWindowButton(.closeButton)?.isHidden = true`
   (also `.miniaturizeButton`, `.zoomButton`) on result/chat. Settings hides the
   title text but **keeps** the traffic lights. This is the macOS 13-safe way to
   get the mockup's chrome-less look without switching to `.borderless` (which
   would break dragging/resizing).
3. **Rounded corners:** the window itself keeps system corners; the SwiftUI
   root view draws `RoundedRectangle(cornerRadius: Metric.rPanel, style: .continuous)`
   as its background so the content layer reads 18pt. For `.borderless` panels
   (picker, custom prompt) also set `panel.isOpaque = false` and
   `panel.backgroundColor = .clear` so the rounded corners actually show the
   desktop behind them.
4. **Vibrancy:** wrap the content in an `NSVisualEffectView`
   (`blendingMode: .behindWindow`, `material: .sidebar` or `.menu` — pick the
   closest to blur-34 by eye) and add a plum tint layer on top
   (`Ramp.plum50.opacity(0.58)` light / `Ramp.ink950.opacity(0.58)` dark — the
   mockup's `--glass` mixes). If a context forces opacity, fall back to
   `Tok.surfaceMuted` / `Tok.screen2` per IMPLEMENTATION §4.
5. **Hairline:** 0.5pt `Tok.line` stroke on the rounded rect, not the window.
6. **Shadow:** keep `panel.hasShadow = true` (native). Never draw the CSS
   shadow from README §Shadows — it is a browser stand-in.
7. **Sizes:** Result default 460×auto (min 360×280 stays), Settings 520×400,
   Chat 520×560 (already correct), picker/custom-prompt keep `fittingSize`.
8. Put all of this in `UI/Shared/PanelChrome.swift` as one helper
   (e.g. `PanelChrome.apply(to:)` + a `PanelBackground` SwiftUI view) so the
   five panel classes stay thin and consistent.

## 13. Markdown theme (P11)

The result body and assistant messages render through **MarkdownUI**, which
ships its own default theme (foreign fonts, its own heading/blockquote styles).
`markdownTextStyle` alone does not cover headings, lists, code, or blockquotes.
P11 adds a shared `MarkdownUI.Theme` built from tokens:

- Body text: system 13 (result) / 12.5 (chat), `Tok.fg`, line-height 1.58.
- Headings: system semibold, sized off body (h3 ≈ 12.5/620 per the mockup's
  `.md .h`), `Tok.fg`.
- Strong: 600 weight. Lists: disc, 18pt indent, 3pt row spacing (mockup `.md ul`).
- Code spans/blocks: `.monospaced` 12, `Tok.fill` background, `Metric.rControl`.
- Blockquote: `Tok.fill` bar + `Tok.fg2` text.
- Links: `Tok.accentStrong(scheme)` (never underlined by default).
- Streaming: while `isStreaming`, the Markdown container renders at 55% opacity
  (mockup `.md.is-loading`) — apply via `.opacity`, not by re-theming.

One theme, parameterized by size, lives in `UI/Shared/` and is used by both
`SummaryPopupView` and `ChatPopupView`. This is the only task allowed to touch
MarkdownUI configuration.

## 14. Interaction states (all custom controls)

IMPLEMENTATION §6 defines these; they apply to every task that draws a custom
control (P3–P8):

- **Hover** — background changes to `Tok.fill(scheme)`, foreground never changes.
  Applies to picker rows, menu rows, chips, xbtn, disclosure rows.
- **Press** — scale 0.98 or one ramp step darker; restore on release.
- **Focus ring** — `Tok.accentRing(scheme)`, 4pt, via `.overlay` on `.plain`
  controls only. Native `.bordered`/`.borderedProminent` already draw the
  system ring — do not double it.
- **Disabled** — the only state allowed to lose contrast (system default
  dimming is fine); every existing disabled rule (Replace, Diff while
  streaming, send button, Regenerate) stays exactly as-is.
- **Selected/last-used** — picker row: full-row `Tok.accentTint` + accent-strong
  check and key glyph.
- **Streaming** — gen-note in the result body (P3), blinking caret in chat (P4),
  Stop ■ replaces send ↑ (P4), Diff toggle disabled (P3, existing rule).

## 15. Accessibility

- **Contrast** — the token set was chosen for ≥4.5:1 on body text and ≥3:1 on
  glyphs (README §Palette documents the ratios). Do not introduce any color
  outside the tokens; if a state seems to need one, escalate rather than invent.
- **Hit targets** — custom rows/buttons keep ≥26pt height (mockup's smallest
  controls are 24–26pt; do not go below).
- **Keyboard** — every existing shortcut stays: picker 1–6/g–l/a/0/esc, ⌘↩
  Replace, ⌘T Chat, ⌘C Copy, ⌘R Regenerate, ⌘W close, Return send, esc cancel.
  Custom controls must remain focusable (`.focusable()` where `.plain` styling
  removes it) so Tab navigation still works.
- **VoiceOver** — keep the `help` tooltips that exist today; custom image-only
  buttons (✕, send, stop, copy) carry `.help()` or accessibility labels.
- **Reduced motion** — the chat streaming caret must respect
  `@Environment(\.accessibilityReduceMotion)` (no blinking; show a static
  "…" instead). The gen-note spinner may stay (it conveys progress) but must
  not pulse/scale.
- **Dark-mode testing is not optional** — every "Done when" in §9 requires both
  appearances.

## 16. Issue-filing metadata (when creating the GitHub issues)

Follow `.agents/skills/issue-contract/SKILL.md` and `.agents/config.json`.
Before filing, the config needs two additions (file a config-change issue or
edit `.agents/config.json` by hand — it is not a protected path):

- **Milestone:** `M6 - Visual parity` (does not exist yet; add to `milestones`).
- **Epic label:** `epic:7` (labels currently stop at `epic:6`); register the
  epic in `epics` with `milestone: M6`, `taskEpic: 7`.

Per task: `kind:task`, one `size:` (S/M/L as in §9), `area:` — `design` for P1,
`ui` for P2–P8, `utilities` for P9, `design` for P10/P11 — plus `agent:ready`
(or `agent:blocked` while a dependency is open). "Depends on" in the issue body
must list **issue numbers**, not P-IDs; the table below is the dependency graph
to translate:

| Task | Depends on | Size | Area |
|:--|:--|:--|:--|
| P1 | — | M | design |
| P2 | P1 | M | ui |
| P3 | P1, P2 | L | ui |
| P4 | P1, P2 | M | ui |
| P5 | P1, P2 | S | ui |
| P6 | P1 | S | ui |
| P7 | P1, P2 | M | ui |
| P8 | P1, P2 | S | ui |
| P9 | P1 | S | utilities |
| P10 | P3–P9 | S | design |
| P11 | P1 | S | ui |

Link every task as a native sub-issue of the Epic P issue. P3 and P9 both touch
`SummaryPopupViewModel.swift` — mark them mutually sequential in the issue
bodies (P9 after P3, or fold P9 into P3's branch).

## 17. Risks

| Risk | Impact | Mitigation |
|:--|:--|:--|
| Vibrancy + tint layer looks wrong (too purple / too gray) vs the mockup's blur-34 | Panels don't match | §12 gives the recipe + fallback tokens; tune material by eye against the mockup, one panel at a time (P2 gate) |
| Hiding traffic lights on result/chat breaks dragging or ⌘W | Usability regression | Keep `.titled` mask; only hide buttons + title (§12.2); verify drag/⌘W in P2's Done-when |
| `NSVisualEffectView` inside `NSHostingController` clips rounded corners | Visual artifact | Set `isOpaque = false` + clear background on borderless panels (§12.3); test picker first |
| MarkdownUI theme fights token colors (headings, code) | Result/chat body off-spec | P11 owns the theme; no other task may tweak MarkdownUI config |
| Custom segmented control loses keyboard/voiceover parity vs native | Accessibility regression | §15 rules; keep the native `Picker` binding underneath the custom chrome |
| PRD v4 (providers) reworks the same Settings/menu-bar files | Wasted/conflicting work | §6b sequencing rule: v4 first, then v3 |
| `.onHover` on picker rows adds latency on 16 rows | Picker feels sluggish | Plain `Color` fills, no animations on hover; measure by hand |
| macOS 13 API ceiling (no `@Observable`, no two-param `.onChange`) | Build breaks | All recipes in §12–§14 are 13-safe; reviewer checks imports |

## 18. Open questions

1. **Vibrancy material choice** — `.sidebar` vs `.menu` vs `.popover` for the
   panel background (§12.4). Decide by eye during P2; record the choice in the
   P2 handoff so P3–P8 don't relitigate it.
2. **Settings footer semantics** — the mockup shows Revert/Save, but settings
   persist live today. §4.6 allows a no-op Save; if real revert semantics are
   wanted, that is a behavior change and out of scope (file separately).
3. **Elapsed placement in Write mode** — frame 04 puts it in the footer, frame
   03 in the tools row. This PRD follows the frames per-mode (§4.3); if the
   product wants one consistent placement, decide before P3 lands.
4. **`epic:7` / `M6` registration** — who edits `.agents/config.json` (§16):
   fold into the Epic P filing issue or do it first; it blocks label automation.
5. **Chat panel width** — README says 520, mockup frames are 430. §6.5 keeps
   README's 520; confirm before P4 since it affects bubble max-widths (82%/88%).

## 19. Glossary

- **Token** — a named semantic value (`Tok.fg`, `Metric.rCard`) resolved per
  appearance; the only sanctioned way to reference color/size in a view.
- **Ramp** — the 11-step color families (`Ramp.violet600` etc.) backing tokens.
- **Surface** — one of the six screens: picker, result, chat, menu-bar popover,
  settings, custom prompt.
- **Panel** — the `NSPanel`/`KeyablePanel` window hosting a surface.
- **Frame** — a numbered mockup figure (02 picker, 03/04 result, 05/06 chat,
  07/08 popover, 09 settings).
- **Vibrancy** — macOS native translucency (`NSVisualEffectView`) standing in
  for the mockup's CSS `backdrop-filter`.

## 20. References

- `AGENTS.md` — hard constraints (§7 restates them).
- `.agents/skills/issue-contract/SKILL.md` + `.agents/config.json` — issue
  filing (§16).
- `Scripts/agent/pickup.sh` / `handoff.sh` — the per-task workflow these issues
  will run through.
- `tickets/PRD-v2.md` §4 — the flow baseline this PRD must not disturb.
- `tickets/PRD-v4-providers.md` — the overlapping PRD (§6b).

## 21. Changelog

- **rev 1 (2026-10-05)** — initial audit + task breakdown P1–P10.
- **rev 2 (2026-10-05, review pass)** — corrections: elapsed placement is
  per-mode (tools row Transform / footer Write, per frames 03/04); P9's file
  list includes `SummarizationOrchestrator.swift` (it calls `recomputeDiff`)
  and threads the scheme via a view-model property. Additions: §6a non-goals;
  §6b sequencing vs `PRD-v4-providers.md`; §6c copy deck; §12 AppKit panel
  recipe; §13 Markdown theme + task **P11**; §14 interaction states; §15
  accessibility; §16 issue-filing metadata (M6/epic:7 registration, dependency
  table); §17 risks; §18 open questions; §19 glossary; §20 references.
