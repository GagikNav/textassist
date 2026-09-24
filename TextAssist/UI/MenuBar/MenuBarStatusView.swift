import SwiftUI

/// SwiftUI view that defines the contents of the menu-bar dropdown menu.
struct MenuBarStatusView: View {
    let onSummarize: () -> Void
    let onSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button("Summarize Selection") {
                onSummarize()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)

            Divider()

            Button("Settings…") {
                onSettings()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .keyboardShortcut("Q")
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    MenuBarStatusView(onSummarize: {}, onSettings: {})
}
#endif
