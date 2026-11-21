import Foundation
import Testing
import TOMLDecoder

@testable import BarikEnhanced

@Suite struct ZenConfigParsing {
    let toml = """
        [widgets]
        displayed = ["default.time", "default.cpuram"]

        [widgets.default.time]
        format = "E d MMM, HH:mm"
        calendar.format = "HH:mm"
        calendar.show-events = true

        [zen]
        hide = ["default.cpuram"]

        [zen.widgets.default.time]
        format = "HH:mm"
        calendar.show-events = false
        """

    @Test func hidesListedWidgetsAndMergesOverridesDeeply() throws {
        let root = try TOMLDecoder().decode(RootToml.self, from: toml)
        let zen = try #require(root.zen)
        #expect(zen.hides("default.cpuram"))
        #expect(!zen.hides("default.time"))

        let time = zen.apply(to: try #require(root.widgets.config(for: "default.time")), of: "default.time")
        #expect(time["format"]?.stringValue == "HH:mm")
        let calendar = try #require(time["calendar"]?.dictionaryValue)
        #expect(calendar["show-events"]?.boolValue == false)
        #expect(calendar["format"]?.stringValue == "HH:mm")
    }

    @Test func widgetsWithoutOverridesKeepTheirConfig() throws {
        let zen = try #require(try TOMLDecoder().decode(RootToml.self, from: toml).zen)
        let config: ConfigData = ["show-icon": .bool(true)]
        #expect(zen.apply(to: config, of: "default.cpuram")["show-icon"]?.boolValue == true)
    }
}
