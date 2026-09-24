import Foundation
import Combine

/// Stores summary styles and remembers the user's last-used style.
/// Built-in styles are always available. Custom styles will be supported
/// in a later increment.
final class StyleStore: ObservableObject {
    /// All available styles. Currently this is the built-in set.
    @Published var styles: [SummaryStyle]

    /// The ID of the style used most recently. Persisted in UserDefaults.
    var lastUsedStyleID: String {
        didSet {
            UserDefaults.standard.set(lastUsedStyleID, forKey: Self.lastUsedStyleIDKey)
        }
    }

    private static let lastUsedStyleIDKey = "com.textassist.lastUsedStyleID"

    /// Creates the store with the built-in styles and the last-used default.
    init(styles: [SummaryStyle] = SummaryStyle.builtIn) {
        self.styles = styles
        let savedID = UserDefaults.standard.string(forKey: Self.lastUsedStyleIDKey)
        self.lastUsedStyleID = savedID ?? styles.first?.id ?? SummaryStyle.shortSummary.id
    }

    /// Returns the style with the given ID, or the first built-in style as a fallback.
    func style(for id: String) -> SummaryStyle {
        styles.first { $0.id == id } ?? styles.first ?? SummaryStyle.shortSummary
    }

    /// Returns the style matching the current `lastUsedStyleID`.
    var lastUsedStyle: SummaryStyle {
        style(for: lastUsedStyleID)
    }

    /// Returns the style whose shortcut key matches the given key string.
    /// Returns `nil` when no style matches (for example, an unassigned digit).
    func style(forShortcutKey key: String) -> SummaryStyle? {
        styles.first { $0.shortcutKey == key }
    }

    /// Marks the given style as the last-used style.
    /// - Parameter style: The style the user just selected.
    func recordSelection(_ style: SummaryStyle) {
        lastUsedStyleID = style.id
    }
}
