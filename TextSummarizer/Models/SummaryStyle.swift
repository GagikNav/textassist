import Foundation

/// A summary style defines how the captured text should be summarized.
/// Each style has a name, a keyboard shortcut, and a prompt template that
/// must contain the `{{text}}` placeholder.
struct SummaryStyle: Identifiable, Hashable, Sendable {
    /// Stable identifier for the style, used for persistence and lookup.
    let id: String

    /// User-facing name shown in the style picker.
    let name: String

    /// Single character shortcut shown in the picker (for example, "1").
    /// Custom Prompt uses "0".
    let shortcutKey: String

    /// Prompt template sent to the LLM. Must contain `{{text}}`.
    let promptTemplate: String

    /// Whether this style was created by the user. Built-in styles are `false`.
    var isCustom: Bool = false

    /// Replaces the `{{text}}` placeholder with the captured selection.
    /// - Parameter text: The text captured from the frontmost app.
    /// - Returns: The final prompt ready to send to the LLM.
    func prompt(for text: String) -> String {
        promptTemplate.replacingOccurrences(of: "{{text}}", with: text)
    }

    /// A URL/filename-friendly version of the style name.
    /// For example, "Bullet Points" becomes "bullet-points".
    var slug: String {
        name
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}

// MARK: - Built-in styles

extension SummaryStyle {
    /// The six built-in summary styles defined in the PRD.
    static let builtIn: [SummaryStyle] = [
        .shortSummary,
        .bulletPoints,
        .detailedSummary,
        .keyTakeaways,
        .eli5,
        .customPrompt
    ]

    static let shortSummary = SummaryStyle(
        id: "short-summary",
        name: "Short Summary",
        shortcutKey: "1",
        promptTemplate: """
        Summarize the following text in 2–4 concise sentences. Output only the summary.

        {{text}}
        """
    )

    static let bulletPoints = SummaryStyle(
        id: "bullet-points",
        name: "Bullet Points",
        shortcutKey: "2",
        promptTemplate: """
        Distill the following text into 3–8 crisp Markdown bullet points. No preamble.

        {{text}}
        """
    )

    static let detailedSummary = SummaryStyle(
        id: "detailed-summary",
        name: "Detailed Summary",
        shortcutKey: "3",
        promptTemplate: """
        Write a detailed summary of the following text using Markdown headings where appropriate. Keep the structure clear and informative.

        {{text}}
        """
    )

    static let keyTakeaways = SummaryStyle(
        id: "key-takeaways",
        name: "Key Takeaways & Action Items",
        shortcutKey: "4",
        promptTemplate: """
        Extract key takeaways and any action items from the following text. Use a "## Takeaways" section and an "## Action Items" section. If there are no action items, say "None" under that section.

        {{text}}
        """
    )

    static let eli5 = SummaryStyle(
        id: "eli5",
        name: "ELI5",
        shortcutKey: "5",
        promptTemplate: """
        Explain the following text in simple terms a non-expert would understand. Use plain language and short sentences.

        {{text}}
        """
    )

    /// Placeholder for the future custom-prompt editor.
    static let customPrompt = SummaryStyle(
        id: "custom-prompt",
        name: "Custom Prompt",
        shortcutKey: "0",
        promptTemplate: """
        Summarize the following text according to your own instructions.

        {{text}}
        """
    )
}
