import Foundation

/// An `LLMProvider` that talks to a local Ollama server.
///
/// Uses `POST /api/chat` with streaming NDJSON responses.
final class OllamaProvider: LLMProvider {
    /// Shared decoder reused across requests.
    private let decoder = JSONDecoder()

    /// Stores the user's Ollama base URL and model choice.
    private let settings: SettingsStore

    /// Long-running session for streaming chat requests.
    ///
    /// Large context windows can take the local model well over the default
    /// 60s request timeout to produce a first token or the next chunk, which
    /// would otherwise abort the stream mid-summary.
    private let streamingSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 600
        configuration.timeoutIntervalForResource = 1800
        return URLSession(configuration: configuration)
    }()

    var displayName: String { "Ollama" }

    /// Creates an Ollama provider that reads its configuration from the given store.
    /// - Parameter settings: The source of truth for base URL and model.
    init(settings: SettingsStore) {
        self.settings = settings
    }

    // MARK: - Model listing

    func listModels() async throws -> [String] {
        let baseURL = await MainActor.run { settings.baseURL }
        let url = baseURL.appendingPathComponent("/api/tags")
        let (data, response) = try await URLSession.shared.data(from: url)
        try verifyHTTPStatus(response)

        let payload = try decoder.decode(ModelListResponse.self, from: data)
        return payload.models.map(\.name)
    }

    // MARK: - Streaming

    func stream(_ request: ChatCompletionRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (baseURL, model) = await MainActor.run { (settings.baseURL, settings.model) }
                    let urlRequest = try makeChatRequest(request, baseURL: baseURL, model: model)
                    let (bytes, response) = try await streamingSession.bytes(for: urlRequest)
                    try verifyHTTPStatus(response, model: model)

                    for try await line in bytes.lines {
                        guard !line.isEmpty else { continue }

                        let decoded: NDJSONLine
                        do {
                            decoded = try NDJSONLine.parse(line, using: self.decoder)
                        } catch {
                            throw OllamaError.decodingFailed(underlying: error)
                        }

                        if let errorMessage = decoded.error, !errorMessage.isEmpty {
                            throw OllamaError.serverMessage(errorMessage)
                        }

                        if decoded.done == true {
                            if decoded.doneReason == "length" {
                                // Stopped because maxTokens was reached, not an error.
                                print("Ollama stream stopped early: hit maxTokens limit")
                            }
                            continuation.finish()
                            return
                        }

                        if let content = decoded.message?.content {
                            continuation.yield(content)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: mapError(error))
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Request building

    private func makeChatRequest(_ request: ChatCompletionRequest, baseURL: URL, model: String) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("/api/chat")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatRequest(
            model: model,
            messages: request.messages.map { ChatMessage(role: $0.role.rawValue, content: $0.content) },
            stream: true,
            options: ChatOptions(
                temperature: request.temperature,
                numPredict: request.maxTokens,
                numCtx: contextWindowSize(for: request)
            )
        )

        urlRequest.httpBody = try JSONEncoder().encode(body)
        return urlRequest
    }

    /// Estimates a context window large enough for the whole conversation plus the reply.
    /// Ollama defaults to 2048 tokens and would otherwise truncate long input silently.
    private func contextWindowSize(for request: ChatCompletionRequest) -> Int {
        let characters = request.messages.reduce(0) { $0 + $1.content.count }
        let required = characters / 4 + request.maxTokens + 256   // ~4 chars per token
        return min(max(required, 2048), 32768)
    }

    // MARK: - Helpers

    private func verifyHTTPStatus(_ response: URLResponse, model: String = "") throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.unexpectedStatus(0)
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 404:
            throw OllamaError.modelNotFound(model)
        default:
            throw OllamaError.unexpectedStatus(httpResponse.statusCode)
        }
    }

    private func mapError(_ error: Error) -> Error {
        // Keep already-mapped errors untouched.
        if let ollamaError = error as? OllamaError {
            return ollamaError
        }

        let nsError = error as NSError
        switch nsError.code {
        case NSURLErrorCannotConnectToHost,
             NSURLErrorCannotFindHost,
             NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorTimedOut:
            return OllamaError.notRunning
        default:
            return error
        }
    }
}

// MARK: - Request/response types

private extension OllamaProvider {
    struct ChatRequest: Encodable {
        let model: String
        let messages: [ChatMessage]
        let stream: Bool
        let options: ChatOptions
    }

    struct ChatMessage: Encodable {
        let role: String
        let content: String
    }

    struct ChatOptions: Encodable {
        let temperature: Double
        let numPredict: Int
        let numCtx: Int

        enum CodingKeys: String, CodingKey {
            case temperature
            case numPredict = "num_predict"
            case numCtx = "num_ctx"
        }
    }

    struct ModelListResponse: Decodable {
        struct Model: Decodable {
            let name: String
        }

        let models: [Model]
    }
}
