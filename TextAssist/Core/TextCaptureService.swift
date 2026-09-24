import ApplicationServices
import AppKit
import Foundation

/// Abstraction for capturing the user's current text selection.
protocol TextCapturing: Sendable {
    /// Reads the selected text from the frontmost application.
    /// Must run on the main actor because it uses `NSWorkspace`.
    @MainActor
    func captureSelection() async throws -> CapturedText
}

/// Captures selected text using the macOS Accessibility API, with a ⌘C
/// pasteboard fallback for apps that do not expose `AXSelectedText`.
///
/// The service first tries to read the selection without touching the
/// clipboard. If that fails, it briefly simulates ⌘C, reads the general
/// pasteboard, and restores the previous clipboard contents. It validates
/// the result and reports friendly errors for common problems like missing
/// Accessibility permission, no selection, secure fields, or selections that
/// are too long.
struct TextCaptureService: TextCapturing {
    /// Maximum number of characters the service will capture in one request.
    static let defaultMaxSelectionLength = 100_000

    private let maxSelectionLength: Int

    init(maxSelectionLength: Int = Self.defaultMaxSelectionLength) {
        self.maxSelectionLength = maxSelectionLength
    }

    @MainActor
    func captureSelection() async throws -> CapturedText {
        // Step 1: Make sure the user has granted Accessibility permission.
        // We use the literal string key to avoid import-version differences.
        let trustedOptions = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(trustedOptions)
        print("Accessibility trusted: \(isTrusted)")

        guard isTrusted else {
            throw CaptureError.accessibilityNotGranted
        }

        // Step 2: Identify the frontmost application.
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            throw CaptureError.noSelection
        }

        let appName = frontmostApp.localizedName ?? "Unknown App"
        print("Frontmost app: \(appName)")

        // Step 3: Try Accessibility capture first (does not touch clipboard).
        if let text = tryCaptureViaAccessibility(frontmostApp: frontmostApp) {
            print("Captured via Accessibility")
            return try makeCapturedText(text: text, sourceAppName: appName)
        }

        // Step 4: Fall back to ⌘C + pasteboard if Accessibility returned nothing.
        // This is needed for apps like Microsoft Word that do not expose
        // AXSelectedText reliably.
        print("Falling back to clipboard ⌘C")
        let fallbackText = try await captureViaClipboard()
        return try makeCapturedText(text: fallbackText, sourceAppName: appName)
    }

    /// Attempts to read the focused element and its selected text via AX.
    /// Returns `nil` when AX succeeds structurally but there is simply no text,
    /// or when the app does not expose selected text so the caller can fall back.
    @MainActor
    private func tryCaptureViaAccessibility(frontmostApp: NSRunningApplication) -> String? {
        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)

        // Get the focused UI element inside that app.
        var focusedValue: CFTypeRef?
        let focusedResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedValue)

        guard focusedResult == .success,
              let focusedElement = focusedValue.map({ $0 as! AXUIElement }) else {
            return nil
        }

        // Reject secure text fields (password boxes).
        if isSecureField(focusedElement) {
            return nil
        }

        // Try the selected text attribute first.
        var selectedTextValue: AnyObject?
        let selectedTextResult = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        )

        if selectedTextResult == .success,
           let text = selectedTextValue as? String,
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }

        // Some apps expose the full value instead of selected text.
        var value: AnyObject?
        let valueResult = AXUIElementCopyAttributeValue(focusedElement, kAXValueAttribute as CFString, &value)
        if valueResult == .success,
           let text = value as? String,
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }

        return nil
    }

    /// Simulates ⌘C, reads the general pasteboard, and restores the previous
    /// clipboard contents so the user's workflow is not disturbed.
    @MainActor
    private func captureViaClipboard() async throws -> String {
        let pasteboard = NSPasteboard.general

        // Save current clipboard contents.
        let previousItems = pasteboard.pasteboardItems?.compactMap { item -> NSPasteboardItem? in
            let newItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    newItem.setData(data, forType: type)
                }
            }
            return newItem
        }

        // Clear the pasteboard so we can detect whether ⌘C produced new content.
        pasteboard.clearContents()

        // Simulate ⌘C.
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(8), keyDown: true) // 'c'
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(8), keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)

        // Give the frontmost app a moment to write to the pasteboard.
        // 300 ms is enough for heavier apps like Microsoft Word.
        try await Task.sleep(nanoseconds: 300_000_000)

        // Read what (if anything) was copied.
        let copiedText = pasteboard.string(forType: .string)
        print("Clipboard after ⌘C: \(copiedText?.count ?? 0) characters")

        guard let copiedText = copiedText, !copiedText.isEmpty else {
            // Restore clipboard before throwing.
            restoreClipboard(previousItems)
            throw CaptureError.noSelection
        }

        // Restore the previous clipboard contents.
        restoreClipboard(previousItems)
        return copiedText
    }

    /// Restores the previous clipboard contents after a ⌘C fallback read.
    @MainActor
    private func restoreClipboard(_ items: [NSPasteboardItem]?) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let items = items, !items.isEmpty {
            pasteboard.writeObjects(items)
        }
    }

    /// Validates and trims captured text, producing a `CapturedText` value.
    @MainActor
    private func makeCapturedText(text: String, sourceAppName: String) throws -> CapturedText {
        guard text.count <= maxSelectionLength else {
            throw CaptureError.selectionTooLong(limit: maxSelectionLength)
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw CaptureError.noSelection
        }

        return CapturedText(text: trimmedText, sourceAppName: sourceAppName)
    }

    /// Checks whether the focused element is a secure text field.
    ///
    /// Secure text fields on macOS report a subrole of `AXSecureTextField`.
    /// Reading selected text from these fields is blocked for privacy.
    private func isSecureField(_ element: AXUIElement) -> Bool {
        var subroleValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleValue)

        guard result == .success, let subrole = subroleValue as? String else {
            return false
        }

        return subrole == "AXSecureTextField"
    }
}
