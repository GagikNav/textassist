---
description: "Rules for SwiftUI/AppKit views in TextAssist/UI — macOS 13 API limits, the approved v2 design tokens, and the non-activating panel pattern. Apply when editing any UI file."
applyTo: "TextAssist/UI/**"
---

# TextAssist UI rules

- **Design is frozen.** Use the tokens in `Docs/design/v2/IMPLEMENTATION.md`
  (`Palette`, `Ramp`, `Tok`) and the layout in `text-assist-v2-mockup.html`. Do not
  invent colors, sizes, radii, or flows.
- **macOS 13.0 only.** Do not use `@Observable`, `onKeyPress`, the two-parameter
  `.onChange(of:)`, `Inspector`, or any newer API. Allowed: `TextField(axis: .vertical)`,
  `ScrollView.scrollContentBackground`, `formStyle(.grouped)`, `SMAppService`,
  `AttributedString`, `Layout`.
- **Panels stay non-activating** (`KeyablePanel`, `.nonactivatingPanel`); the source app
  must remain frontmost so Replace works.
- **View models** are `@MainActor ObservableObject` with `@Published` state; views are
  plain SwiftUI structs. Keep `#Preview` blocks compiling.
- No `project.pbxproj` edits — new files under `TextAssist/` compile automatically.
