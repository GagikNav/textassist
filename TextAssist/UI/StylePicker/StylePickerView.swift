import SwiftUI

/// The SwiftUI content of the style picker panel.
///
/// Shows styles grouped by category. Each style is selected with its shortcut
/// key (digits for Transform, letters for Write and Chat, `0` for Custom).
/// Pressing `Escape` cancels.
struct StylePickerView: View {
    /// All styles to display.
    let styles: [SummaryStyle]

    /// The ID of the style used most recently, highlighted with a checkmark.
    let lastUsedStyleID: String

    /// Called when the user picks a style.
    let onSelect: (SummaryStyle) -> Void

    /// Called when the user cancels with `Escape`.
    let onCancel: () -> Void

    private struct PickerGroup: Identifiable {
        let id: String
        let title: String?
        let styles: [SummaryStyle]
    }

    private var groups: [PickerGroup] {
        [
            PickerGroup(id: "transform", title: "Transform", styles: styles.filter { $0.category == .transform }),
            PickerGroup(id: "write", title: "Write", styles: styles.filter { $0.category == .write }),
            PickerGroup(id: "chat", title: "Chat", styles: styles.filter { $0.category == .chat }),
            PickerGroup(id: "custom", title: nil, styles: styles.filter { $0.category == .custom })
        ]
        .filter { !$0.styles.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(groups) { group in
                if let title = group.title {
                    Text(title.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                        .padding(.leading, 4)
                } else {
                    Divider().padding(.vertical, 4)
                }

                ForEach(group.styles, id: \.id) { style in
                    row(for: style)
                }
            }

            Divider().padding(.vertical, 4)

            Button {
                onCancel()
            } label: {
                HStack(spacing: 8) {
                    Text("esc")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, alignment: .center)
                    Text("Cancel").foregroundStyle(.secondary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)
            .keyboardShortcut(.cancelAction)
        }
        .padding(12)
        .frame(width: 240)
    }

    private func row(for style: SummaryStyle) -> some View {
        Button {
            onSelect(style)
        } label: {
            HStack(spacing: 8) {
                Text(style.shortcutKey)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 20, alignment: .center)

                Text(style.name).foregroundStyle(.primary)

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
}

#if DEBUG
#Preview {
    StylePickerView(
        styles: SummaryStyle.builtIn,
        lastUsedStyleID: SummaryStyle.fixGrammar.id,
        onSelect: { _ in },
        onCancel: { }
    )
}
#endif
