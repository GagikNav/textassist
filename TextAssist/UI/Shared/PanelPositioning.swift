import AppKit

/// Shared positioning logic for floating panels.
///
/// Centralizes the cursor-relative placement so each popup doesn't need its
/// own copy. The three legacy `positionPanelNearCursor` methods in existing
/// panels are intentionally left in place for now.
enum PanelPositioning {
    /// Places the panel near the mouse cursor while keeping it fully on screen.
    @MainActor
    static func positionNearCursor(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let panelSize = panel.frame.size

        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
                ?? NSScreen.main
        else {
            panel.center()
            return
        }

        let visibleFrame = screen.visibleFrame
        var origin = CGPoint(
            x: mouseLocation.x - panelSize.width / 2,
            y: mouseLocation.y - panelSize.height / 2
        )
        origin.x = max(visibleFrame.minX, min(origin.x, visibleFrame.maxX - panelSize.width))
        origin.y = max(visibleFrame.minY, min(origin.y, visibleFrame.maxY - panelSize.height))
        panel.setFrameOrigin(origin)
    }
}
