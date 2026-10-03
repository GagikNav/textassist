# Text Assist v2 — SwiftUI implementation guide

Companion to `README.md` (token spec) and `text-assist-v2-mockup.html` (visual).
This file translates the approved tokens into drop-in SwiftUI values so an
implementation agent never has to guess a color, size, or radius. It **adds no new
design decisions** — where this file and `README.md` disagree, `README.md` wins.

Deployment target is **macOS 13.0**, Swift 5 language mode, `MainActor` default. Every
snippet below is macOS 13-safe. Create `TextAssist/UI/Shared/Palette.swift` (or a
similarly named shared file); it is compiled automatically through the synchronized
group — do not touch `project.pbxproj`.

## 1. Palette

The palette is the supplied four anchors (`#2E073F #7A1CAC #AD49E1 #EBD3F8`) expanded
into ramps. Bind the ramps once, then reference semantic tokens — never raw hexes at a
call site.

```swift
import SwiftUI

extension Color {
    /// `Color(hex: 0x9634C9)` — sRGB, opaque unless `opacity` is supplied.
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >>  8) & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Raw ramps — mirror of `README.md` §Palette. Anchors are marked.
enum Ramp {
    // violet — accent
    static let violet50  = Color(hex: 0xFBF6FE)
    static let violet100 = Color(hex: 0xF5E7FC)
    static let violet200 = Color(hex: 0xEBD3F8)   // anchor: lavender
    static let violet300 = Color(hex: 0xDDACEF)
    static let violet400 = Color(hex: 0xC87BEB)
    static let violet500 = Color(hex: 0xAD49E1)   // anchor: violet
    static let violet600 = Color(hex: 0x9634C9)   // accent fill
    static let violet700 = Color(hex: 0x7A1CAC)   // anchor: plum
    static let violet800 = Color(hex: 0x5C1482)
    static let violet900 = Color(hex: 0x400A59)
    static let violet950 = Color(hex: 0x2E073F)   // anchor: ink

    // plum — light surfaces
    static let plum50  = Color(hex: 0xFAF7FC)
    static let plum100 = Color(hex: 0xF2EBF6)
    static let plum200 = Color(hex: 0xE5D9ED)
    static let plum500 = Color(hex: 0x9882A9)     // unknown status dot

    // mauve — muted structural neutrals
    static let mauve400 = Color(hex: 0x9E89A6)    // unknown dot, dark
    static let mauve900 = Color(hex: 0x241B28)    // desktop gradient stop

    // ink — deep plum backdrop / shadows
    static let ink950 = Color(hex: 0x1C0428)
    static let ink900 = Color(hex: 0x2E073F)

    // neutral text — Apple's four-stop gray, inverse stops for dark
    static let gray1  = Color(hex: 0x1D1D1F)
    static let gray2  = Color(hex: 0x424245)
    static let gray3  = Color(hex: 0x6E6E73)
    static let gray4  = Color(hex: 0x86868B)
    static let gray1d = Color(hex: 0xF5F5F7)
    static let gray2d = Color(hex: 0xC7C7CC)
    static let gray3d = Color(hex: 0xA1A1A6)

    // semantic status — flagged out-of-palette
    static let green = Color(hex: 0x2E7D46)
    static let red   = Color(hex: 0xB3452C)
    static let greenD = Color(hex: 0x5FBF7A)      // dark, ≥4.5:1
    static let redD   = Color(hex: 0xE07A5F)      // dark, ≥4.5:1
}
```

### Semantic tokens

Resolve per appearance with a single entry point so no view hard-codes light/dark.

```swift
/// Semantic color tokens. `scheme` comes from `@Environment(\.colorScheme)`.
enum Tok {
    static let accent      = Ramp.violet600
    static let accentFg    = Color.white                    // on any accent fill (5.8:1)
    static func accentStrong(_ s: ColorScheme) -> Color {   // accent as text/icon/focus
        s == .dark ? Ramp.violet400 : Ramp.violet700
    }
    static func accentTint(_ s: ColorScheme) -> Color {     // selected row, user bubble
        Ramp.violet500.opacity(s == .dark ? 0.26 : 0.20)
    }
    static func accentRing(_ s: ColorScheme) -> Color {     // focus ring
        (s == .dark ? Ramp.violet400 : Ramp.violet600).opacity(s == .dark ? 0.62 : 0.55)
    }

    // text ramp
    static func fg(_ s: ColorScheme)  -> Color { s == .dark ? Ramp.gray1d : Ramp.gray1 }
    static func fg2(_ s: ColorScheme) -> Color { s == .dark ? Ramp.gray2d : Ramp.gray2 }
    static func dim(_ s: ColorScheme) -> Color { s == .dark ? Ramp.gray3d : Ramp.gray3 }
    static let caption = Ramp.gray4                          // same both modes

    // screens (opaque fallback; prefer materials, see §5)
    static let screen  = Color(hex: 0x100217)   // ink-950 58% → black
    static let screen2 = Color(hex: 0x15031E)   // ink-950 76% → black
    static let sunk    = Color(hex: 0x0A010E)   // dark input well (dark mode)
    static let surfaceMuted = Color(hex: 0xFCFBFD) // plum-50 → white (light raised)
    static let sunkLight    = Color(hex: 0xF5EFF8) // plum-100 → white (light well)

    // borders
    static func hair(_ s: ColorScheme) -> Color {           // dividers inside panels
        s == .dark ? Color.white.opacity(0.12) : Ramp.plum200
    }
    static func line(_ s: ColorScheme) -> Color {           // panel / control hairline
        s == .dark ? Color.white.opacity(0.17) : Ramp.ink950.opacity(0.13)
    }
    static func fill(_ s: ColorScheme) -> Color {           // hover row / segmented track
        s == .dark ? Color.white.opacity(0.10) : Ramp.plum100
    }
    static func fill2(_ s: ColorScheme) -> Color {
        s == .dark ? Color.white.opacity(0.22) : Ramp.plum200
    }

    // status + diff
    static func ok(_ s: ColorScheme)  -> Color { s == .dark ? Ramp.greenD : Ramp.green }
    static func bad(_ s: ColorScheme) -> Color { s == .dark ? Ramp.redD   : Ramp.red }
    static func unknown(_ s: ColorScheme) -> Color {
        s == .dark ? Ramp.mauve400 : Ramp.plum500
    }
    static func add(_ s: ColorScheme) -> Color { s == .dark ? Ramp.greenD : Ramp.green }
    static func addBg(_ s: ColorScheme) -> Color { add(s).opacity(s == .dark ? 0.22 : 0.18) }
    static func del(_ s: ColorScheme) -> Color { s == .dark ? Ramp.redD : Ramp.red }
    static func delBg(_ s: ColorScheme) -> Color { del(s).opacity(s == .dark ? 0.20 : 0.15) }
}
```

The opaque `screen` values are resolved references for the mockup's mixes
(`ink-950 58% → black` ≈ `#100217`, `76% → black` ≈ `#15031E`). If you change the mix in
the mockup, recompute these.

## 2. Typography

System faces only; no bundled fonts. Display and body are both SF, split by role.

| Role | SwiftUI |
|:--|:--|
| Panel title | `.font(.system(size: 13.5, weight: .semibold))` |
| Body / result / chat | `.font(.system(size: 13))` |
| Caption / label | `.font(.system(size: 11))` |
| Picker group row | `.font(.system(size: 10.5, weight: .semibold)).textCase(.uppercase)` |
| Mono (shortcut, elapsed, model) | `.font(.system(size: 12, design: .monospaced)).monospacedDigit()` |

Body line spacing for the diff is `1.75`; use `.lineSpacing` on the diff `Text` only.

## 3. Spacing, radius, sizing

```swift
enum Metric {
    // spacing scale
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let rowPad: CGFloat = 6      // panel row padding 5–8

    // radius — Apple's three tiers; every corner is one of these
    static let rControl: CGFloat = 8    // --r-sm: buttons, chips, menu rows, picker rows
    static let rCard: CGFloat = 12      // --r-md: cards, popovers, menus, fields, bubbles
    static let rPanel: CGFloat = 18     // --r-lg: floating panels, settings window

    // panel sizes (default / minimum)
    static let pickerWidth: CGFloat = 240
    static let resultWidth: CGFloat = 460
    static let chatSize = CGSize(width: 520, height: 560)
    static let chatMin  = CGSize(width: 380, height: 320)
    static let settingsSize = CGSize(width: 520, height: 400)
}
```

Use continuous corners: `RoundedRectangle(cornerRadius: Metric.rCard, style: .continuous)`.
Circular controls keep `Circle()`; capsule toggles/pills use `Capsule()`.

## 4. Shadows and materials

Do **not** hand-roll the CSS shadows in the app — the floating panels are `NSPanel`s, so
use the window's native shadow (`panel.hasShadow = true`) and let macOS draw it. The
mockup's CSS shadow (`0 22px 64px -20px ink-950 @ .62`) is only a browser stand-in.
Within SwiftUI content, the only sanctioned shadow is the small raised-control one:
`.shadow(color: Ramp.ink950.opacity(0.16), radius: 1, y: 1)`.

For the panel vibrancy, use native material instead of the translucent plum mix:

```swift
// floating panel / popover background
.background(.regularMaterial)          // or an NSVisualEffectView wrapper for tuning
// input wells, "Original" disclosure, segmented track
.background(.thinMaterial)
```

When vibrancy is unavailable (e.g. a forced-opaque context), fall back to
`Tok.surfaceMuted` (light) / `Tok.screen2` (dark).

## 5. Component → file → task map

Build to the mockup; each surface maps to the PRD task that owns it.

| Surface | Files | Task |
|:--|:--|:--|
| Picker v2 (grouped, letters, auto-size) | `UI/StylePicker/StylePickerView.swift`, `StylePickerPanel.swift` | T2.2, T3.3 |
| Result · Transform / Write | `UI/Popup/SummaryPopupView.swift`, `SummaryPopupViewModel.swift` | T3.1–T3.5 |
| Diff (Clean ⇄ Diff) | `Utilities/TextDiffer.swift` + popup | T3.2 |
| Replace in place | `Core/TextReplacementService.swift`, `Utilities/PasteboardSnapshot.swift` | T3.4 |
| Chat popup | `UI/Chat/ChatPopupView.swift`, `ChatViewModel.swift`, `ChatPopup.swift` | T4.1–T4.4 |
| Menu-bar popover | `UI/MenuBar/MenuBarStatusView.swift` | T5.2, T6.3, T6.4 |
| Settings · General | `UI/Settings/*` | T6.2 |
| Shared tokens | `UI/Shared/Palette.swift` (new) | T1.1 |

Full new/changed file list: `tickets/PRD-v2.md` §6.

## 6. Interaction states

- **Focus ring** — `Tok.accentRing(scheme)`, 4px, applied via `.overlay` on custom
  (`.plain`) controls and `.focusable()`. Native `.bordered` / `.borderedProminent`
  already draw the system ring; do not double it.
- **Hover** — change the background, never the foreground. Row/module hover:
  `Tok.fill(scheme)`. Filled accent button hover darkens toward ink (never lightens) so
  white labels keep contrast; use a violet-700 press tone.
- **Active/press** — reduce scale slightly (0.98) or shift fill one ramp step darker.
- **Disabled** — this is the only state allowed to lower contrast. Replace is disabled
  unless capture origin is a real selection AND the result is non-empty AND the source
  app has a PID.
- **Streaming** — Write diffs and the Chat Stop ■ button are disabled until the stream
  ends; show a caret while streaming.

## 7. Empty and edge states

- **Chat, selection but no turns** — starter chips only (see mockup); hide once a turn
  exists.
- **Ollama status dot** — `ok` (green) online, `bad` (red) offline + "Not running. Start
  Ollama and try again.", `unknown` (plum/mauve) while checking.
- **Pinned selection card** — collapsed by default; expanded caps at 140pt then scrolls.
- Sample copy in the mockup (`I has a apple`, word counts) is display text for review
  only; do not ship it as product copy.
