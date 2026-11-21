import SwiftUI
import ServiceManagement

struct SettingsMenuView: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @ObservedObject private var configManager = ConfigManager.shared

    private var backgroundBlurEnabled: Bool {
        configManager.config.experimental.background.displayed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PopupStyle.rowSpacing) {
            PopupMenuItem(icon: "square.grid.2x2", title: "Configure Widgets") {
                WidgetConfiguratorWindow.show()
            }

            PopupMenuItem(icon: backgroundBlurEnabled ? "checkmark" : nil, title: "Blur Background") {
                configManager.updateConfigValue(
                    key: "experimental.background.displayed",
                    newValue: backgroundBlurEnabled ? "false" : "true",
                    wrapInQuotes: false)
                if !backgroundBlurEnabled {
                    // 1 is the ultra-thin material: a full-screen frosting that
                    // still shows the wallpaper instead of a flat gray wash.
                    configManager.updateConfigValue(
                        key: "experimental.background.blur",
                        newValue: "1",
                        wrapInQuotes: false)
                }
            }

            PopupMenuItem(icon: launchAtLogin ? "checkmark" : nil, title: "Launch at Login") {
                launchAtLogin.toggle()
                do {
                    if launchAtLogin {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    launchAtLogin = !launchAtLogin
                }
            }

            PopupMenuDivider()

            PopupMenuItem(icon: "info.circle", title: "About Barik Enhanced") {
                AboutWindow.show()
            }

            PopupMenuItem(icon: "power", title: "Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(PopupStyle.menuInset)
        .frame(width: 240)
    }
}
