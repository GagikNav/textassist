import SwiftUI

@main
struct TextSummarizerApp: App {
    /// Keeps the hotkey manager alive for the lifetime of the app.
    /// The manager registers its global shortcut as soon as it is created.
    @StateObject private var hotkeyManager: HotkeyManager = {
        let captureService = TextCaptureService()
        return HotkeyManager(textCaptureService: captureService)
    }()

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
