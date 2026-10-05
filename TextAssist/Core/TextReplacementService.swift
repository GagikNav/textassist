import AppKit
import ApplicationServices

/// Errors that can happen while pasting a result back into the source app.
enum ReplacementError: Error, LocalizedError {
    case accessibilityNotGranted
    case sourceAppUnavailable
    case eventCreationFailed

    var errorDescription: String? {
        switch self {
        case .accessibilityNotGranted:
            return "Text Assist needs Accessibility permission to paste into other apps."
        case .sourceAppUnavailable:
            return "The original app is no longer available. Use Copy instead."
        case .eventCreationFailed:
            return "Text Assist couldn't synthesize the paste keystroke. Use Copy instead."
        }
    }
}

/// Replaces the user's selection in the source app by pasting with a simulated ⌘V.
///
/// Flow: save clipboard → put result on clipboard → re-activate source app →
/// post ⌘V directly to the source app's process → wait → restore the previous
/// clipboard.
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

        // Create the synthetic ⌘V up front so a failure here surfaces as an
        // error instead of a silent no-op.
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(9), keyDown: true), // 'v'
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(9), keyDown: false)
        else {
            throw ReplacementError.eventCreationFailed
        }
        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        // Post the paste directly to the source app's process. Posting at the
        // HID event tap would deliver the event to the key window — which is the
        // floating popup while it is open. The popup has no editable responder,
        // so the paste is dropped and the system beeps instead of replacing the
        // selection.
        keyDown.postToPid(pid)
        keyUp.postToPid(pid)

        // Give the app time to read the pasteboard before `defer` restores it.
        try await Task.sleep(nanoseconds: 400_000_000)
    }
}
