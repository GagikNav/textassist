import Foundation

/// One message in a provider-agnostic conversation.
struct LLMMessage: Sendable, Equatable {
    enum Role: String, Sendable {
        case system, user, assistant
    }

    let role: Role
    let content: String
}

/// A multi-turn completion request. Used directly by Chat and indirectly by `SummaryRequest`.
struct ChatCompletionRequest: Sendable {
    let messages: [LLMMessage]
    let maxTokens: Int
    let temperature: Double

    /// - Parameters:
    ///   - messages: Full conversation including the system message.
    ///   - maxTokens: Maximum tokens to generate. Default is `4096`.
    ///   - temperature: Sampling temperature. Default is `0.2`.
    init(messages: [LLMMessage], maxTokens: Int = 4096, temperature: Double = 0.2) {
        self.messages = messages
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}
