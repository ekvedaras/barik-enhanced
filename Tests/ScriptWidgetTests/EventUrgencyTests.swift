import Foundation
import Testing

@testable import BarikEnhanced

@Suite struct EventUrgencyWindows {
    let start = Date(timeIntervalSinceReferenceDate: 1_000_000)

    func urgency(secondsBeforeStart: TimeInterval, isAllDay: Bool = false) -> EventUrgency {
        EventUrgency(start: start, isAllDay: isAllDay, now: start.addingTimeInterval(-secondsBeforeStart))
    }

    @Test func soonInTheFiveMinutesBeforeStart() {
        #expect(urgency(secondsBeforeStart: 301) == .none)
        #expect(urgency(secondsBeforeStart: 300) == .soon)
        #expect(urgency(secondsBeforeStart: 1) == .soon)
    }

    @Test func startedInTheFirstTwoMinutes() {
        #expect(urgency(secondsBeforeStart: 0) == .started)
        #expect(urgency(secondsBeforeStart: -120) == .started)
        #expect(urgency(secondsBeforeStart: -121) == .none)
    }

    @Test func allDayEventsAreNeverUrgent() {
        #expect(urgency(secondsBeforeStart: 60, isAllDay: true) == .none)
    }
}
