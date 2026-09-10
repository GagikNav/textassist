import SwiftUI

/// Root view for the app's Settings / Preferences window.
///
/// This view is hosted by the `Settings` scene in `TextSummarizerApp`.
struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    let provider: any LLMProvider

    var body: some View {
        ProviderSettingsView(settings: settings, provider: provider)
    }
}
