import Foundation
import SwiftUI

/// `[zen]` in the config: what zen mode takes off the bar.
///
/// ```toml
/// [zen]
/// hide = ["default.cpuram", "script.github-prs"]   # widget ids
///
/// [zen.widgets.default.time]                        # merged over [widgets.default.time]
/// format = "HH:mm"
/// ```
struct ZenConfig: Decodable {
    let hide: [String]
    let widgets: ConfigData

    init(hide: [String] = [], widgets: ConfigData = [:]) {
        self.hide = hide
        self.widgets = widgets
    }

    enum CodingKeys: String, CodingKey { case hide, widgets }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hide = try container.decodeIfPresent([String].self, forKey: .hide) ?? []
        widgets = try container.decodeIfPresent(ConfigData.self, forKey: .widgets) ?? [:]
    }

    func hides(_ widgetId: String) -> Bool {
        hide.contains(widgetId)
    }

    /// The widget's config with its `[zen.widgets.<id>]` table merged over it.
    func apply(to config: ConfigData, of widgetId: String) -> ConfigData {
        var overrides: ConfigData? = widgets
        for key in widgetId.split(separator: ".") {
            overrides = overrides?[String(key)]?.dictionaryValue
        }
        return config.deepMerging(overrides ?? [:])
    }
}

extension Dictionary where Key == String, Value == TOMLValue {
    /// Tables merge key by key, so `calendar.show-events` keeps `calendar.format`.
    func deepMerging(_ other: ConfigData) -> ConfigData {
        var merged = self
        for (key, value) in other {
            if case .dictionary(let overrides) = value, case .dictionary(let base)? = merged[key] {
                merged[key] = .dictionary(base.deepMerging(overrides))
            } else {
                merged[key] = value
            }
        }
        return merged
    }
}

/// Zen mode on or off for the running bar. Toggled by `barik zen [on|off]`,
/// a right click on the clock, or the bar's context menu. Survives restarts (UserDefaults).
final class ZenMode: ObservableObject {
    static let shared = ZenMode()
    private static let defaultsKey = "zenMode"

    @Published private(set) var isOn = UserDefaults.standard.bool(forKey: defaultsKey)

    private init() {
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(didReceiveCommand(_:)),
            name: BarikPushChannel.zen, object: nil, suspensionBehavior: .deliverImmediately)
    }

    func set(_ on: Bool) {
        guard on != isOn else { return }
        print("[zen] \(on ? "on" : "off")")
        withAnimation(.smooth(duration: 0.3)) { isOn = on }
        UserDefaults.standard.set(on, forKey: Self.defaultsKey)
    }

    func toggle() {
        set(!isOn)
    }

    @objc private func didReceiveCommand(_ notification: Notification) {
        switch notification.object as? String {
        case "on": set(true)
        case "off": set(false)
        default: toggle()
        }
    }
}
