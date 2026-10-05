import SwiftUI

@main
struct TextAssistApp: App {
    /// Stores Ollama base URL and model.
    @StateObject private var settings: SettingsStore

    /// Stores summary styles and remembers the user's last choice.
    @StateObject private var styleStore: StyleStore

    /// Stores and persists the most recent results.
    @StateObject private var historyStore: HistoryStore

    /// Coordinates capture → style picker → provider → popup.
    @StateObject private var orchestrator: SummarizationOrchestrator

    /// Keeps the hotkey manager alive for the lifetime of the app.
    /// The manager registers its global shortcut as soon as it is created.
    @StateObject private var hotkeyManager: HotkeyManager

    /// Tracks Ollama reachability and available models for the menu bar.
    @StateObject private var statusMonitor: OllamaStatusMonitor

    /// Shared provider instance used by both the orchestrator and settings UI.
    private let provider: any LLMProvider

    /// Floating settings panel shown from the menu bar.
    private let settingsPanel: SettingsPanel

    /// Creates the app and shares a single set of services between
    /// the settings UI, menu bar, and hotkey manager.
    init() {
        let settings = SettingsStore()
        let store = StyleStore()
        let history = HistoryStore()
        let captureService = TextCaptureService()
        let provider: any LLMProvider = OllamaProvider(settings: settings)
        let orchestrator = SummarizationOrchestrator(
            textCaptureService: captureService,
            styleStore: store,
            llmProvider: provider,
            historyStore: history
        )

        self.provider = provider
        _statusMonitor = StateObject(wrappedValue: OllamaStatusMonitor(provider: provider))
        self.settingsPanel = SettingsPanel(settings: settings, provider: provider)
        _settings = StateObject(wrappedValue: settings)
        _styleStore = StateObject(wrappedValue: store)
        _historyStore = StateObject(wrappedValue: history)
        _orchestrator = StateObject(wrappedValue: orchestrator)
        _hotkeyManager = StateObject(
            wrappedValue: HotkeyManager(orchestrator: orchestrator)
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarStatusView(
                settings: settings,
                monitor: statusMonitor,
                history: historyStore,
                onSummarize: {
                    Task {
                        await hotkeyManager.triggerSummarize()
                    }
                },
                onSettings: {
                    settingsPanel.show()
                },
                onReopen: { entry in
                    orchestrator.reopen(entry)
                }
            )
        } label: {
            Image("MenuBarIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .menuBarExtraStyle(.window)
    }
}
