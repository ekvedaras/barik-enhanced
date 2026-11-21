import SwiftUI

@main
struct BarikEnhancedApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        LogFile.start()
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
