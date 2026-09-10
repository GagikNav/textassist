import Foundation
import AppKit
import Combine

/// Coordinates the end-to-end summarization flow:
/// capture → style picker → provider stream → popup.
///
/// This class is owned by `TextSummarizerApp` and lives for the lifetime of
/// the app. It keeps at most one style picker and one summary popup open at
/// a time.
@MainActor
final class SummarizationOrchestrator: ObservableObject {
    private let textCaptureService: any TextCapturing
    private let styleStore: StyleStore
    private let llmProvider: any LLMProvider

    private var pickerPanel: StylePickerPanel?
    private var summaryPopup: SummaryPopup?
    private var streamingTask: Task<Void, Never>?

    /// Creates the orchestrator with the app's shared services.
    /// - Parameters:
    ///   - textCaptureService: Reads the current selection.
    ///   - styleStore: Provides styles and remembers the last choice.
    ///   - llmProvider: Streams summaries from the configured backend.
    init(
        textCaptureService: any TextCapturing,
        styleStore: StyleStore,
        llmProvider: any LLMProvider
    ) {
        self.textCaptureService = textCaptureService
        self.styleStore = styleStore
        self.llmProvider = llmProvider
    }

    /// Starts the full summarization flow from the beginning.
    ///
    /// This is called by the global hotkey and the menu-bar menu.
    func startSummarization() async {
        do {
            let captured = try await textCaptureService.captureSelection()
            showStylePicker(for: captured)
        } catch let error as CaptureError {
            // Capture errors still go to the console for Increment C.
            // A dedicated error UI will be added if needed in later increments.
            print("Capture failed: \(error.localizedDescription)")
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
        }
    }

    // MARK: - Style picker

    private func showStylePicker(for captured: CapturedText) {
        pickerPanel?.close()

        pickerPanel = StylePickerPanel(styleStore: styleStore) { [weak self] style in
            self?.pickerPanel = nil
            Task { [weak self] in
                await self?.showSummaryPopup(for: captured, style: style)
            }
        }

        pickerPanel?.show()
    }

    // MARK: - Summary popup

    private func showSummaryPopup(for captured: CapturedText, style: SummaryStyle) {
        streamingTask?.cancel()
        summaryPopup?.close()

        let viewModel = SummaryPopupViewModel(
            capturedText: captured,
            currentStyle: style,
            availableStyles: styleStore.styles
        )

        configureActions(for: viewModel, captured: captured)

        let popup = SummaryPopup(viewModel: viewModel)
        popup.onClose = { [weak self] in
            self?.closePopup()
        }

        summaryPopup = popup
        popup.show()

        streamingTask = Task { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            await self.streamSummary(for: captured, style: style, viewModel: viewModel)
        }
    }

    private func configureActions(for viewModel: SummaryPopupViewModel, captured: CapturedText) {
        viewModel.onCopy = { [weak viewModel] in
            guard let text = viewModel?.streamedText, !text.isEmpty else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }

        viewModel.onRegenerate = { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            self.streamingTask?.cancel()
            self.streamingTask = Task {
                await self.streamSummary(
                    for: captured,
                    style: viewModel.currentStyle,
                    viewModel: viewModel
                )
            }
        }

        viewModel.onStyleChange = { [weak self, weak viewModel] newStyle in
            guard let self, let viewModel else { return }
            self.styleStore.recordSelection(newStyle)
            self.streamingTask?.cancel()
            self.streamingTask = Task {
                await self.streamSummary(
                    for: captured,
                    style: newStyle,
                    viewModel: viewModel
                )
            }
        }

        viewModel.onClose = { [weak self] in
            self?.closePopup()
        }
    }

    private func closePopup() {
        streamingTask?.cancel()
        streamingTask = nil
        summaryPopup?.close()
        summaryPopup = nil
    }

    // MARK: - Streaming

    private func streamSummary(
        for captured: CapturedText,
        style: SummaryStyle,
        viewModel: SummaryPopupViewModel
    ) async {
        let request = SummaryRequest(style: style, text: captured.text)

        viewModel.streamedText = ""
        viewModel.isStreaming = true
        viewModel.errorMessage = nil
        viewModel.elapsedTime = nil
        viewModel.currentStyle = style

        let startTime = Date()

        defer {
            viewModel.isStreaming = false
        }

        do {
            for try await delta in llmProvider.summarize(request) {
                guard !Task.isCancelled else { return }
                viewModel.streamedText += delta
            }
            viewModel.elapsedTime = Date().timeIntervalSince(startTime)
        } catch {
            guard !Task.isCancelled else { return }
            viewModel.errorMessage = (error as? LocalizedError)?.localizedDescription
                ?? error.localizedDescription
        }
    }
}
