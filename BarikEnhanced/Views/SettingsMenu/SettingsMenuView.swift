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
            SettingsMenuItem(icon: "square.grid.2x2", title: "Configure Widgets") {
                WidgetConfiguratorWindow.show()
            }

            SettingsMenuItem(icon: backgroundBlurEnabled ? "checkmark" : nil, title: "Blur Background") {
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

            SettingsMenuItem(icon: launchAtLogin ? "checkmark" : nil, title: "Launch at Login") {
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

            Divider().padding(.horizontal, 10).padding(.vertical, 4)

            SettingsMenuItem(icon: "info.circle", title: "About Barik Enhanced") {
                AboutWindow.show()
            }

            SettingsMenuItem(icon: "power", title: "Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(PopupStyle.menuInset)
        .frame(width: 240)
    }
}

/// A menu row; an icon of nil leaves its column empty, like an unchecked menu item.
struct SettingsMenuItem: View {
    let icon: String?
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon ?? "circle")
                    .font(.system(size: 13))
                    .opacity(icon == nil ? 0 : 0.8)
                    .frame(width: 18)

                Text(title)
                    .font(.system(size: 13))
            }
            .popupRow()
        }
        .buttonStyle(.plain)
    }
}
