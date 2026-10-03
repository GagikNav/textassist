import Foundation
import Combine

/// Tracks whether the Ollama server is reachable and which models it offers.
@MainActor
final class OllamaStatusMonitor: ObservableObject {
    enum Status {
        case unknown, online, offline
    }

    @Published private(set) var status: Status = .unknown
    @Published private(set) var availableModels: [String] = []

    private let provider: any LLMProvider

    init(provider: any LLMProvider) {
        self.provider = provider
    }

    /// Re-checks the server. Call when the menu-bar popover appears.
    func refresh() async {
        do {
            availableModels = try await provider.listModels()
            status = .online
        } catch {
            availableModels = []
            status = .offline
        }
    }
}
