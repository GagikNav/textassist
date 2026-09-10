import SwiftUI

@main
struct TextSummarizerApp: App {
    /// Stores summary styles and remembers the user's last choice.
    @StateObject private var styleStore: StyleStore

    /// Keeps the hotkey manager alive for the lifetime of the app.
    /// The manager registers its global shortcut as soon as it is created.
    @StateObject private var hotkeyManager: HotkeyManager

    /// Creates the app and shares a single `StyleStore` between
    /// the settings UI and the hotkey manager.
    init() {
        let store = StyleStore()
        let captureService = TextCaptureService()
        _styleStore = StateObject(wrappedValue: store)
        _hotkeyManager = StateObject(
            wrappedValue: HotkeyManager(
                textCaptureService: captureService,
                styleStore: store
            )
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarStatusView {
                Task {
                    await hotkeyManager.triggerSummarize()
                }
            }
        } label: {
            Image(systemName: "doc.text")
        }
        .menuBarExtraStyle(.window)
    }
}
