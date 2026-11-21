import SwiftUI

/// One look for every item on the bar, modelled on the macOS menu bar:
/// regular system text at menu bar size, pills of one height and radius.
enum BarStyle {
    /// `NSFont.menuBarFont(ofSize: 0)`: the system font at 13 pt, regular weight.
    static let font = Font.system(size: 13)
    static let iconSize: CGFloat = 13
    static let pillPadding: CGFloat = 8
    /// Between pills of one widget; widgets are `experimental.foreground.spacing` apart.
    static let pillSpacing: CGFloat = 4

    static func pillHeight(foregroundHeight: CGFloat) -> CGFloat {
        min(26, max(16, foregroundHeight - 8))
    }

    static func pillRadius(foregroundHeight: CGFloat) -> CGFloat {
        pillHeight(foregroundHeight: foregroundHeight) * 0.3
    }
}

/// A thin, short, low-contrast divider between groups, like the macOS menu bar uses.
struct BarSeparator: View {
    var body: some View {
        Capsule()
            .fill(.primary.opacity(0.25))
            .frame(width: 1, height: 14)
            .padding(.horizontal, 2)
    }
}
