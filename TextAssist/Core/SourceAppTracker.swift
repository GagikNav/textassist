import AppKit

/// Tracks the most recently activated or deactivated application that is not
/// Text Assist itself.
///
/// Opening the `MenuBarExtra` popover activates Text Assist, so by the time
/// the user clicks "Assist with Selection" the frontmost application is no
/// longer the one holding the selection. This tracker remembers the app the
/// user was in before the menu opened, so capture can target it.
@MainActor
final class SourceAppTracker: NSObject {
    /// The most recent frontmost application other than Text Assist.
    private(set) var lastNonSelfApp: NSRunningApplication?

    override init() {
        super.init()
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(
            self,
            selector: #selector(applicationDidChange(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(applicationDidChange(_:)),
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil
        )
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    @objc private func applicationDidChange(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        if app.bundleIdentifier != Bundle.main.bundleIdentifier {
            lastNonSelfApp = app
        }
    }
}
