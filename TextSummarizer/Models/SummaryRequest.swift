import Foundation

/// Everything an LLM provider needs to produce one summary.
struct SummaryRequest: Sendable {
    /// The style chosen by the user.
    let style: SummaryStyle

    /// The text captured from the frontmost app.
    let text: String

    /// The provider-specific model identifier.
    let model: String

    /// Maximum number of tokens the provider should generate.
    let maxTokens: Int

    /// Sampling temperature. Lower values produce more deterministic output.
    let temperature: Double

    /// Creates a request.
    /// - Parameters:
    ///   - style: The chosen summary style.
    ///   - text: The captured selection.
    ///   - model: Model identifier, for example `phi3:instruct`.
    ///   - maxTokens: Maximum tokens to generate. Default is `1024`.
    ///   - temperature: Sampling temperature. Default is `0.2`.
    init(
        style: SummaryStyle,
        text: String,
        model: String,
        maxTokens: Int = 1024,
        temperature: Double = 0.2
    ) {
        self.style = style
        self.text = text
        self.model = model
        self.maxTokens = maxTokens
        self.temperature = temperature
    }

    /// The fully substituted user message ready to send to the LLM.
    var userMessage: String {
        style.prompt(for: text)
    }
}
