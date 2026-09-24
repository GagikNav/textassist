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

    // MARK: - Streaming summary

    func summarize(_ request: SummaryRequest) -> AsyncThrowingStream<String, Error> {
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

    private func makeChatRequest(_ request: SummaryRequest, baseURL: URL, model: String) throws -> URLRequest {
        let url = baseURL.appendingPathComponent("/api/chat")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ChatRequest(
            model: model,
            messages: [
                ChatMessage(role: "system", content: Self.systemPrompt),
                ChatMessage(role: "user", content: request.userMessage)
            ],
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

    /// Estimates a context window large enough to hold the prompt and the
    /// generated response, since Ollama defaults to only 2048 tokens and
    /// would otherwise truncate long captured text mid-stream.
    private func contextWindowSize(for request: SummaryRequest) -> Int {
        // Rough heuristic: ~4 characters per token, plus generation headroom.
        let estimatedPromptTokens = request.userMessage.count / 4
        let required = estimatedPromptTokens + request.maxTokens + 256
        return min(max(required, 2048), 32768)
    }

    /// Provider-agnostic default system prompt from the PRD.
    private static let systemPrompt = """
        You are a precise summarization engine. Follow the user's instructions exactly. \
        Never add information not present in the source. Respond in Markdown.
        """

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
