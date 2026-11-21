import SwiftUI

private var panels: [NSPanel] = []

class HidingPanel: NSPanel, NSWindowDelegate {
    var hideTimer: Timer?

    override var canBecomeKey: Bool {
        return true
    }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing bufferingType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect, styleMask: style, backing: bufferingType,
            defer: flag)
        self.delegate = self
    }

    deinit {
        hideTimer?.invalidate()
        hideTimer = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        hide(returningFocus: false)
    }

    /// Losing key means focus already went elsewhere, so only explicit closes return it.
    func hide(returningFocus: Bool = true) {
        if returningFocus { MenuBarPopup.returnFocus() }
        hideTimer?.invalidate()
        NotificationCenter.default.post(name: .willHideWindow, object: nil)
        hideTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(
                Constants.menuBarPopupAnimationDurationInMilliseconds) / 1000.0,
            repeats: false
        ) { [weak self] _ in
            self?.orderOut(nil)
        }
    }
}

class MenuBarPopup {
    static var lastContentIdentifier: String? = nil
    static var currentScreenIndex: Int? = nil

    /// The app that had focus before a popup opened. Barik takes focus while a
    /// popup is open, because only the active app gets key events (Escape).
    private static var previousApp: NSRunningApplication?

    private static func takeFocus() {
        _ = closeMonitor
        let front = NSWorkspace.shared.frontmostApplication
        if front != NSRunningApplication.current {
            previousApp = front
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Gives focus back only while Barik still has it: a click into another app keeps that app.
    /// Escape, or a click in the bar outside the popup, closes an open popup.
    /// Clicks in other apps already close it: the panel loses key.
    private static let closeMonitor = NSEvent.addLocalMonitorForEvents(
        matching: [.keyDown, .leftMouseUp, .rightMouseUp]
    ) { event in
        guard let open = panels.first(where: { $0.isVisible }) as? HidingPanel else { return event }
        if event.type == .keyDown {
            guard event.keyCode == 53 else { return event }
            lastContentIdentifier = nil
            open.hide()
            return nil
        }
        if event.window !== open {
            // A click on another widget swaps the popup's content instead.
            let shownBefore = lastContentIdentifier
            DispatchQueue.main.async {
                if lastContentIdentifier == shownBefore { open.hide() }
            }
        }
        return event
    }

    static func returnFocus() {
        defer { previousApp = nil }
        guard NSApp.isActive, let previousApp else { return }
        previousApp.activate()
    }

    static func show<Content: View>(
        rect: CGRect, id: String, @ViewBuilder content: @escaping () -> Content
    ) {
        // Determine which screen the widget is on
        let screenIndex = getScreenIndex(for: rect)
        guard screenIndex < panels.count else { return }

        let panel = panels[screenIndex]
        let screenFrame = screenFrame(for: screenIndex)
        let localMidX = rect.midX - screenFrame.minX
        let localMidY = rect.midY - screenFrame.minY
        currentScreenIndex = screenIndex

        if panel.isKeyWindow, lastContentIdentifier == id {
            NotificationCenter.default.post(name: .willHideWindow, object: nil)
            let duration =
                Double(Constants.menuBarPopupAnimationDurationInMilliseconds)
                / 1000.0
            returnFocus()
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                panel.orderOut(nil)
                lastContentIdentifier = nil
            }
            return
        }

        let isContentChange =
            panel.isKeyWindow
            && (lastContentIdentifier != nil && lastContentIdentifier != id)
        lastContentIdentifier = id

        if let hidingPanel = panel as? HidingPanel {
            hidingPanel.hideTimer?.invalidate()
            hidingPanel.hideTimer = nil
        }

        if panel.isKeyWindow {
            NotificationCenter.default.post(
                name: .willChangeContent, object: nil)
            let baseDuration =
                Double(Constants.menuBarPopupAnimationDurationInMilliseconds)
                / 1000.0
            let duration = isContentChange ? baseDuration / 2 : baseDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                panel.contentView = FirstMouseHostingView(
                    rootView:
                        ZStack {
                            MenuBarPopupView {
                                content()
                            }
                            .position(x: localMidX, y: localMidY)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
                takeFocus()
            panel.makeKeyAndOrderFront(nil)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .willShowWindow, object: nil)
                }
            }
        } else {
            panel.contentView = FirstMouseHostingView(
                rootView:
                    ZStack {
                        MenuBarPopupView {
                            content()
                        }
                        .position(x: localMidX, y: localMidY)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
            takeFocus()
            panel.makeKeyAndOrderFront(nil)
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .willShowWindow, object: nil)
            }
        }
    }

    static func setup() {
        let monitorMode = ConfigManager.shared.config.monitors.mode
        let screens: [NSScreen]

        switch monitorMode {
        case .main:
            if let mainScreen = NSScreen.main {
                screens = [mainScreen]
            } else {
                return
            }
        case .all:
            screens = NSScreen.screens
        }

        // Remove excess panels if screens were reduced
        while panels.count > screens.count {
            panels.removeLast().close()
        }

        // Create panels for each screen
        for (index, screen) in screens.enumerated() {
            let panelFrame = screen.frame

            if index < panels.count {
                // Update existing panel
                panels[index].setFrame(panelFrame, display: true)
                panels[index].level = NSWindow.Level(
                    rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
                panels[index].orderOut(nil)
            } else {
                // Create new panel
                let newPanel = HidingPanel(
                    contentRect: panelFrame,
                    styleMask: [.nonactivatingPanel],
                    backing: .buffered,
                    defer: false
                )

                newPanel.level = NSWindow.Level(
                    rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
                newPanel.backgroundColor = .clear
                newPanel.hasShadow = false
                newPanel.isReleasedWhenClosed = false
                newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]

                panels.append(newPanel)
            }
        }

        lastContentIdentifier = nil
        currentScreenIndex = nil
    }

    private static func getScreenIndex(for rect: CGRect) -> Int {
        let monitorMode = ConfigManager.shared.config.monitors.mode

        switch monitorMode {
        case .main:
            return 0
        case .all:
            let screens = NSScreen.screens

            // Find which screen contains the rect (based on the midpoint)
            let midX = rect.midX
            let midY = rect.midY

            for (index, screen) in screens.enumerated() {
                let frame = screen.frame
                if midX >= frame.minX && midX <= frame.maxX &&
                   midY >= frame.minY && midY <= frame.maxY {
                    return index
                }
            }

            // Default to main screen (index 0) if not found
            return 0
        }
    }

    private static func screenFrame(for index: Int) -> CGRect {
        let monitorMode = ConfigManager.shared.config.monitors.mode

        switch monitorMode {
        case .main:
            return NSScreen.main?.frame ?? .zero
        case .all:
            guard index < NSScreen.screens.count else {
                return NSScreen.main?.frame ?? .zero
            }
            return NSScreen.screens[index].frame
        }
    }
}
