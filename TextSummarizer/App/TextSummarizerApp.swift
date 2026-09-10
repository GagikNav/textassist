import SwiftUI

@main
struct TextSummarizerApp: App {
    /// Stores summary styles and remembers the user's last choice.
    @StateObject private var styleStore: StyleStore

    /// Coordinates capture → style picker → provider → popup.
    @StateObject private var orchestrator: SummarizationOrchestrator

    /// Keeps the hotkey manager alive for the lifetime of the app.
    /// The manager registers its global shortcut as soon as it is created.
    @StateObject private var hotkeyManager: HotkeyManager

    /// Creates the app and shares a single set of services between
    /// the settings UI, menu bar, and hotkey manager.
    init() {
        let store = StyleStore()
        let captureService = TextCaptureService()
        let provider = OllamaProvider()
        let orchestrator = SummarizationOrchestrator(
            textCaptureService: captureService,
            styleStore: store,
            llmProvider: provider
        )

        _styleStore = StateObject(wrappedValue: store)
        _orchestrator = StateObject(wrappedValue: orchestrator)
        _hotkeyManager = StateObject(
            wrappedValue: HotkeyManager(orchestrator: orchestrator)
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
