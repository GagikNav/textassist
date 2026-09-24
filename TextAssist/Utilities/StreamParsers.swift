import Foundation

/// A single NDJSON line from Ollama's `/api/chat` streaming endpoint.
///
/// Example line:
/// ```json
/// {"model":"phi3:instruct","created_at":"...","message":{"role":"assistant","content":"Hello"},"done":false}
/// ```
struct NDJSONLine: Decodable {
    struct Message: Decodable {
        let role: String?
        let content: String?
    }

    let message: Message?
    let done: Bool?
    let error: String?

    /// Why generation stopped, for example `"stop"` or `"length"`.
    /// Present only on the final line, when `done` is `true`.
    let doneReason: String?

    enum CodingKeys: String, CodingKey {
        case message, done, error
        case doneReason = "done_reason"
    }

    /// Parses one NDJSON line.
    /// - Parameters:
    ///   - line: A single line of NDJSON from the stream.
    ///   - decoder: The JSON decoder to use. Defaults to a new `JSONDecoder`.
    /// - Returns: The decoded line.
    /// - Throws: Any decoding error from `JSONDecoder`.
    static func parse(_ line: String, using decoder: JSONDecoder = JSONDecoder()) throws -> NDJSONLine {
        try decoder.decode(NDJSONLine.self, from: Data(line.utf8))
    }
}
