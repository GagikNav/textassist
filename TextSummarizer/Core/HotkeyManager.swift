import KeyboardShortcuts
import Foundation
import AppKit
import Combine

/// Name used by KeyboardShortcuts to store the global "summarize selection" shortcut.
extension KeyboardShortcuts.Name {
    static let summarizeSelection = Self("summarizeSelection", initial: .init(.s, modifiers: [.option, .shift]))
}

/// Registers and handles the global hotkey that triggers text capture.
final class HotkeyManager: ObservableObject {
    private let textCaptureService: any TextCapturing

    /// Creates a hotkey manager with the given text capture service.
    /// The global shortcut is registered immediately.
    /// - Parameter textCaptureService: The service used to read the current selection.
    init(textCaptureService: any TextCapturing) {
        self.textCaptureService = textCaptureService
        registerShortcuts()
    }

    /// Registers the global shortcut. Called automatically during initialization.
    func registerShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .summarizeSelection) { [weak self] in
            Task { [weak self] in
                await self?.handleSummarizeShortcut()
            }
        }
    }

    /// Called whenever the user presses the summarize shortcut.
    private func handleSummarizeShortcut() async {
        await triggerSummarize()
    }

    /// Triggers a text capture and prints the result to the console.
    /// This is used by both the global hotkey and the menu-bar menu.
    func triggerSummarize() async {
        do {
            let captured = try await textCaptureService.captureSelection()
            print("Captured from: \(captured.sourceAppName)")
            print("Selected text:\n\(captured.text)")
        } catch let error as CaptureError {
            print("Capture failed: \(error.localizedDescription)")
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
        }
    }
}
