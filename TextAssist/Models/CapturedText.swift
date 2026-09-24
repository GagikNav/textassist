import Foundation

/// Holds text captured from the frontmost app and the name of the app it came from.
struct CapturedText: Sendable {
    /// The selected text captured from the active application.
    let text: String

    /// The localized name of the source application (for example, "Safari" or "Notes").
    let sourceAppName: String
}
