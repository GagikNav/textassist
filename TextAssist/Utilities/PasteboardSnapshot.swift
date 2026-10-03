import AppKit

/// A deep copy of the pasteboard contents that can be restored later.
struct PasteboardSnapshot {
    private let items: [NSPasteboardItem]

    /// Copies every item and every type currently on the pasteboard.
    static func capture(from pasteboard: NSPasteboard = .general) -> PasteboardSnapshot {
        let copies = pasteboard.pasteboardItems?.map { item -> NSPasteboardItem in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        } ?? []
        return PasteboardSnapshot(items: copies)
    }

    /// Replaces the pasteboard contents with this snapshot.
    func restore(to pasteboard: NSPasteboard = .general) {
        pasteboard.clearContents()
        if !items.isEmpty {
            pasteboard.writeObjects(items)
        }
    }
}
