import Foundation

/// Everything an LLM provider needs to produce one single-turn result for a style.
struct SummaryRequest: Sendable {
    /// The style chosen by the user.
    let style: SummaryStyle

    /// The text captured from the frontmost app.
    let text: String

    /// Maximum number of tokens the provider should generate.
    let maxTokens: Int

    /// Sampling temperature. Falls back to the style's value, then `0.2`.
    let temperature: Double

    init(
        style: SummaryStyle,
        text: String,
        maxTokens: Int = 4096,
        temperature: Double? = nil
    ) {
        self.style = style
        self.text = text
        self.maxTokens = maxTokens
        self.temperature = temperature ?? style.temperature ?? 0.2
    }

    /// The fully substituted user message ready to send to the LLM.
    var userMessage: String {
        style.prompt(for: text)
    }

    /// The same request expressed as a generic multi-turn completion.
    var completionRequest: ChatCompletionRequest {
        ChatCompletionRequest(
            messages: [
                LLMMessage(role: .system, content: style.systemPrompt ?? SummaryStyle.defaultSystemPrompt),
                LLMMessage(role: .user, content: userMessage)
            ],
            maxTokens: maxTokens,
            temperature: temperature
        )
    }
}
