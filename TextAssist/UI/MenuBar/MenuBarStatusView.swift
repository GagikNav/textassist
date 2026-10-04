import SwiftUI

/// SwiftUI view that defines the contents of the menu-bar dropdown menu.
struct MenuBarStatusView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var monitor: OllamaStatusMonitor

    let onSummarize: () -> Void
    let onSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text("Ollama · \(settings.model)")
                    .font(.subheadline)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)

            if monitor.status == .online && !monitor.availableModels.isEmpty {
                Picker("Model", selection: $settings.model) {
                    if !monitor.availableModels.contains(settings.model) {
                        Text(settings.model).tag(settings.model)
                    }
                    ForEach(monitor.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            if monitor.status == .offline {
                Text("Not running. Start Ollama and try again.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }

            Divider()

            Button {
                onSummarize()
            } label: {
                HStack {
                    Text("Assist with Selection")
                    Spacer(minLength: 0)
                    Text("⌥⇧S")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)

            Button {
                onSettings()
            } label: {
                HStack {
                    Text("Settings…")
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Text("Quit")
                    Spacer(minLength: 0)
                    Text("⌘Q")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .keyboardShortcut("Q")
        }
        .padding(.vertical, 4)
        .onAppear {
            Task {
                await monitor.refresh()
            }
        }
    }

    /// Color of the Ollama status dot: green online, red offline, gray while unknown.
    private var statusColor: Color {
        switch monitor.status {
        case .online: return .green
        case .offline: return .red
        case .unknown: return .gray
        }
    }
}

#if DEBUG
#Preview {
    MenuBarStatusView(
        settings: SettingsStore(),
        monitor: OllamaStatusMonitor(provider: OllamaProvider(settings: SettingsStore())),
        onSummarize: {},
        onSettings: {}
    )
}
#endif
