import Foundation
import Testing

@testable import BarikEnhanced

@Suite struct PopupPlacementFrames {
    let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
    let popup = CGSize(width: 200, height: 100)

    func frame(anchorX: CGFloat, atBottom: Bool = false) -> CGRect {
        PopupPlacement(anchorX: anchorX, barHeight: 30, atBottom: atBottom).frame(for: popup, in: screen)
    }

    @Test func centredUnderTheWidgetWithAGapBelowTheBar() {
        #expect(frame(anchorX: 700) == CGRect(x: 600, y: 30 + PopupStyle.gapBelowBar, width: 200, height: 100))
    }

    @Test func clampedToTheScreenEdges() {
        #expect(frame(anchorX: 1430).maxX == 1440 - PopupStyle.screenMargin)
        #expect(frame(anchorX: 10).minX == PopupStyle.screenMargin)
    }

    @Test func aboveABottomBar() {
        #expect(frame(anchorX: 700, atBottom: true).maxY == 900 - 30 - PopupStyle.gapBelowBar)
    }
}
