import Foundation
import SwiftUI

/// One `[widgets.script.<name>]` table. See the script widget contract (v1).
struct ScriptWidgetSettings: Equatable {
    enum Mode: String {
        case poll, stream
    }

    static let defaultPath =
        "/run/current-system/sw/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    static let defaultInterval: TimeInterval = 60

    let command: String
    let mode: Mode
    /// Poll only. 0 means the script runs only at start and on its events.
    let interval: TimeInterval
    let events: [String]
    let path: String

    init(command: String, mode: Mode = .poll, interval: TimeInterval = defaultInterval,
         events: [String] = [], path: String = defaultPath) {
        self.command = command
        self.mode = mode
        self.interval = interval
        self.events = events
        self.path = path
    }

    /// Nil when the table has no `command`.
    init?(config: ConfigData, path: String?, home: String = NSHomeDirectory()) {
        guard let rawCommand = config["command"]?.stringValue?
            .trimmingCharacters(in: .whitespaces), !rawCommand.isEmpty
        else { return nil }

        let command = rawCommand.hasPrefix("~/")
            ? home + rawCommand.dropFirst()
            : rawCommand
        let interval: TimeInterval
        switch config["interval"] {
        case .int(let value): interval = TimeInterval(max(0, value))
        case .double(let value): interval = max(0, value)
        default: interval = Self.defaultInterval
        }

        self.init(
            command: command,
            mode: config["mode"]?.stringValue.flatMap(Mode.init(rawValue:)) ?? .poll,
            interval: interval,
            events: config["events"]?.arrayValue?.compactMap(\.stringValue) ?? [],
            path: path ?? Self.defaultPath)
    }

    var environment: [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = path
        environment["HOME"] = NSHomeDirectory()
        return environment
    }
}

/// Root `[script]` table.
struct ScriptRootConfig: Decodable {
    let path: String?
}

// MARK: - Script output

struct ScriptDocument: Decodable, Equatable {
    let items: [ScriptItem]

    init(items: [ScriptItem]) {
        self.items = items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try container.decode([ScriptItem].self, forKey: .items)
        var seen = Set<String>()
        items = decoded.enumerated().map { index, item in
            var id = item.id.isEmpty ? "item-\(index)" : item.id
            if seen.contains(id) { id += "#\(index)" }
            seen.insert(id)
            return item.with(id: id)
        }
    }

    static func parse(_ data: Data) throws -> ScriptDocument {
        try JSONDecoder().decode(ScriptDocument.self, from: data)
    }

    private enum CodingKeys: String, CodingKey { case items }
}

struct ScriptItem: Decodable, Equatable, Identifiable {
    enum Style: String { case pill, plain }
    enum Animation: String { case none, pulse, shake, spin }

    let id: String
    let icon: ScriptIcon?
    let label: String?
    let color: ScriptColor?
    let style: Style
    let outline: Bool
    let joined: Bool
    let animation: Animation
    let tooltip: String?
    let click: String?
    let rightClick: String?
    let popup: [ScriptPopupRow]

    init(id: String, icon: ScriptIcon? = nil, label: String? = nil, color: ScriptColor? = nil,
         style: Style = .pill, outline: Bool = false, joined: Bool = false,
         animation: Animation = .none, tooltip: String? = nil, click: String? = nil,
         rightClick: String? = nil, popup: [ScriptPopupRow] = []) {
        self.id = id
        self.icon = icon
        self.label = label
        self.color = color
        self.style = style
        self.outline = outline
        self.joined = joined
        self.animation = animation
        self.tooltip = tooltip
        self.click = click
        self.rightClick = rightClick
        self.popup = popup
    }

    /// Unknown or mistyped optional fields fall back to their defaults, so one
    /// odd value does not blank the whole widget.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func string(_ key: CodingKeys) -> String? {
            (try? c.decodeIfPresent(String.self, forKey: key)).flatMap { $0?.isEmpty == false ? $0 : nil }
        }
        func bool(_ key: CodingKeys) -> Bool {
            ((try? c.decodeIfPresent(Bool.self, forKey: key)) ?? nil) ?? false
        }
        self.init(
            id: string(.id) ?? "",
            icon: string(.icon).flatMap(ScriptIcon.init),
            label: string(.label),
            color: string(.color).flatMap(ScriptColor.init),
            style: string(.style).flatMap(Style.init(rawValue:)) ?? .pill,
            outline: bool(.outline),
            joined: bool(.joined),
            animation: string(.animation).flatMap(Animation.init(rawValue:)) ?? .none,
            tooltip: string(.tooltip),
            click: string(.click),
            rightClick: string(.rightClick),
            popup: ((try? c.decodeIfPresent([ScriptPopupRow].self, forKey: .popup)) ?? nil) ?? [])
    }

    func with(id: String) -> ScriptItem {
        ScriptItem(id: id, icon: icon, label: label, color: color, style: style,
                   outline: outline, joined: joined, animation: animation, tooltip: tooltip,
                   click: click, rightClick: rightClick, popup: popup)
    }

    private enum CodingKeys: String, CodingKey {
        case id, icon, label, color, style, outline, joined, animation, tooltip, click, popup
        case rightClick = "right_click"
    }
}

struct ScriptPopupRow: Decodable, Equatable {
    let icon: ScriptIcon?
    let label: String?
    let color: ScriptColor?
    let click: String?

    init(icon: ScriptIcon? = nil, label: String? = nil, color: ScriptColor? = nil, click: String? = nil) {
        self.icon = icon
        self.label = label
        self.color = color
        self.click = click
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func string(_ key: CodingKeys) -> String? {
            (try? c.decodeIfPresent(String.self, forKey: key)).flatMap { $0?.isEmpty == false ? $0 : nil }
        }
        self.init(
            icon: string(.icon).flatMap(ScriptIcon.init),
            label: string(.label),
            color: string(.color).flatMap(ScriptColor.init),
            click: string(.click))
    }

    private enum CodingKeys: String, CodingKey { case icon, label, color, click }
}

enum ScriptIcon: Equatable {
    case symbol(String)
    case app(bundleID: String)
    case file(path: String)
    case text(String)

    init?(_ raw: String) {
        guard let colon = raw.firstIndex(of: ":") else { return nil }
        let value = String(raw[raw.index(after: colon)...])
        guard !value.isEmpty else { return nil }
        switch raw[..<colon] {
        case "sf": self = .symbol(value)
        case "app": self = .app(bundleID: value)
        case "file":
            self = .file(path: value.hasPrefix("~/") ? NSHomeDirectory() + value.dropFirst() : value)
        case "text": self = .text(value)
        default: return nil
        }
    }
}

enum ScriptColor: Equatable {
    case accent, primary, secondary, red, orange, yellow, green, blue, purple, pink
    case rgb(red: Double, green: Double, blue: Double)

    init?(_ raw: String) {
        switch raw.lowercased() {
        case "accent": self = .accent
        case "primary": self = .primary
        case "secondary": self = .secondary
        case "red": self = .red
        case "orange": self = .orange
        case "yellow": self = .yellow
        case "green": self = .green
        case "blue": self = .blue
        case "purple": self = .purple
        case "pink": self = .pink
        default:
            guard raw.count == 7, raw.hasPrefix("#"),
                let value = UInt32(raw.dropFirst(), radix: 16)
            else { return nil }
            self = .rgb(
                red: Double((value >> 16) & 0xFF) / 255,
                green: Double((value >> 8) & 0xFF) / 255,
                blue: Double(value & 0xFF) / 255)
        }
    }

    var style: AnyShapeStyle {
        switch self {
        case .accent: AnyShapeStyle(Color.accentColor)
        case .primary: AnyShapeStyle(.primary)
        case .secondary: AnyShapeStyle(.secondary)
        case .red: AnyShapeStyle(Color.red)
        case .orange: AnyShapeStyle(Color.orange)
        case .yellow: AnyShapeStyle(Color.yellow)
        case .green: AnyShapeStyle(Color.green)
        case .blue: AnyShapeStyle(Color.blue)
        case .purple: AnyShapeStyle(Color.purple)
        case .pink: AnyShapeStyle(Color.pink)
        case let .rgb(red, green, blue): AnyShapeStyle(Color(red: red, green: green, blue: blue))
        }
    }
}
