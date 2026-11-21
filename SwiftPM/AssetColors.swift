import AppKit
import SwiftUI

// Xcode generates these symbols from Resources/Assets.xcassets/Colors. SwiftPM has no actool,
// so the SwiftPM build defines them here. Keep in sync with the colorsets.
private func assetColor(light: (Double, Double), dark: (Double, Double)) -> Color {
    Color(NSColor(name: nil) { appearance in
        let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let (white, alpha) = isDark ? dark : light
        return NSColor(white: white, alpha: alpha)
    })
}

extension Color {
    static let active = assetColor(light: (1, 0.8), dark: (1, 0.4))
    static let foreground = assetColor(light: (0, 0.9), dark: (1, 0.9))
    static let foregroundOutside = assetColor(light: (1, 0.9), dark: (1, 0.9))
    static let foregroundOutsideInvert = assetColor(light: (0, 0.8), dark: (0, 0.8))
    static let foregroundShadow = assetColor(light: (0, 0), dark: (0, 0.5))
    static let foregroundShadowOutside = assetColor(light: (0, 0.3), dark: (0, 0.5))
    static let icon = assetColor(light: (1, 0.9), dark: (1, 0.9))
    static let iconShadow = assetColor(light: (0, 0.1), dark: (0, 0.1))
    static let noActive = assetColor(light: (1, 0.4), dark: (1, 0.1))
    static let selected = assetColor(light: (0, 0.1), dark: (1, 0.4))
    static let shadow = assetColor(light: (0, 0.1), dark: (0, 0.5))
}

extension ShapeStyle where Self == Color {
    static var active: Color { .active }
    static var foreground: Color { .foreground }
    static var foregroundOutside: Color { .foregroundOutside }
    static var foregroundOutsideInvert: Color { .foregroundOutsideInvert }
    static var foregroundShadow: Color { .foregroundShadow }
    static var foregroundShadowOutside: Color { .foregroundShadowOutside }
    static var icon: Color { .icon }
    static var iconShadow: Color { .iconShadow }
    static var noActive: Color { .noActive }
    static var selected: Color { .selected }
    static var shadow: Color { .shadow }
}
