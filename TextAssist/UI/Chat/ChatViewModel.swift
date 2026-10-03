import Foundation
import SwiftUI
import Combine

/// One displayed chat message.
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: LLMMessage.Role
    var content: String
}

/// State and actions for the chat popup.
@MainActor
final class ChatViewModel: ObservableObject {
    /// Number of most recent messages sent to the model with each request.
    static let maxHistoryMessages = 20

    /// One-tap prompts shown while the conversation is empty.
    static let starterPrompts = [
        "What's the main point?",
        "Find weaknesses",
        "Draft a reply",
        "Explain the jargon"
    ]

    /// The pinned selection.
    let capturedText: CapturedText

    private let provider: any LLMProvider
    private var streamingTask: Task<Void, Never>?

    @Published private(set) var messages: [ChatMessage]
    @Published var draft: String = ""
    @Published private(set) var isStreaming = false
    @Published var errorMessage: String?
    @Published var isContextExpanded = false

    /// Called when the user closes the chat.
    var onClose: () -> Void = {}

    /// - Parameters:
    ///   - capturedText: The selection pinned as context.
    ///   - provider: The LLM backend.
    ///   - seed: Optional prior turns (used by "Continue in Chat").
    init(capturedText: CapturedText, provider: any LLMProvider, seed: [LLMMessage] = []) {
        self.capturedText = capturedText
        self.provider = provider
        self.messages = seed.map { ChatMessage(role: $0.role, content: $0.content) }
    }

    var canSend: Bool {
        !isStreaming && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var wordCount: Int {
        capturedText.text.split(whereSeparator: \.isWhitespace).count
    }

    // MARK: - Actions

    /// Sends the current draft.
    func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }
        draft = ""
        send(text)
    }

    /// Sends a message (used by starter chips and the input field).
    func send(_ text: String) {
        guard !isStreaming else { return }
        errorMessage = nil
        messages.append(ChatMessage(role: .user, content: text))
        messages.append(ChatMessage(role: .assistant, content: ""))
        streamReply()
    }

    /// Re-generates the last assistant answer.
    func regenerateLast() {
        guard !isStreaming, messages.last?.role == .assistant else { return }
        messages.removeLast()
        messages.append(ChatMessage(role: .assistant, content: ""))
        errorMessage = nil
        streamReply()
    }

    /// Stops the current stream, keeping whatever text arrived.
    func stop() {
        streamingTask?.cancel()
        streamingTask = nil
        isStreaming = false
    }

    /// Cancels any work and notifies the owner.
    func close() {
        stop()
        onClose()
    }

    // MARK: - Streaming

    private func streamReply() {
        guard let placeholder = messages.last, placeholder.role == .assistant else { return }
        let placeholderID = placeholder.id

        let history = messages.dropLast().suffix(Self.maxHistoryMessages)
        var payload = [LLMMessage(role: .system, content: Self.systemPrompt(for: capturedText.text))]
        payload += history.map { LLMMessage(role: $0.role, content: $0.content) }

        let request = ChatCompletionRequest(messages: payload, maxTokens: 2048, temperature: 0.5)
        isStreaming = true

        streamingTask = Task { [weak self] in
            guard let self else { return }
            defer { self.isStreaming = false }
            do {
                for try await delta in self.provider.stream(request) {
                    guard !Task.isCancelled else { return }
                    self.append(delta, toMessageWithID: placeholderID)
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.errorMessage = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
                self.removeMessageIfEmpty(id: placeholderID)
            }
        }
    }

    private func append(_ delta: String, toMessageWithID id: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].content += delta
    }

    private func removeMessageIfEmpty(id: UUID) {
        if let index = messages.firstIndex(where: { $0.id == id }), messages[index].content.isEmpty {
            messages.remove(at: index)
        }
    }

    /// System prompt that pins the selection as context for the whole conversation.
    static func systemPrompt(for text: String) -> String {
        """
        You are a helpful assistant. The user selected the text below in another app and wants to \
        discuss it. Use the text as your primary source. If the answer is not in the text, say so \
        clearly before adding general knowledge. Be concise. Respond in Markdown.

        <selected_text>
        \(text)
        </selected_text>
        """
    }
}
