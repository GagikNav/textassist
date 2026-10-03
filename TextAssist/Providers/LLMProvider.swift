import Foundation

/// Common interface for all LLM backends.
protocol LLMProvider: Sendable {
    /// Human-readable name shown in settings.
    var displayName: String { get }

    /// Fetches the list of models available at the configured endpoint.
    func listModels() async throws -> [String]

    /// Streams a completion for a full conversation.
    /// Each yielded string is a partial delta; the full reply is their concatenation.
    func stream(_ request: ChatCompletionRequest) -> AsyncThrowingStream<String, Error>

    /// Streams a single-turn result for a style. Default implementation calls `stream(_:)`.
    func summarize(_ request: SummaryRequest) -> AsyncThrowingStream<String, Error>
}

extension LLMProvider {
    func summarize(_ request: SummaryRequest) -> AsyncThrowingStream<String, Error> {
        stream(request.completionRequest)
    }
}
