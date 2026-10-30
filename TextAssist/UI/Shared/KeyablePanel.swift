import AppKit

/// An `NSPanel` subclass that can become key so it receives keyboard events,
/// while still being non-activating so it does not steal focus from the
/// user's current application.
///
/// This is useful for borderless or titled floating panels such as the
/// style picker and summary popup.
final class KeyablePanel: NSPanel {
    /// Called when the panel is closed so owners can release their reference.
    var onClose: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Closes the panel on Esc, going through `close()` so owners clean up via `onClose`.
    ///
    /// A focused text view or field editor forwards Esc up the responder chain to here.
    /// While an input method is composing (marked text) Esc only cancels the composition,
    /// so the panel stays open.
    override func cancelOperation(_ sender: Any?) {
        if let client = firstResponder as? NSTextInputClient, client.hasMarkedText() {
            return
        }
        close()
    }

    override func close() {
        super.close()
        onClose?()
    }
}
