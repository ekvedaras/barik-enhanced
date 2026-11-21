import AppKit
import SwiftUI

/// The bar has its own context menu, so a SwiftUI gesture never sees right
/// clicks. This view catches them over its own bounds, before the menu does.
struct RightClickCatcher: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> CatcherView {
        let view = CatcherView()
        view.action = action
        return view
    }

    func updateNSView(_ view: CatcherView, context: Context) {
        view.action = action
    }

    final class CatcherView: NSView {
        var action: (() -> Void)?
        private var monitor: Any?

        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
                guard let self, let action = self.action, event.window === self.window,
                    self.bounds.contains(self.convert(event.locationInWindow, from: nil))
                else { return event }
                action()
                return nil
            }
        }
    }
}
