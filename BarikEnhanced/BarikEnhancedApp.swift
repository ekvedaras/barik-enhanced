import SwiftUI

@main
struct BarikEnhancedApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Before the log and before AppDelegate's single-instance guard: the
        // CLI runs while the bar is already running.
        BarikPushChannel.handleCommandLine()
        LogFile.start()
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
