import AppKit
import ApplicationServices

/// Errors that can happen while pasting a result back into the source app.
enum ReplacementError: Error, LocalizedError {
    case accessibilityNotGranted
    case sourceAppUnavailable

    var errorDescription: String? {
        switch self {
        case .accessibilityNotGranted:
            return "Text Assist needs Accessibility permission to paste into other apps."
        case .sourceAppUnavailable:
            return "The original app is no longer available. Use Copy instead."
        }
    }
}

/// Replaces the user's selection in the source app by pasting with a simulated ⌘V.
///
/// Flow: save clipboard → put result on clipboard → re-activate source app →
/// post ⌘V → wait → restore the previous clipboard.
@MainActor
struct TextReplacementService {
    func replaceSelection(with text: String, inAppWithPID pid: pid_t?) async throws {
        guard AXIsProcessTrusted() else { throw ReplacementError.accessibilityNotGranted }
        guard let pid,
              let app = NSRunningApplication(processIdentifier: pid),
              !app.isTerminated else {
            throw ReplacementError.sourceAppUnavailable
        }

        let snapshot = PasteboardSnapshot.capture()
        defer { snapshot.restore() }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // The panel is non-activating, so the source app is usually still active.
        // Activating again is cheap and covers the case where it is not.
        app.activate(options: [])
        try await Task.sleep(nanoseconds: 150_000_000)

        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(9), keyDown: true) // 'v'
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(9), keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)

        // Give the app time to read the pasteboard before `defer` restores it.
        try await Task.sleep(nanoseconds: 400_000_000)
    }
}
