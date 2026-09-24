import SwiftUI
import AppKit

/// A compact, non-activating floating panel that lets the user type a
/// custom prompt instruction.
///
/// The panel appears near the mouse cursor. The user only types the
/// instruction; the captured text is appended automatically as `{{text}}`.
@MainActor
final class CustomPromptPanel {
    private let onConfirm: (SummaryStyle) -> Void
    private let onCancel: () -> Void
    private var panel: KeyablePanel?

    /// Creates a new custom prompt panel.
    /// - Parameters:
    ///   - onConfirm: Called when the user confirms with a valid instruction.
    ///                The returned style has a prompt template of
    ///                `"<instruction>\n\n{{text}}"`.
    ///   - onCancel: Called when the user cancels or closes the panel.
    init(
        onConfirm: @escaping (SummaryStyle) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    /// Shows the panel near the current mouse cursor.
    /// If a panel is already open, it is replaced.
    func show() {
        close()

        let promptView = CustomPromptView(
            onConfirm: { [weak self] prompt in
                let style = SummaryStyle(
                    id: SummaryStyle.customPrompt.id,
                    name: SummaryStyle.customPrompt.name,
                    shortcutKey: SummaryStyle.customPrompt.shortcutKey,
                    promptTemplate: prompt + "\n\n{{text}}",
                    isCustom: true
                )
                self?.close()
                self?.onConfirm(style)
            },
            onCancel: { [weak self] in
                self?.close()
                self?.onCancel()
            }
        )

        let hostingController = NSHostingController(rootView: promptView)
        hostingController.view.frame = CGRect(origin: .zero, size: CGSize(width: 360, height: 220))

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
        panel.onClose = { [weak self] in
            self?.panel = nil
        }

        self.panel = panel
        positionPanelNearCursor(panel)
        panel.makeKeyAndOrderFront(nil)
    }

    /// Closes and releases the panel.
    func close() {
        panel?.close()
        panel = nil
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
