import SwiftUI
import AppKit

/// A floating, non-activating popup that displays a streaming Markdown summary.
///
/// The popup appears near the mouse cursor, can be resized, and does not
/// activate the app so the user can keep working in the source application.
///
/// When the user closes the panel with its close button, the `onClose`
/// callback is invoked so the owner can cancel any ongoing stream.
@MainActor
final class SummaryPopup: NSObject {
    /// Default popup size chosen to balance readability with screen real estate.
    /// This is roughly 15% larger than the first iteration.
    static let defaultSize = CGSize(width: 600, height: 420)

    /// Minimum size the user can resize the popup to.
    static let minimumSize = CGSize(width: 360, height: 280)

    /// Called when the panel is closed by the user.
    var onClose: (() -> Void)?

    private let viewModel: SummaryPopupViewModel
    private var panel: KeyablePanel?

    /// Creates a popup with the given view model.
    /// - Parameter viewModel: The observable state and actions for the popup.
    init(viewModel: SummaryPopupViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    /// Shows the popup near the current mouse cursor.
    /// If a popup is already open, it is replaced.
    func show() {
        close()

        let hostingController = NSHostingController(
            rootView: SummaryPopupView(viewModel: self.viewModel)
        )
        hostingController.view.frame = CGRect(origin: .zero, size: Self.defaultSize)

        let panel = KeyablePanel(
            contentRect: hostingController.view.bounds,
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.title = viewModel.currentStyle.name
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
        positionPanelNearCursor(panel)
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

extension SummaryPopup: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        panel?.delegate = nil
        panel = nil
        onClose?()
    }

    // MARK: - Positioning

    /// Places the panel near the mouse cursor while keeping it fully on screen.
    private func positionPanelNearCursor(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let panelSize = panel.frame.size

        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
                ?? NSScreen.main
        else {
            // No screen information available: center on the main screen.
            panel.center()
            return
        }

        let visibleFrame = screen.visibleFrame
        var origin = CGPoint(
            x: mouseLocation.x - panelSize.width / 2,
            y: mouseLocation.y - panelSize.height / 2
        )

        // Keep the panel inside the visible screen area.
        origin.x = max(visibleFrame.minX, min(origin.x, visibleFrame.maxX - panelSize.width))
        origin.y = max(visibleFrame.minY, min(origin.y, visibleFrame.maxY - panelSize.height))

        panel.setFrameOrigin(origin)
    }
}
