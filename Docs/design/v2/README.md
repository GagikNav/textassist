# Text Assist v2 — Design tokens

Approved design contract for v2 (PRD task **T0.1**). Source of truth for the mockup
`text-assist-v2-mockup.html` in this folder and for the SwiftUI translation in
`IMPLEMENTATION.md`. Directions refine the ASCII sketches in `tickets/PRD-v2.md` §4;
they do not redesign flows.

Direction: **native macOS utility** — system SF display + SF text, mono numerics,
hairline borders, vibrancy panels, traffic-light window chrome. A menu-bar app, not a
web page.

## Palette (source of truth)

The brand palette is the supplied **four-color purple set**, bound verbatim as
`--brand-ink #2E073F`, `--brand-plum #7A1CAC`, `--brand-violet #AD49E1`,
`--brand-lavender #EBD3F8`. They anchor an 11-step accent ramp plus tonal neutral
families derived from the same hue; every semantic token below resolves to a step in
one of those ramps.

| Family | Prefix | Role |
|:--|:--|:--|
| violet | `--lg` | accent — selection, primary button, caret, user bubble |
| orchid | `--mo` | spare mid-tone neutral (unused in v2 chrome) |
| plum | `--pl` | light surfaces — panel base, dividers, hover fills |
| mauve | `--pt` | muted structural neutrals — gradients, unknown-dot |
| ink | `--ev` | deep plum — desktop backdrop, shadows (no longer text) |

**Neutral text is Apple's four-stop gray scale**, not a purple tint. Text tokens bind
to a separate ramp so the purple stays structural (chrome, accent) and body copy reads
neutral:

| Stop | Token | Light value | Dark value (inverse) | Use |
|:--|:--|:--|:--|:--|
| primary | `--gray-1` | `#1d1d1f` | `#f5f5f7` | titles, result body, primary labels |
| secondary | `--gray-2` | `#424245` | `#c7c7cc` | subtitles, disclosures, tabs |
| tertiary | `--gray-3` | `#6e6e73` | `#a1a1a6` | shortcut keys, elapsed, group labels |
| caption | `--gray-4` | `#86868b` | `#86868b` | glyphs/icons on light; small captions on dark |

`--fg / --fg-2 / --muted / --meta` are the semantic aliases (Apple's exact contract
names). On light plates body copy tops out at `--muted` (#6e6e73, ≈4.8:1) because
`--meta` (#86868b) falls below 4.5:1 on plum-50; `--meta` therefore serves glyphs/icons
on light (≥3:1) and small text on the dark backdrop (≈5.4:1).

**Anchors:** ink `#2E073F` = `--ev-900` (desktop backdrop / shadows); plum `#7A1CAC` =
`--lg-700` (focus ring / accent-as-text); violet `#AD49E1` = `--lg-500` (tints, caret);
lavender `#EBD3F8` = `--lg-200` (light tint).

Semantic exceptions the single hue range cannot express: `--red:#b3452c` (muted
terracotta) for offline state and removed diff, and `--green:#2e7d46` for online state
and added diff. Two out-of-palette colors, both marked — state hue is not brand hue.

## Color mapping

| Token | Resolves to | Use |
|:--|:--|:--|
| `--panel` | plum-50 @ 88% | floating panel surface (vibrancy) |
| `--panel-solid` | plum-50 → white | buttons, fields, raised controls |
| `--sunk` | plum-100 → white | input wells, "Original", segmented track |
| `--panel-fg` | gray-1 `#1d1d1f` | primary text |
| `--panel-mut` | gray-2 `#424245` | secondary text (≥8:1) |
| `--panel-dim` | gray-3 `#6e6e73` | tertiary: shortcut keys, elapsed (≈4.8:1) |
| `--caption` | gray-4 `#86868b` | glyphs/icons on light; small captions on dark |
| `--panel-hair` | plum-200 | dividers inside panels |
| `--panel-line` | ink-950 @ 13% | panel / control hairline |
| `--accent` | violet-600 `#9634C9` | primary button, toggle, send, caret |
| `--accent-fg` | **white** | text/icons **on** accent fills (5.8:1) |
| `--accent-strong` | violet-700 `#7A1CAC` | focus ring; accent as text/icon on light (7.1:1) |
| `--ok` / `--bad` | green `#2e7d46` / red `#b3452c` | Ollama online / offline dot |
| `--gray` | plum-500 | Ollama unknown dot |
| `--add` / `--add-bg` | green / green @ 18% | added diff text |
| `--del` / `--del-bg` | red / red @ 15% | removed diff text |
| `--accent-tint` | violet-500 @ 20% | selected row, user bubble |
| `--canvas` / `--canvas-2` | ink-950 / +mauve-900 | macOS desktop backdrop |

Accent fill (`--accent`, a violet step between the supplied `#AD49E1` and `#7A1CAC`)
carries **white** text at 5.8:1; a mid-tone accent filled with light text stays legible
where the raw `#AD49E1` would not (4.4:1). Accent hover darkens toward ink, never
lightens, so white text keeps its contrast. Diff red/green and the status dots are
**semantic**, not accent budget.

## Appearance (Light / Dark)

The mockup ships a **Light / Dark** switch in the board header (mirroring macOS System
Settings → Appearance). It sets `[data-appearance="dark"]` on the document, rebinding
only the *product* tokens below; the desktop backdrop (`--canvas-*`) is fixed so the
review board itself never inverts. In the app this is simply the system appearance
(light/dark), so implement both from `colorScheme` / `NSAppearance`.

| Token | Light | Dark |
|:--|:--|:--|
| `--screen` | — (n/a) | ink-950 → black @ 58% (near-black plate) |
| `--panel` | plum-50 @ 88% | `--screen` — near-black window fill |
| `--panel-solid` | plum-50 → white | `--screen-2` = ink-950 → black @ 76% (near-black raised) |
| `--sunk` | plum-100 → white | ink-950 → black @ 36% (deeper well) |
| `--panel-fg` | gray-1 `#1d1d1f` | gray-1d `#f5f5f7` |
| `--panel-mut` | gray-2 `#424245` | gray-2d `#c7c7cc` |
| `--panel-dim` | gray-3 `#6e6e73` | gray-3d `#a1a1a6` |
| `--caption` | gray-4 `#86868b` | gray-4d `#86868b` |
| `--panel-hair` | plum-200 | white @ 12% |
| `--panel-line` | ink-950 @ 13% | white @ 17% |
| `--panel-fill` / `--panel-fill2` | plum-100 / plum-200 | white @ 10% / 22% |
| `--accent` | violet-600 | violet-600 |
| `--accent-strong` | violet-700 (on light) | violet-400 (on dark) |
| `--glass` / `--strip` / `--foot` / `--field-bg` | white-tinted translucents | ink / faint-white translucents |
| `--red` / `--green` | terracotta / forest | `#e07a5f` / `#5fbf7a` (≥4.5:1) |

The filled accent stays a **violet-600** step with **white** text in both appearances
(5.8:1). Dark mode lightens the *accent-as-text* token (`--accent-strong` → violet-400)
rather than the fill, so button labels and focus rings never lose contrast. Text/icon
semantic red and green are lightened in dark so the diff and status dots stay ≥4.5:1 on
the dark plate.

**Dark surfaces are near-black.** In dark appearance every *screen* (picker, result
popup, chat, menu-bar popover, settings window) renders on a near-black ink plate
(`--screen` = ink-950 mixed 58% toward black, `--screen-2` = 76% for raised controls)
instead of the lighter ink-900 fill. The purple survives only as accent, selection tint,
and the desktop backdrop behind the windows.

## Type

System macOS faces. Sizes in px.

| Role | Size / weight | Notes |
|:--|:--|:--|
| Panel title | 13.5 / 600 | picker group rows are 10.5 uppercase |
| Body, result, chat | 13 / 400 | diff line-height 1.75 |
| Caption, labels | 11 / 400 | `.fsub` 11 muted |
| Mono | 12 / 400 | shortcut keys, elapsed time, model name, all numerics (tabular) |

## Spacing & radius

Spacing scale: `4 · 8 · 12 · 16 · 20`. Row padding inside panels `5–8`. Radius follows
Apple's three tiers: control `8` (`--r-sm`) · card, popover, field `12` (`--r-md`) ·
floating panel and settings window `18` (`--r-lg`). Circular controls stay `50%`;
capsule toggles and pills stay `999px`. Every corner in the UI resolves to one of these.

## Shadows

- Floating panel: `0 22px 64px -20px ink-950 @ .62, 0 2px 8px @ .26`
- Raised control: `0 1px 2px ink-950 @ .16`
- Panel edge: hairline `0.5px ink-950 @ .13`

## macOS chrome

- **Global menu bar** above each status-item popover: app name, File/Edit/View/Window/Help,
  control-center glyphs, the highlighted Text Assist status item, clock. The popover is
  anchored to the item with a beak.
- **Settings** is a standard window: traffic lights, centered title, tab row.
- Buttons map to AppKit styles; toggles and segmented controls are native-feeling.

## Button styles (SwiftUI mapping)

| Mockup | SwiftUI |
|:--|:--|
| `Replace ⌘↩` (filled accent) | `.buttonStyle(.borderedProminent)` + `.keyboardShortcut(.return, modifiers: .command)` |
| `Copy` / `Regenerate` (bordered) | `.buttonStyle(.bordered)` |
| `Chat ⌘T` (text only) | `.buttonStyle(.borderless)` |
| Picker / menu-bar rows | `.buttonStyle(.plain)` |

## Components defined

- **Appearance switch** — board-header Light / Dark segmented control; rebinds product
  tokens (see *Appearance*). In the app, follow the system appearance.
- **Picker** — 4 groups (Transform / Write / Chat / Custom), 240 wide, auto-sized to fit
  all 16 rows + Cancel with no clipping. Last-used check in accent. `esc` cancels.
- **Result · Transform** — Markdown body, style dropdown, "Original (n words)"
  disclosure, Copy · Regenerate · Chat ⌘T, elapsed in mono. No Diff, no Replace.
- **Result · Write** — plain-text body, Clean/Diff segmented toggle (Diff disabled while
  streaming), Replace ⌘↩ (disabled unless a real selection + non-empty result), Chat ⌘T,
  elapsed.
- **Chat** — title bar, pinned selection card (collapsed / expanded, max 140), starter
  chips only when empty, user bubble (accent tint, right), assistant Markdown (left) +
  hover Copy/Regenerate, streaming caret, Stop ■ button, input bar (Return sends).
- **Menu-bar popover** — status dot (ok / gray / bad) + `Ollama · <model>`, offline
  caption, model picker, Assist ⌥⇧S, Settings…, Recent (P1), Quit ⌘Q.
- **Settings** — General tab: hotkey recorders (Assist ⌥⇧S, Chat ⌥⇧C, Fix grammar ⌥⇧G)
  and Launch-at-login toggle; Provider tab unchanged.

## Panel sizes

| Surface | Default | Minimum |
|:--|:--|:--|
| Style picker | content-fitting (~240 × 520) | — |
| Result popup | 460 × auto | — |
| Chat popup | 520 × 560 | 380 × 320 |
| Settings | 520 × 400 | — |

## Empty / edge states

- Chat with a selection but no turns → starter chips.
- Ollama offline → red dot + "Not running. Start Ollama and try again."; `unknown` while
  checking.
- Replace disabled when capture origin is `fieldValue` or the app has no PID.
