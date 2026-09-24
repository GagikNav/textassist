import SwiftUI

/// The SwiftUI content of the style picker panel.
///
/// Shows a vertical list of summary styles. Each style can be selected with
/// its shortcut key (`1`–`6` and `0`). Pressing `Escape` cancels.
struct StylePickerView: View {
    /// All styles to display.
    let styles: [SummaryStyle]

    /// The ID of the style used most recently, highlighted with a checkmark.
    let lastUsedStyleID: String

    /// Called when the user picks a style.
    let onSelect: (SummaryStyle) -> Void

    /// Called when the user cancels with `Escape`.
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(styles, id: \.id) { style in
                Button {
                    onSelect(style)
                } label: {
                    HStack(spacing: 8) {
                        Text(style.shortcutKey)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 20, alignment: .center)

                        Text(style.name)
                            .foregroundStyle(.primary)

                        Spacer()

                        if style.id == lastUsedStyleID {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 2)
                .keyboardShortcut(KeyEquivalent(Character(style.shortcutKey)), modifiers: [])
            }

            Divider()
                .padding(.vertical, 4)

            Button {
                onCancel()
            } label: {
                HStack(spacing: 8) {
                    Text("esc")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, alignment: .center)

                    Text("Cancel")
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)
            .keyboardShortcut(.cancelAction)
        }
        .padding(12)
        .frame(width: 220)
    }
}

#if DEBUG
#Preview {
    StylePickerView(
        styles: SummaryStyle.builtIn,
        lastUsedStyleID: SummaryStyle.bulletPoints.id,
        onSelect: { _ in },
        onCancel: { }
    )
}
#endif
