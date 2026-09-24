import Foundation
import SwiftUI
import Combine

/// The observable state and user actions for the summary popup.
///
/// The `SummarizationOrchestrator` creates and mutates this object on the
/// main actor. The `SummaryPopupView` binds to it to render the streaming
/// Markdown, toolbar buttons, and error banner.
@MainActor
final class SummaryPopupViewModel: ObservableObject {
    /// The captured text being summarized.
    let capturedText: CapturedText

    /// All styles the user can switch to from the popup.
    let availableStyles: [SummaryStyle]

    /// The style currently being used.
    @Published var currentStyle: SummaryStyle

    /// The streamed Markdown summary so far.
    @Published var streamedText: String = ""

    /// Whether the provider is still streaming tokens.
    @Published var isStreaming: Bool = false

    /// A user-facing error message, if streaming failed.
    @Published var errorMessage: String? = nil

    /// Elapsed time from first token to stream completion, in seconds.
    @Published var elapsedTime: TimeInterval? = nil

    /// Called when the user taps Copy or presses ⌘C.
    var onCopy: () -> Void = {}

    /// Called when the user taps Regenerate or presses ⌘R.
    var onRegenerate: () -> Void = {}

    /// Called when the user picks a different style from the toolbar dropdown.
    var onStyleChange: (SummaryStyle) -> Void = { _ in }

    /// Called when the user closes the popup.
    var onClose: () -> Void = {}

    /// Creates a view model for the popup.
    /// - Parameters:
    ///   - capturedText: The captured selection.
    ///   - currentStyle: The style chosen in the picker.
    ///   - availableStyles: All built-in styles.
    init(
        capturedText: CapturedText,
        currentStyle: SummaryStyle,
        availableStyles: [SummaryStyle]
    ) {
        self.capturedText = capturedText
        self.currentStyle = currentStyle
        self.availableStyles = availableStyles
    }

    /// Copies the current summary to the pasteboard.
    func copyToPasteboard() {
        onCopy()
    }

    /// Re-runs summarization with the current style.
    func regenerate() {
        onRegenerate()
    }

    /// Switches to a new style and re-runs summarization.
    func changeStyle(to style: SummaryStyle) {
        guard style.id != currentStyle.id else { return }
        currentStyle = style
        onStyleChange(style)
    }

    /// Closes the popup.
    func close() {
        onClose()
    }
}
