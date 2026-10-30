import SwiftUI

/// Root view for the app's Settings / Preferences window.
///
/// This view is hosted by the `Settings` scene in `TextAssistApp`.
struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var updater: UpdaterService
    let provider: any LLMProvider

    var body: some View {
        ProviderSettingsView(settings: settings, updater: updater, provider: provider)
    }
}
