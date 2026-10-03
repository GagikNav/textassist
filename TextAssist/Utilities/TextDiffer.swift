import Foundation
import SwiftUI

enum DiffKind {
    case same, removed, added
}

struct DiffToken: Identifiable {
    let id = UUID()
    let kind: DiffKind
    let text: String
}

/// Word-level diff built on `CollectionDifference`. No third-party dependency.
enum TextDiffer {
    /// Splits text into alternating word and whitespace tokens so spacing is preserved.
    static func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var currentIsSpace: Bool?

        for character in text {
            let isSpace = character.isWhitespace
            if let wasSpace = currentIsSpace, wasSpace != isSpace {
                tokens.append(current)
                current = ""
            }
            current.append(character)
            currentIsSpace = isSpace
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }

    /// Returns tokens in reading order, tagged as same, removed (old only), or added (new only).
    static func diff(old: String, new: String) -> [DiffToken] {
        let oldTokens = tokenize(old)
        let newTokens = tokenize(new)
        let changes = newTokens.difference(from: oldTokens)

        var removed = Set<Int>()
        var inserted = Set<Int>()
        for change in changes {
            switch change {
            case .remove(let offset, _, _): removed.insert(offset)
            case .insert(let offset, _, _): inserted.insert(offset)
            }
        }

        var result: [DiffToken] = []
        var i = 0
        var j = 0
        while i < oldTokens.count || j < newTokens.count {
            if i < oldTokens.count, removed.contains(i) {
                result.append(DiffToken(kind: .removed, text: oldTokens[i]))
                i += 1
            } else if j < newTokens.count, inserted.contains(j) {
                result.append(DiffToken(kind: .added, text: newTokens[j]))
                j += 1
            } else if i < oldTokens.count, j < newTokens.count {
                result.append(DiffToken(kind: .same, text: newTokens[j]))
                i += 1
                j += 1
            } else {
                break
            }
        }
        return result
    }

    /// Builds a styled string: removed words red and struck through, added words green.
    static func attributed(_ tokens: [DiffToken]) -> AttributedString {
        var output = AttributedString()
        for token in tokens {
            var piece = AttributedString(token.text)
            switch token.kind {
            case .same:
                break
            case .removed:
                piece.foregroundColor = Color.red
                piece.backgroundColor = Color.red.opacity(0.15)
                piece.strikethroughStyle = .single
            case .added:
                piece.foregroundColor = Color.green
                piece.backgroundColor = Color.green.opacity(0.18)
            }
            output.append(piece)
        }
        return output
    }
}
