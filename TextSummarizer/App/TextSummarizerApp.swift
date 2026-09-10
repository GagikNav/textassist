import SwiftUI

@main
struct TextSummarizerApp: App {
    /// Stores Ollama base URL and model.
    @StateObject private var settings: SettingsStore

    /// Stores summary styles and remembers the user's last choice.
    @StateObject private var styleStore: StyleStore

    /// Coordinates capture → style picker → provider → popup.
    @StateObject private var orchestrator: SummarizationOrchestrator

    /// Keeps the hotkey manager alive for the lifetime of the app.
    /// The manager registers its global shortcut as soon as it is created.
    @StateObject private var hotkeyManager: HotkeyManager

    /// Shared provider instance used by both the orchestrator and settings UI.
    private let provider: any LLMProvider

    /// Floating settings panel shown from the menu bar.
    private let settingsPanel: SettingsPanel

    /// Creates the app and shares a single set of services between
    /// the settings UI, menu bar, and hotkey manager.
    init() {
        let settings = SettingsStore()
        let store = StyleStore()
        let captureService = TextCaptureService()
        let provider: any LLMProvider = OllamaProvider(settings: settings)
        let orchestrator = SummarizationOrchestrator(
            textCaptureService: captureService,
            styleStore: store,
            llmProvider: provider
        )

        self.provider = provider
        self.settingsPanel = SettingsPanel(settings: settings, provider: provider)
        _settings = StateObject(wrappedValue: settings)
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
            } onSettings: {
                settingsPanel.show()
            }
        } label: {
            Image(systemName: "doc.text")
        }
        .menuBarExtraStyle(.window)
    }
}
