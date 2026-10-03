import Foundation
import SwiftUI
import Combine

/// Which rendering to show for Write results.
enum ResultViewMode: String, CaseIterable, Identifiable {
    case clean = "Clean"
    case diff = "Diff"
    var id: String { rawValue }
}

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

    /// Clean text or word-level diff (Write styles only).
    @Published var viewMode: ResultViewMode = .clean

    /// Whether the original selection is expanded above the result.
    @Published var showsOriginal: Bool = false

    /// Precomputed diff between the original and the result.
    @Published private(set) var diffText: AttributedString = AttributedString()

    /// Called when the user taps Copy or presses ⌘C.
    var onCopy: () -> Void = {}

    /// Called when the user taps Replace or presses ⌘↩.
    var onReplace: () -> Void = {}

    /// Called when the user taps Chat or presses ⌘T.
    var onContinueInChat: () -> Void = {}

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

    /// Whether the current style belongs to the Write group.
    var isWriteMode: Bool { currentStyle.category == .write }

    /// True when a diff was computed and can be displayed.
    var isDiffAvailable: Bool { !diffText.characters.isEmpty }

    /// True when the result can be written back over the selection.
    var canReplace: Bool {
        isWriteMode && capturedText.canReplaceSelection
            && !isStreaming && !streamedText.isEmpty && errorMessage == nil
    }

    /// Recomputes the diff. Skips very large inputs to keep the UI responsive.
    func recomputeDiff() {
        guard isWriteMode, !streamedText.isEmpty,
              capturedText.text.count + streamedText.count < 20_000 else {
            diffText = AttributedString()
            return
        }
        diffText = TextDiffer.attributed(TextDiffer.diff(old: capturedText.text, new: streamedText))
    }

    /// Closes the popup.
    func close() {
        onClose()
    }
}
