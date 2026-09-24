import Foundation

/// Errors that can occur when communicating with a local Ollama instance.
enum OllamaError: Error, LocalizedError {
    /// Ollama is not reachable at the configured base URL.
    case notRunning

    /// The requested model is not available on the Ollama server.
    case modelNotFound(String)

    /// The response body could not be parsed as NDJSON.
    case decodingFailed(underlying: Error)

    /// The server returned an unexpected HTTP status code.
    case unexpectedStatus(Int)

    /// The response stream contained an error message from Ollama.
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .notRunning:
            return "Ollama does not appear to be running. Make sure it is started and try again."
        case .modelNotFound(let model):
            return "Model \"\(model)\" was not found. Run `ollama pull \(model)` and try again."
        case .decodingFailed:
            return "Could not read Ollama's response. The server may have returned an error page."
        case .unexpectedStatus(let code):
            return "Ollama returned an unexpected status code: \(code)."
        case .serverMessage(let message):
            return "Ollama error: \(message)"
        }
    }
}
