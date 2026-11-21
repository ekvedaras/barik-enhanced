import Foundation
import Testing

@testable import BarikEnhanced

@Suite struct ScriptOverflowHiding {
    func entry(_ id: String, _ minX: CGFloat, _ width: CGFloat) -> ScriptOverflow.Entry {
        ScriptOverflow.Entry(name: "w", itemID: id, frame: CGRect(x: minX, y: 0, width: width, height: 20))
    }

    @Test func nothingHidesWhileEverythingFits() {
        #expect(ScriptOverflow.hidden([entry("a", 0, 50), entry("b", 60, 50)], visibleMaxX: 110).isEmpty)
    }

    @Test func overflowAlsoHidesWhatSitsWhereTheBadgeGoes() {
        let entries = [entry("c", 120, 50), entry("a", 0, 50), entry("b", 60, 50)]
        let hidden = ScriptOverflow.hidden(entries, visibleMaxX: 150).map(\.itemID)
        #expect(hidden == ["b", "c"])
    }
}
