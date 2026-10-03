import Foundation

/// How the text was obtained. Replace-in-place is only safe for real selections.
enum CaptureOrigin: Sendable {
    /// `AXSelectedText` returned the selection.
    case selectedText
    /// Nothing was selected; the whole field value was read.
    case fieldValue
    /// Obtained through the simulated ⌘C fallback.
    case clipboard
}

/// Holds text captured from the frontmost app and where it came from.
struct CapturedText: Sendable {
    /// The selected text captured from the active application.
    let text: String

    /// The localized name of the source application (for example, "Safari" or "Notes").
    let sourceAppName: String

    /// Process identifier of the source app, used by Replace to re-activate it.
    var sourceAppPID: pid_t? = nil

    /// How the text was captured.
    var origin: CaptureOrigin = .selectedText

    /// Whether pasting a result back would replace what the user selected.
    var canReplaceSelection: Bool {
        sourceAppPID != nil && origin != .fieldValue
    }
}
