import SwiftUI
import AppKit

/// A compact, non-activating floating panel that lets the user pick a summary style.
///
/// The panel appears near the mouse cursor, accepts digit shortcuts (`1`–`6`, `0`),
/// and closes automatically when the user makes a choice or presses `Escape`.
@MainActor
final class StylePickerPanel {
    private let styleStore: StyleStore
    private let onSelect: (SummaryStyle) -> Void
    private var panel: KeyablePanel?

    /// Creates a new picker panel.
    /// - Parameters:
    ///   - styleStore: The store that provides styles and remembers the last choice.
    ///   - onSelect: Closure called when the user picks a style.
    init(styleStore: StyleStore, onSelect: @escaping (SummaryStyle) -> Void) {
        self.styleStore = styleStore
        self.onSelect = onSelect
    }

    /// Shows the picker near the current mouse cursor.
    /// If a picker is already open, it is replaced.
    func show() {
        close()

        let pickerView = StylePickerView(
            styles: styleStore.styles,
            lastUsedStyleID: styleStore.lastUsedStyleID,
            onSelect: { [weak self] style in
                self?.styleStore.recordSelection(style)
                self?.close()
                self?.onSelect(style)
            },
            onCancel: { [weak self] in
                self?.close()
            }
        )

        let hostingController = NSHostingController(rootView: pickerView)
        // Match the SwiftUI view's intended width; height is determined by the content.
        hostingController.view.frame = CGRect(origin: .zero, size: CGSize(width: 220, height: 200))

        let panel = KeyablePanel(
            contentRect: hostingController.view.bounds,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.contentView = hostingController.view

        self.panel = panel
        positionPanelNearCursor(panel)
        panel.makeKeyAndOrderFront(nil)
    }

    /// Closes and releases the panel.
    func close() {
        panel?.close()
        panel = nil
    }
}

// MARK: - KeyablePanel

/// A borderless panel that is allowed to become the key window so it can
/// receive digit-key and Escape keyboard events, while still being
/// non-activating so it does not steal focus from the user's current app.
private final class KeyablePanel: NSPanel {
    override var canBecomeKeyWindow: Bool { true }
    override var canBecomeMainWindow: Bool { false }
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
