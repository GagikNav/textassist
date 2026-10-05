import SwiftUI
import KeyboardShortcuts
import ServiceManagement

/// SwiftUI form for the app's settings.
///
/// Groups the global keyboard shortcuts and launch-at-login toggle under a
/// "General" section, and the Ollama base URL and model under "Ollama". The
/// model list is fetched from the configured server and shown in a picker. If
/// the server cannot be reached, a plain text field is shown instead so the
/// user can still type a model name.
struct ProviderSettingsView: View {
    @ObservedObject var settings: SettingsStore
    let provider: any LLMProvider

    @State private var models: [String] = []
    @State private var isLoadingModels = false
    @State private var modelLoadError: String?
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Assist:", name: .summarizeSelection)
                KeyboardShortcuts.Recorder("Chat:", name: .chatWithSelection)
                KeyboardShortcuts.Recorder("Fix grammar:", name: .fixGrammar)

                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = !enabled
                        }
                    }
            } header: {
                Text("General")
            }

            Section {
                TextField("Base URL", text: baseURLBinding)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()

                if shouldShowPicker {
                    Picker("Model", selection: $settings.model) {
                        if !models.contains(settings.model) {
                            Text(settings.model).tag(settings.model)
                        }
                        ForEach(models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                } else {
                    TextField("Model", text: $settings.model)
                        .textFieldStyle(.roundedBorder)
                }

                if let error = modelLoadError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Spacer()
                    Button("Refresh Models") {
                        Task { await loadModels() }
                    }
                    .disabled(isLoadingModels)
                }
            } header: {
                Text("Ollama")
            } footer: {
                Text("Changes take effect on the next summary.")
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 360, minHeight: 400)
        .task {
            await loadModels()
        }
    }

    /// Shows the picker only when we have a model list and no load error.
    private var shouldShowPicker: Bool {
        !models.isEmpty && modelLoadError == nil
    }

    /// Binds the `URL` base URL to a string text field, validating the input.
    private var baseURLBinding: Binding<String> {
        Binding(
            get: { settings.baseURL.absoluteString },
            set: { newValue in
                if let url = URL(string: newValue), url.scheme != nil {
                    settings.baseURL = url
                }
            }
        )
    }

    /// Fetches the list of available models from the provider.
    private func loadModels() async {
        isLoadingModels = true
        modelLoadError = nil
        defer { isLoadingModels = false }

        do {
            models = try await provider.listModels()
        } catch {
            models = []
            modelLoadError = (error as? LocalizedError)?.localizedDescription
                ?? error.localizedDescription
        }
    }
}

#if DEBUG
#Preview {
    ProviderSettingsView(settings: SettingsStore(), provider: OllamaProvider(settings: SettingsStore()))
}
#endif
