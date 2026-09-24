import Foundation
import Combine

/// Stores user-configurable settings for the app.
///
/// Currently this is limited to the Ollama provider: base URL and model.
/// Values are persisted in `UserDefaults` and update the UI automatically
/// through `@Published` properties.
@MainActor
final class SettingsStore: ObservableObject, @unchecked Sendable {
    /// Default Ollama API endpoint used on first launch.
    static let defaultBaseURL = URL(string: "http://localhost:11434")!

    /// Default model used on first launch.
    static let defaultModel = "phi3:instruct"

    private static let baseURLKey = "com.textassist.ollamaBaseURL"
    private static let modelKey = "com.textassist.ollamaModel"

    /// Base URL of the Ollama server, for example `http://localhost:11434`.
    @Published var baseURL: URL {
        didSet { UserDefaults.standard.set(baseURL, forKey: Self.baseURLKey) }
    }

    /// Model identifier passed to Ollama, for example `phi3:instruct`.
    @Published var model: String {
        didSet { UserDefaults.standard.set(model, forKey: Self.modelKey) }
    }

    /// Creates the store, loading saved values or falling back to defaults.
    init() {
        self.baseURL = UserDefaults.standard.url(forKey: Self.baseURLKey) ?? Self.defaultBaseURL
        self.model = UserDefaults.standard.string(forKey: Self.modelKey) ?? Self.defaultModel
    }
}
