import SwiftUI

/// The look every popup shares, modelled on the macOS 26 Control Center and menu bar extras.
enum PopupStyle {
    /// Space between the bar and the top of a popup.
    static let gapBelowBar: CGFloat = 6
    /// Closest a popup gets to the screen's left or right edge.
    static let screenMargin: CGFloat = 8
    static let cornerRadius: CGFloat = 22
    /// Inset between a popup's edge and its content.
    static let padding: CGFloat = 14
    /// Inset of a menu-like popup, whose rows carry their own padding.
    static let menuInset: CGFloat = 6
    static let rowSpacing: CGFloat = 2
    static let rowCornerRadius: CGFloat = 10
    static let tileCornerRadius: CGFloat = 16

    static var surfaceShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
}

extension View {
    /// The popup's background: Liquid Glass on macOS 26, a dark material before.
    @ViewBuilder
    func popupSurface() -> some View {
        if #available(macOS 26, *) {
            GlassEffectContainer {
                self.glassEffect(.regular, in: PopupStyle.surfaceShape)
            }
        } else {
            self
                .background(.ultraThinMaterial, in: PopupStyle.surfaceShape)
                .overlay(PopupStyle.surfaceShape.strokeBorder(.white.opacity(0.12)))
        }
    }

    /// A menu row: full width, highlighted under the pointer like a native menu item.
    func popupRow(isInteractive: Bool = true) -> some View {
        modifier(PopupRowModifier(isInteractive: isInteractive))
    }

    /// A Control Center tile, for a row that holds a control.
    @ViewBuilder
    func popupTile() -> some View {
        let shape = RoundedRectangle(cornerRadius: PopupStyle.tileCornerRadius, style: .continuous)
        let tile = self.padding(.horizontal, 12).padding(.vertical, 10)
        if #available(macOS 26, *) {
            tile.glassEffect(.regular, in: shape)
        } else {
            tile.background(.white.opacity(0.1), in: shape)
        }
    }
}

private struct PopupRowModifier: ViewModifier {
    let isInteractive: Bool
    @State private var hovered = false

    func body(content: Content) -> some View {
        let highlighted = isInteractive && hovered
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: PopupStyle.rowCornerRadius, style: .continuous)
                    .fill(highlighted ? Color(nsColor: .controlAccentColor) : .clear)
            )
            .contentShape(Rectangle())
            .onHover { hovered = $0 }
    }
}
