import KeyboardShortcuts
import Foundation
import AppKit
import Combine

/// Name used by KeyboardShortcuts to store the global "summarize selection" shortcut.
extension KeyboardShortcuts.Name {
    static let summarizeSelection = Self("summarizeSelection", initial: .init(.s, modifiers: [.option, .shift]))
}

/// Registers the global hotkey and forwards triggers to the orchestrator.
///
/// The orchestrator owns the actual flow: capture, style picker, provider
/// stream, and popup.
@MainActor
final class HotkeyManager: ObservableObject {
    private let orchestrator: SummarizationOrchestrator

    /// Creates a hotkey manager that forwards actions to the orchestrator.
    /// The global shortcut is registered immediately.
    /// - Parameter orchestrator: The object that owns the summarization flow.
    init(orchestrator: SummarizationOrchestrator) {
        self.orchestrator = orchestrator
        registerShortcuts()
    }

    /// Registers the global shortcut. Called automatically during initialization.
    func registerShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .summarizeSelection) { [weak self] in
            Task { [weak self] in
                await self?.triggerSummarize()
            }
        }
    }

    /// Triggers a summarization via the orchestrator.
    /// This is used by both the global hotkey and the menu-bar menu.
    func triggerSummarize() async {
        await orchestrator.startSummarization()
    }
}
