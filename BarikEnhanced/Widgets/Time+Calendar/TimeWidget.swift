import EventKit
import SwiftUI

struct TimeWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    var config: ConfigData { configProvider.config }
    var calendarConfig: ConfigData? { config["calendar"]?.dictionaryValue }

    var format: String { config["format"]?.stringValue ?? "E d, J:mm" }
    var timeZone: String? { config["time-zone"]?.stringValue }

    var calendarFormat: String {
        calendarConfig?["format"]?.stringValue ?? "J:mm"
    }
    var calendarShowEvents: Bool {
        calendarConfig?["show-events"]?.boolValue ?? true
    }

    @State private var currentTime = Date()
    let calendarManager: CalendarManager

    @State private var rect = CGRect()

    private let timer = Timer.publish(every: 5, on: .main, in: .common)
        .autoconnect()

    /// `calendar.events-inline = true` puts the next event left of the clock, so the widget fits a one-line bar.
    var calendarEventsInline: Bool {
        calendarConfig?["events-inline"]?.boolValue ?? false
    }

    private var nextEvent: EKEvent? {
        calendarShowEvents ? calendarManager.nextEvent : nil
    }

    var body: some View {
        let layout = calendarEventsInline
            ? AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
            : AnyLayout(VStackLayout(alignment: .trailing, spacing: 0))
        layout {
            if calendarEventsInline, let nextEvent {
                eventView(nextEvent)
            }
            Text(formattedTime(pattern: format, from: currentTime))
                .fontWeight(.semibold)
            if !calendarEventsInline, let nextEvent {
                eventView(nextEvent)
                    .font(.subheadline)
            }
        }
        .font(.headline)
        .lineLimit(1)
        .foregroundStyle(.foregroundOutside)
        .shadow(color: .foregroundShadowOutside, radius: 3)
        .fixedSize(horizontal: true, vertical: false)
        .onReceive(timer) { date in
            currentTime = date
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        rect = geometry.frame(in: .global)
                    }
                    .onChange(of: geometry.frame(in: .global)) {
                        oldState, newState in
                        rect = newState
                    }
            }
        )
        .experimentalConfiguration(cornerRadius: 15)
        .frame(maxHeight: .infinity)
        .background(.black.opacity(0.001))
        .contentShape(Rectangle())
        .monospacedDigit()
        .onTapGesture { showCalendarPopup() }
    }

    private func showCalendarPopup() {
        MenuBarPopup.show(rect: rect, id: "calendar") {
            CalendarPopup(
                calendarManager: calendarManager,
                configProvider: configProvider)
        }
    }

    /// Accent text in the 5 minutes before the event, an accent pill in the
    /// first 2 minutes after it starts. A click joins its Meet/Zoom/Teams link.
    private func eventView(_ event: EKEvent) -> some View {
        let urgency = EventUrgency(
            start: event.startDate, isAllDay: event.isAllDay, now: EventClock.now(currentTime))
        let link = MeetingLinkDetector.detect(
            structuredURL: event.url, location: event.location, notes: event.notes)
        return HStack(spacing: 4) {
            if let link {
                Image(systemName: link.service.symbolName)
                    .font(.caption)
            }
            Text(eventText(for: event))
        }
        .foregroundStyle(
            urgency == .started ? AnyShapeStyle(.black)
                : urgency == .soon ? AnyShapeStyle(Color.accentColor)
                : AnyShapeStyle(.foregroundOutside))
        .opacity(urgency == .none ? 0.8 : 1)
        .padding(.horizontal, urgency == .started ? 6 : 0)
        .background {
            if urgency == .started {
                Capsule().fill(Color.accentColor).padding(.vertical, -2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let link {
                MeetingJoinCoordinator().join(link)
            } else {
                showCalendarPopup()
            }
        }
        .help(link.map { "Join \($0.service.displayName)" } ?? "")
    }

    // Format the current time.
    private func formattedTime(pattern: String, from time: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate(pattern)

        if let timeZone = timeZone,
            let tz = TimeZone(identifier: timeZone)
        {
            formatter.timeZone = tz
        } else {
            formatter.timeZone = TimeZone.current
        }

        return formatter.string(from: time)
    }

    // Create text for the calendar event.
    private func eventText(for event: EKEvent) -> String {
        var text = event.title ?? ""
        if !event.isAllDay {
            text += " ("
            text += formattedTime(
                pattern: calendarFormat, from: event.startDate)
            text += ")"
        }
        return text
    }
}

struct TimeWidget_Previews: PreviewProvider {
    static var previews: some View {
        let provider = ConfigProvider(config: ConfigData())

        ZStack {
            TimeWidget(calendarManager: CalendarManager.shared)
                .environmentObject(provider)
        }.frame(width: 500, height: 100)
    }
}
