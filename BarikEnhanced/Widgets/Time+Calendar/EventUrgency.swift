import Foundation

/// How close the next event is: `soon` in the 5 minutes before it starts,
/// `started` in the first 2 minutes after.
enum EventUrgency: Equatable {
    case none, soon, started

    static let soonWindow: TimeInterval = 5 * 60
    static let startedWindow: TimeInterval = 2 * 60

    init(start: Date, isAllDay: Bool, now: Date) {
        let untilStart = start.timeIntervalSince(now)
        if isAllDay {
            self = .none
        } else if untilStart > 0, untilStart <= Self.soonWindow {
            self = .soon
        } else if untilStart <= 0, -untilStart <= Self.startedWindow {
            self = .started
        } else {
            self = .none
        }
    }
}

/// `BARIK_DEBUG_NOW_OFFSET=<seconds>` in the app's environment shifts the
/// "now" that event urgency is measured against, so the colours can be
/// checked without waiting for a meeting. Unset means the real clock.
enum EventClock {
    private static let offset: TimeInterval =
        ProcessInfo.processInfo.environment["BARIK_DEBUG_NOW_OFFSET"].flatMap(TimeInterval.init) ?? 0

    static func now(_ real: Date = Date()) -> Date {
        real.addingTimeInterval(offset)
    }
}
