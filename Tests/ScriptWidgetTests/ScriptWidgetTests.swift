import Foundation
import Testing
import TOMLDecoder

@testable import BarikEnhanced

@Suite struct ScriptDocumentDecoding {
    @Test func decodesEveryContractField() throws {
        let json = """
            {"items": [{
              "id": "pr-525", "icon": "sf:arrow.triangle.pull", "label": "acme/widgets #525",
              "color": "green", "style": "plain", "outline": true, "joined": true,
              "animation": "pulse", "tooltip": "Fix import", "click": "open x",
              "right_click": "echo r",
              "popup": [{"icon": "sf:checkmark", "label": "CI passed", "color": "#ff8000", "click": "echo p"}]
            }]}
            """
        let item = try #require(ScriptDocument.parse(Data(json.utf8)).items.first)

        #expect(item == ScriptItem(
            id: "pr-525", icon: .symbol("arrow.triangle.pull"), label: "acme/widgets #525",
            color: .green, style: .plain, outline: true, joined: true, animation: .pulse,
            tooltip: "Fix import", click: "open x", rightClick: "echo r",
            popup: [ScriptPopupRow(icon: .symbol("checkmark"), label: "CI passed",
                                   color: .rgb(red: 1, green: 128.0 / 255, blue: 0), click: "echo p")]))
    }

    @Test func missingAndUnknownFieldsFallBackToDefaults() throws {
        let json = """
            {"items": [{"label": "a", "style": "fancy", "animation": "wobble", "color": "teal",
                        "icon": "nope", "joined": "yes", "extra": 1}]}
            """
        let item = try #require(ScriptDocument.parse(Data(json.utf8)).items.first)

        #expect(item == ScriptItem(id: "item-0", label: "a"))
    }

    @Test func decodesSeparatorStyle() throws {
        let json = #"{"items": [{"id": "sep", "style": "separator"}]}"#
        let item = try #require(ScriptDocument.parse(Data(json.utf8)).items.first)

        #expect(item.style == .separator)
    }

    @Test func duplicateIdsAreMadeUnique() throws {
        let json = #"{"items": [{"id": "a"}, {"id": "a"}, {}]}"#
        let ids = try ScriptDocument.parse(Data(json.utf8)).items.map(\.id)

        #expect(ids == ["a", "a#1", "item-2"])
    }

    @Test func emptyItemsIsAValidDocument() throws {
        #expect(try ScriptDocument.parse(Data(#"{"items": []}"#.utf8)).items.isEmpty)
    }

    @Test func documentWithoutItemsIsAnError() {
        #expect(throws: (any Error).self) { try ScriptDocument.parse(Data(#"{"foo": 1}"#.utf8)) }
        #expect(throws: (any Error).self) { try ScriptDocument.parse(Data("not json".utf8)) }
    }

    @Test(arguments: [
        ("sf:bell", ScriptIcon.symbol("bell")),
        ("app:com.apple.Safari", .app(bundleID: "com.apple.Safari")),
        ("file:/tmp/a.png", .file(path: "/tmp/a.png")),
        ("text:🎧", .text("🎧")),
        ("text:a:b", .text("a:b")),
    ])
    func iconPrefixes(raw: String, icon: ScriptIcon) {
        #expect(ScriptIcon(raw) == icon)
    }
}

@Suite struct ScriptWidgetConfig {
    private func root(_ toml: String) throws -> RootToml {
        try TOMLDecoder().decode(RootToml.self, from: toml)
    }

    @Test func parsesAStreamWidgetAndTheRootPath() throws {
        let root = try root("""
            [script]
            path = "/custom/bin:/usr/bin"

            [widgets]
            displayed = ["script.claude"]

            [widgets.script.claude]
            command = "~/.config/barik/scripts/claude.sh"
            mode = "stream"
            events = ["claude", "system_woke"]
            """)
        let config = try #require(root.widgets.config(for: "script.claude"))
        let settings = try #require(
            ScriptWidgetSettings(config: config, path: root.script?.path, home: "/Users/me"))

        #expect(settings == ScriptWidgetSettings(
            command: "/Users/me/.config/barik/scripts/claude.sh", mode: .stream,
            interval: ScriptWidgetSettings.defaultInterval, events: ["claude", "system_woke"],
            path: "/custom/bin:/usr/bin"))
    }

    @Test func pollDefaultsAndZeroInterval() throws {
        let root = try root("""
            [widgets]
            displayed = ["script.prs"]

            [widgets.script.prs]
            command = "gh pr list"
            interval = 0
            """)
        let config = try #require(root.widgets.config(for: "script.prs"))
        let settings = try #require(ScriptWidgetSettings(config: config, path: root.script?.path))

        #expect(settings == ScriptWidgetSettings(
            command: "gh pr list", mode: .poll, interval: 0, events: [],
            path: ScriptWidgetSettings.defaultPath))
    }

    @Test func tableWithoutCommandIsRejected() {
        #expect(ScriptWidgetSettings(config: ["mode": .string("poll")], path: nil) == nil)
    }
}
