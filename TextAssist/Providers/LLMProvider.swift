import Foundation

/// Common interface for all LLM backends.
///
/// The app currently supports Ollama. An OpenAI-compatible provider can
/// adopt the same protocol later without changing callers.
protocol LLMProvider: Sendable {
    /// Human-readable name shown in settings.
    var displayName: String { get }

    /// Fetches the list of models available at the configured endpoint.
    /// - Returns: An array of model identifiers, for example `["phi3:instruct"]`.
    func listModels() async throws -> [String]

    /// Streams a summary for the given request.
    ///
    /// Each yielded string is a partial delta. The full summary is the
    /// concatenation of all deltas. The stream completes when generation ends
    /// or throws on error.
    /// - Parameter request: The captured text, chosen style, and model options.
    /// - Returns: An async stream of token deltas.
    func summarize(_ request: SummaryRequest) -> AsyncThrowingStream<String, Error>
}
