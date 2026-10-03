import Foundation

/// Removes common LLM wrapper noise from rewritten-text results.
enum OutputCleaner {
    /// Strips code fences, "Here is the revised text:" preambles, and wrapping quotes.
    /// Call once after streaming has finished, never per delta.
    static func cleanRewrite(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Wrapping code fence.
        if text.hasPrefix("```"), text.hasSuffix("```"), text.count >= 6 {
            var lines = text.components(separatedBy: "\n")
            if lines.count >= 2 {
                lines.removeFirst()
                if lines.last?.trimmingCharacters(in: .whitespaces) == "```" {
                    lines.removeLast()
                }
                text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // 2. Single-line preamble ending in a colon.
        let lines = text.components(separatedBy: "\n")
        if lines.count > 1, let first = lines.first?.lowercased(), first.hasSuffix(":") {
            let prefixes = ["here", "sure", "certainly", "revised", "rewritten", "corrected", "improved"]
            if prefixes.contains(where: { first.hasPrefix($0) }) {
                text = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // 3. Wrapping quotes, only when the interior contains no quote characters.
        let pairs: [(Character, Character)] = [("\"", "\""), ("“", "”")]
        for (open, close) in pairs where text.count > 2 && text.first == open && text.last == close {
            let inner = text.dropFirst().dropLast()
            if !inner.contains(open) && !inner.contains(close) {
                text = String(inner)
            }
        }

        return text
    }
}
