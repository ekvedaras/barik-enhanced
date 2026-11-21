import AppKit
import SwiftUI

/// `notch`: empty space as wide as the camera notch of the screen the bar is on,
/// zero wide on screens without one.
struct NotchWidget: NSViewRepresentable {
    func makeNSView(context: Context) -> NotchSpacerView { NotchSpacerView() }
    func updateNSView(_ nsView: NotchSpacerView, context: Context) {}
}

/// An AppKit view, because only the hosting window knows which screen this bar is on
/// (panels are reused across screens when displays change).
final class NotchSpacerView: NSView {
    override var intrinsicContentSize: NSSize {
        NSSize(width: Self.notchWidth(of: window?.screen), height: NSView.noIntrinsicMetric)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        let center = NotificationCenter.default
        center.removeObserver(self)
        if let window {
            center.addObserver(
                self, selector: #selector(screenMayHaveChanged),
                name: NSWindow.didChangeScreenNotification, object: window)
            center.addObserver(
                self, selector: #selector(screenMayHaveChanged),
                name: NSApplication.didChangeScreenParametersNotification, object: nil)
        }
        invalidateIntrinsicContentSize()
    }

    @objc private func screenMayHaveChanged() {
        invalidateIntrinsicContentSize()
    }

    static func notchWidth(of screen: NSScreen?) -> CGFloat {
        guard let screen,
            let left = screen.auxiliaryTopLeftArea,
            let right = screen.auxiliaryTopRightArea
        else { return 0 }
        return max(0, screen.frame.width - left.width - right.width)
    }
}
