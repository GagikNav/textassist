import Foundation
import Combine

/// A single past result, persisted as part of the recent history.
///
/// Stored as JSON on disk so the most recent results survive an app restart.
/// `input` is the original captured selection (truncated), `output` the
/// finished result, ready to be re-opened without re-streaming.
struct HistoryEntry: Codable, Identifiable {
    /// Stable identifier for the entry.
    let id: UUID

    /// When the result was produced.
    let date: Date

    /// Identifier of the style that produced the result.
    let styleID: String

    /// User-facing name of the style, shown in the menu bar.
    let styleName: String

    /// Localized name of the app the selection was captured from.
    let sourceAppName: String

    /// The original selection, truncated to a safe size for persistence.
    let input: String

    /// The finished (cleaned) result.
    let output: String

    /// Maximum number of characters of the original input kept per entry.
    static let maxInputLength = 20_000
}

/// Stores and persists the most recent results.
///
/// Entries are kept newest-first, capped at 25, and written as JSON to
/// `~/Library/Application Support/Text Assist/history.json` after every change.
/// Corrupt or missing files simply start empty.
@MainActor
final class HistoryStore: ObservableObject {
    /// Most recent results, newest first.
    @Published private(set) var entries: [HistoryEntry]

    /// Maximum number of entries retained.
    static let maxEntries = 25

    /// Creates the store, loading any previously saved history.
    init() {
        self.entries = Self.load()
    }

    /// Inserts an entry at the front and trims to the cap.
    /// - Parameter entry: The result to record.
    func add(_ entry: HistoryEntry) {
        entries.insert(entry, at: 0)
        if entries.count > Self.maxEntries {
            entries = Array(entries.prefix(Self.maxEntries))
        }
        persist()
    }

    /// Removes all entries and clears the saved file.
    func clear() {
        entries.removeAll()
        persist()
    }

    // MARK: - Persistence

    private static var fileURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport
            .appendingPathComponent("Text Assist", isDirectory: true)
            .appendingPathComponent("history.json")
    }

    private static func load() -> [HistoryEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([HistoryEntry].self, from: data)) ?? []
    }

    private func persist() {
        let file = Self.fileURL
        do {
            try FileManager.default.createDirectory(
                at: file.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(entries)
            try data.write(to: file, options: .atomic)
        } catch {
            // Persistence is best-effort; a failed write must not crash the app.
            print("Failed to persist history: \(error.localizedDescription)")
        }
    }
}
