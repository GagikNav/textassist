import SwiftUI
import AppKit

/// A floating settings panel for the menu-bar app.
///
/// SwiftUI's `Settings` scene does not integrate with `MenuBarExtra` apps on
/// macOS 13, so we open a dedicated non-activating panel from the menu bar.
@MainActor
final class SettingsPanel {
    private let settings: SettingsStore
    private let provider: any LLMProvider
    private var panel: KeyablePanel?

    /// Creates the settings panel.
    /// - Parameters:
    ///   - settings: The store that holds user-configurable values.
    ///   - provider: The LLM provider used to fetch available models.
    init(settings: SettingsStore, provider: any LLMProvider) {
        self.settings = settings
        self.provider = provider
    }

    /// Shows the settings panel near the center of the main screen.
    /// If the panel is already open, it is brought to the front.
    func show() {
        if let panel {
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let settingsView = SettingsView(settings: settings, provider: provider)
        let hostingController = NSHostingController(rootView: settingsView)
        hostingController.view.frame = CGRect(origin: .zero, size: CGSize(width: 420, height: 220))

        let panel = KeyablePanel(
            contentRect: hostingController.view.bounds,
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.title = "Text Assist Settings"
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.contentView = hostingController.view
        panel.center()

        panel.onClose = { [weak self] in
            self?.panel = nil
        }

        self.panel = panel
        panel.makeKeyAndOrderFront(nil)
    }

    /// Closes and releases the panel.
    func close() {
        panel?.close()
        panel = nil
    }
}
