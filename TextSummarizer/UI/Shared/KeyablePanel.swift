import AppKit

/// An `NSPanel` subclass that can become key so it receives keyboard events,
/// while still being non-activating so it does not steal focus from the
/// user's current application.
///
/// This is useful for borderless or titled floating panels such as the
/// style picker and summary popup.
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
