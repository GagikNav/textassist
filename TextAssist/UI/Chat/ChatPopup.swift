import SwiftUI
import AppKit

/// A floating, non-activating popup that displays the multi-turn chat UI.
///
/// The popup appears near the mouse cursor, can be resized, and does not
/// activate the app so the user can keep working in the source application.
///
/// When the user closes the panel with its close button, the `onClose`
/// callback is invoked so the owner can release the popup and its stream.
@MainActor
final class ChatPopup: NSObject {
    /// Default popup size chosen to balance the chat's message list and input.
    static let defaultSize = CGSize(width: 520, height: 560)

    /// Minimum size the user can resize the popup to.
    static let minimumSize = CGSize(width: 380, height: 320)

    /// Called when the panel is closed by the user.
    var onClose: (() -> Void)?

    let viewModel: ChatViewModel
    private var panel: KeyablePanel?

    /// Creates a popup with the given view model.
    /// - Parameter viewModel: The observable state and actions for the chat.
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    /// Shows the popup near the current mouse cursor.
    /// If a popup is already open, it is replaced.
    func show() {
        close()

        let hostingController = NSHostingController(
            rootView: ChatPopupView(viewModel: self.viewModel)
        )
        hostingController.view.frame = CGRect(origin: .zero, size: Self.defaultSize)

        let panel = KeyablePanel(
            contentRect: hostingController.view.bounds,
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.title = "Chat"
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.minSize = Self.minimumSize
        panel.contentView = hostingController.view
        panel.delegate = self

        self.panel = panel
        PanelPositioning.positionNearCursor(panel)
        panel.makeKeyAndOrderFront(nil)
    }

    /// Closes and releases the panel.
    func close() {
        panel?.delegate = nil
        panel?.close()
        panel = nil
    }
}

// MARK: - NSWindowDelegate

extension ChatPopup: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        panel?.delegate = nil
        panel = nil
        onClose?()
    }
}
