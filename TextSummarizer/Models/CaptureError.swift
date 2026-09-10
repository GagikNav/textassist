import Foundation

/// Errors that can happen while trying to capture the user's text selection.
enum CaptureError: Error, LocalizedError {
    /// The app does not have Accessibility permission.
    case accessibilityNotGranted

    /// No text is currently selected.
    case noSelection

    /// The focused field is a secure text field (for example, a password box).
    case secureField

    /// The selection is longer than the allowed limit.
    case selectionTooLong(limit: Int)

    var errorDescription: String? {
        switch self {
        case .accessibilityNotGranted:
            return "Text Summarizer needs Accessibility permission to read the selected text."
        case .noSelection:
            return "No text selection found."
        case .secureField:
            return "Can't read protected fields like password boxes."
        case .selectionTooLong(let limit):
            return "Selection is too long. The limit is \(limit) characters."
        }
    }
}
