import KeyboardShortcuts
import Foundation
import AppKit
import Combine

/// Name used by KeyboardShortcuts to store the global "summarize selection" shortcut.
extension KeyboardShortcuts.Name {
    static let summarizeSelection = Self("summarizeSelection", initial: .init(.s, modifiers: [.option, .shift]))
}

/// Registers and handles the global hotkey that triggers text capture.
///
/// After capturing text, it shows a style picker so the user can choose how
/// the selection should be summarized, then streams the result from the
/// configured LLM provider.
@MainActor
final class HotkeyManager: ObservableObject {
    private let textCaptureService: any TextCapturing
    private let styleStore: StyleStore
    private let llmProvider: any LLMProvider
    private var pickerPanel: StylePickerPanel?

    /// Creates a hotkey manager with the given services.
    /// The global shortcut is registered immediately.
    /// - Parameters:
    ///   - textCaptureService: The service used to read the current selection.
    ///   - styleStore: The store that provides summary styles.
    ///   - llmProvider: The provider used to generate summaries.
    init(textCaptureService: any TextCapturing,
         styleStore: StyleStore,
         llmProvider: any LLMProvider) {
        self.textCaptureService = textCaptureService
        self.styleStore = styleStore
        self.llmProvider = llmProvider
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

    /// Triggers a text capture and shows the style picker on success.
    /// This is used by both the global hotkey and the menu-bar menu.
    func triggerSummarize() async {
        do {
            let captured = try await textCaptureService.captureSelection()
            showStylePicker(for: captured)
        } catch let error as CaptureError {
            print("Capture failed: \(error.localizedDescription)")
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
        }
    }

    /// Shows the style picker near the cursor. If a picker is already open,
    /// it is closed first so only one picker is visible at a time.
    private func showStylePicker(for captured: CapturedText) {
        pickerPanel?.close()

        pickerPanel = StylePickerPanel(styleStore: styleStore) { [weak self] style in
            self?.pickerPanel = nil
            print("Selected style: \(style.name)")
            Task {
                await self?.streamSummary(for: captured, style: style)
            }
        }

        pickerPanel?.show()
    }

    /// Sends the captured text and chosen style to the LLM provider and
    /// prints the streamed tokens to the console.
    private func streamSummary(for captured: CapturedText, style: SummaryStyle) async {
        let request = SummaryRequest(
            style: style,
            text: captured.text,
            model: OllamaProvider.defaultModel
        )

        do {
            print("Streaming summary from \(llmProvider.displayName)...")
            for try await delta in llmProvider.summarize(request) {
                print(delta, terminator: "")
            }
            print("\n--- Stream complete ---")
        } catch let error as LocalizedError {
            print("\nSummary failed: \(error.localizedDescription)")
        } catch {
            print("\nUnexpected error: \(error.localizedDescription)")
        }
    }
}
