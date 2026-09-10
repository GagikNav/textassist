import SwiftUI

/// SwiftUI view that defines the contents of the menu-bar dropdown menu.
struct MenuBarStatusView: View {
    let onSummarize: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button("Summarize Selection") {
                onSummarize()
            }

            Divider()

            Button("Settings…") {
                // Placeholder for the settings window (Phase 2).
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("Q")
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    MenuBarStatusView(onSummarize: {})
}
#endif
