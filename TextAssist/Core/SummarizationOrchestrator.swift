import Foundation
import AppKit
import Combine

/// Coordinates the end-to-end summarization flow:
/// capture → style picker → provider stream → popup.
///
/// This class is owned by `TextAssistApp` and lives for the lifetime of
/// the app. It keeps at most one style picker and one popup (summary or chat)
/// open at a time.
@MainActor
final class SummarizationOrchestrator: ObservableObject {
    private let textCaptureService: any TextCapturing
    private let styleStore: StyleStore
    private let llmProvider: any LLMProvider

    private var pickerPanel: StylePickerPanel?
    private var customPromptPanel: CustomPromptPanel?
    private var summaryPopup: SummaryPopup?
    private var chatPopup: ChatPopup?
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
        customPromptPanel?.close()
        customPromptPanel = nil

        pickerPanel = StylePickerPanel(styleStore: styleStore) { [weak self] style in
            self?.pickerPanel = nil
            guard let self else { return }

            if style.id == SummaryStyle.customPrompt.id {
                self.showCustomPromptPanel(for: captured)
            } else if style.category == .chat {
                self.showChat(for: captured, seed: [])
            } else {
                Task { [weak self] in
                    self?.showSummaryPopup(for: captured, style: style)
                }
            }
        }

        pickerPanel?.show()
    }

    // MARK: - Custom prompt panel

    private func showCustomPromptPanel(for captured: CapturedText) {
        closeChat()
        customPromptPanel?.close()

        customPromptPanel = CustomPromptPanel(
            onConfirm: { [weak self] style in
                self?.customPromptPanel = nil
                Task { [weak self] in
                    self?.showSummaryPopup(for: captured, style: style)
                }
            },
            onCancel: { [weak self] in
                self?.customPromptPanel = nil
            }
        )

        customPromptPanel?.show()
    }

    // MARK: - Summary popup

    private func showSummaryPopup(for captured: CapturedText, style: SummaryStyle) {
        closeChat()
        streamingTask?.cancel()
        summaryPopup?.close()

        let viewModel = SummaryPopupViewModel(
            capturedText: captured,
            currentStyle: style,
            availableStyles: styleStore.styles.filter {
                $0.category == .transform || $0.category == .write
            }
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

        viewModel.onReplace = { [weak self, weak viewModel] in
            guard let self, let viewModel, viewModel.canReplace else { return }
            let output = viewModel.streamedText
            Task { @MainActor in
                do {
                    try await TextReplacementService().replaceSelection(
                        with: output,
                        inAppWithPID: captured.sourceAppPID
                    )
                    self.closePopup()
                } catch {
                    viewModel.errorMessage = (error as? LocalizedError)?.errorDescription
                        ?? error.localizedDescription
                }
            }
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

        viewModel.onContinueInChat = { [weak self, weak viewModel] in
            guard let self, let viewModel else { return }
            var seed: [LLMMessage] = []
            if !viewModel.streamedText.isEmpty {
                seed = [
                    LLMMessage(role: .user, content: "Apply: \(viewModel.currentStyle.name)"),
                    LLMMessage(role: .assistant, content: viewModel.streamedText)
                ]
            }
            self.closePopup()
            self.showChat(for: captured, seed: seed)
        }
    }

    private func closePopup() {
        streamingTask?.cancel()
        streamingTask = nil
        summaryPopup?.close()
        summaryPopup = nil
    }

    // MARK: - Chat popup

    private func showChat(for captured: CapturedText, seed: [LLMMessage]) {
        chatPopup?.viewModel.stop()
        chatPopup?.close()

        let viewModel = ChatViewModel(capturedText: captured, provider: llmProvider, seed: seed)
        viewModel.onClose = { [weak self] in self?.closeChat() }

        let popup = ChatPopup(viewModel: viewModel)
        popup.onClose = { [weak self] in self?.closeChat() }
        chatPopup = popup
        popup.show()
    }

    private func closeChat() {
        chatPopup?.viewModel.stop()
        chatPopup?.close()
        chatPopup = nil
    }

    // MARK: - Streaming

    private func streamSummary(
        for captured: CapturedText,
        style: SummaryStyle,
        viewModel: SummaryPopupViewModel
    ) async {
        let request = SummaryRequest(style: style, text: captured.text)

        viewModel.streamedText = ""
        viewModel.viewMode = .clean
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
            if style.category == .write {
                viewModel.streamedText = OutputCleaner.cleanRewrite(viewModel.streamedText)
            }
            viewModel.elapsedTime = Date().timeIntervalSince(startTime)
            viewModel.recomputeDiff()
        } catch {
            guard !Task.isCancelled else { return }
            viewModel.errorMessage = (error as? LocalizedError)?.localizedDescription
                ?? error.localizedDescription
        }
    }
}
