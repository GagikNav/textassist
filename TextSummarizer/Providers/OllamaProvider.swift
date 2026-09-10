import Foundation

/// An `LLMProvider` that talks to a local Ollama server.
///
/// Uses `POST /api/chat` with streaming NDJSON responses.
final class OllamaProvider: LLMProvider {
    /// Default Ollama API endpoint.
    static let defaultBaseURL = URL(string: "http://localhost:11434")!

    /// Default model to use until a model selector is added.
    static let defaultModel = "phi3:instruct"

    /// Base URL of the Ollama server, for example `http://localhost:11434`.
    let baseURL: URL

    /// Model identifier passed to Ollama, for example `phi3:instruct`.
    let model: String

    /// Shared decoder reused across requests.
    private let decoder = JSONDecoder()

    var displayName: String { "Ollama" }

    /// Creates an Ollama provider.
    /// - Parameters:
    ///   - baseURL: The server base URL. Defaults to `http://localhost:11434`.
    ///   - model: The model name. Defaults to `phi3:instruct`.
    init(baseURL: URL = OllamaProvider.defaultBaseURL,
         model: String = OllamaProvider.defaultModel) {
        self.baseURL = baseURL
        self.model = model
    }

    // MARK: - Model listing

    func listModels() async throws -> [String] {
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
                    let urlRequest = try makeChatRequest(request)
                    let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
                    try verifyHTTPStatus(response)

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

    private func makeChatRequest(_ request: SummaryRequest) throws -> URLRequest {
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
                numPredict: request.maxTokens
            )
        )

        urlRequest.httpBody = try JSONEncoder().encode(body)
        return urlRequest
    }

    /// Provider-agnostic default system prompt from the PRD.
    private static let systemPrompt = """
        You are a precise summarization engine. Follow the user's instructions exactly. \
        Never add information not present in the source. Respond in Markdown.
        """

    // MARK: - Helpers

    private func verifyHTTPStatus(_ response: URLResponse) throws {
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

        enum CodingKeys: String, CodingKey {
            case temperature
            case numPredict = "num_predict"
        }
    }

    struct ModelListResponse: Decodable {
        struct Model: Decodable {
            let name: String
        }

        let models: [Model]
    }
}
