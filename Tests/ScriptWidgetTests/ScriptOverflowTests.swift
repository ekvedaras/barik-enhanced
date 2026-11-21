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

    @Test func badgeNeverCoversAFixedWidgetThatReachesTheBadgeRoom() {
        // Spaces end at 290, the visible section ends at 300: the old clamp put the badge at 252, over them.
        let all = [entry("a", 300, 50)]
        let hidden = ScriptOverflow.hidden(all, visibleMaxX: 300)
        let shown = ScriptOverflow.shownMaxX(
            hidden: hidden, all: all, fixed: [CGRect(x: 0, y: 0, width: 290, height: 20)], sectionMinX: 0)
        #expect(ScriptOverflow.badgeMinX(hidden: hidden, visibleMaxX: 300, shownMaxX: shown, spacing: 8) == 298)
    }

    @Test func badgeTakesTheFirstHiddenItemsPlace() {
        let all = [entry("a", 0, 50), entry("b", 60, 50), entry("c", 120, 50)]
        let hidden = ScriptOverflow.hidden(all, visibleMaxX: 150)
        let shown = ScriptOverflow.shownMaxX(hidden: hidden, all: all, fixed: [], sectionMinX: 0)
        #expect(ScriptOverflow.badgeMinX(hidden: hidden, visibleMaxX: 150, shownMaxX: shown, spacing: 8) == 60)
    }

    @Test func fixedWidgetsLeaveRoomForTheBadgeOnlyWhileItShows() {
        #expect(ScriptOverflow.room(from: 10, visibleMaxX: 300, overflowing: false, spacing: 8) == 290)
        #expect(ScriptOverflow.room(from: 10, visibleMaxX: 300, overflowing: true, spacing: 8) == 234)
    }
}
