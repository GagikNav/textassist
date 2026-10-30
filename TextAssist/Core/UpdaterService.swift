import Foundation
import AppKit
import Combine
import Sparkle

/// Checks GitHub for newer releases and installs them, using Sparkle.
///
/// The feed address and the update-signing public key come from `Info.plist`
/// (`SUFeedURL`, `SUPublicEDKey`). Release builds start the updater at launch, so it checks
/// on a schedule. Debug builds report version `1.0` and would always see an "update", so
/// they start the updater only when the user asks for a check.
final class UpdaterService: ObservableObject {
    /// Whether a check can start now. `false` while a check or install is already running.
    @Published private(set) var canCheckForUpdates: Bool

    private let controller: SPUStandardUpdaterController
    private var hasStarted: Bool
    private var cancellable: AnyCancellable?

    /// Creates the updater and, in Release builds, starts it.
    init() {
        #if DEBUG
        let startsAtLaunch = false
        #else
        let startsAtLaunch = true
        #endif

        controller = SPUStandardUpdaterController(
            startingUpdater: startsAtLaunch,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        hasStarted = startsAtLaunch
        // Before the updater starts, a manual check is still allowed: it starts the updater.
        canCheckForUpdates = !startsAtLaunch

        cancellable = controller.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self, self.hasStarted else { return }
                self.canCheckForUpdates = value
            }
    }

    /// Whether Sparkle checks for updates on its own schedule. Stored by Sparkle in the
    /// app's preferences.
    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set {
            objectWillChange.send()
            controller.updater.automaticallyChecksForUpdates = newValue
        }
    }

    /// Starts a check now and shows Sparkle's window with the result.
    ///
    /// The app is menu-bar only, so Sparkle's window would open behind other apps. Bring the
    /// app forward here, for this explicit user request only; the floating panels stay
    /// non-activating.
    func checkForUpdates() {
        if #available(macOS 14.0, *) {
            NSApplication.shared.activate()
        } else {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        if !hasStarted {
            hasStarted = true
            controller.startUpdater()
        }
        controller.checkForUpdates(nil)
    }
}
