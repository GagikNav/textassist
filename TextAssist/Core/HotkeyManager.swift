import KeyboardShortcuts
import Foundation
import AppKit
import Combine

/// Names used by KeyboardShortcuts to store the global shortcuts.
extension KeyboardShortcuts.Name {
    static let summarizeSelection = Self("summarizeSelection", initial: .init(.s, modifiers: [.option, .shift]))
    static let chatWithSelection = Self("chatWithSelection", initial: .init(.c, modifiers: [.option, .shift]))
    static let fixGrammar = Self("fixGrammar", initial: .init(.g, modifiers: [.option, .shift]))
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

    /// Registers the global shortcuts. Called automatically during initialization.
    func registerShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .summarizeSelection) { [weak self] in
            Task { [weak self] in
                await self?.triggerSummarize()
            }
        }

        KeyboardShortcuts.onKeyUp(for: .chatWithSelection) { [weak self] in
            Task { [weak self] in
                await self?.triggerDirect(SummaryStyle.chatWithSelection)
            }
        }

        KeyboardShortcuts.onKeyUp(for: .fixGrammar) { [weak self] in
            Task { [weak self] in
                await self?.triggerDirect(SummaryStyle.fixGrammar)
            }
        }
    }

    /// Triggers a summarization via the orchestrator.
    /// This is used by the global hotkey.
    func triggerSummarize() async {
        await orchestrator.startSummarization()
    }

    /// Runs a style straight away, skipping the style picker.
    /// - Parameter style: The style to apply to the current selection.
    func triggerDirect(_ style: SummaryStyle) async {
        await orchestrator.startDirect(style: style)
    }
}
