import SwiftUI

struct SpacesWidget: View {
    @ObservedObject var viewModel = SpacesViewModel.shared

    @ObservedObject var configManager = ConfigManager.shared
    var foregroundHeight: CGFloat { configManager.config.experimental.foreground.resolveHeight() }

    var body: some View {
        // Short of room (the bar's left section is full), pills drop their window titles before anything overlaps.
        ViewThatFits(in: .horizontal) {
            pills(withTitles: true)
            pills(withTitles: false)
        }
        .experimentalConfiguration(horizontalPadding: 5, cornerRadius: 10)
        .animation(.smooth(duration: 0.3), value: viewModel.spaces)
        .foregroundStyle(Color.foreground)
        .environmentObject(viewModel)
    }

    private func pills(withTitles: Bool) -> some View {
        HStack(spacing: foregroundHeight < 30 ? 0 : BarStyle.pillSpacing) {
            ForEach(viewModel.spaces) { space in
                SpaceView(space: space, withTitles: withTitles)
            }
        }
    }
}

/// This view shows a space with its windows.
private struct SpaceView: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @EnvironmentObject var viewModel: SpacesViewModel

    var config: ConfigData { configProvider.config }
    var spaceConfig: ConfigData { config["space"]?.dictionaryValue ?? [:] }

    @ObservedObject var configManager = ConfigManager.shared
    var foregroundHeight: CGFloat { configManager.config.experimental.foreground.resolveHeight() }

    var showKey: Bool { spaceConfig["show-key"]?.boolValue ?? true }

    let space: AnySpace
    let withTitles: Bool

    @State var isHovered = false

    var body: some View {
        let isFocused = space.windows.contains { $0.isFocused } || space.isFocused
        let badgeModels = ScriptWidgets.shared.models(inSpace: space.id)
        HStack(spacing: 0) {
            Spacer().frame(width: BarStyle.pillPadding)
            if showKey {
                Text(space.id)
                    .font(BarStyle.font)
                    .frame(minWidth: 10)
                    .fixedSize(horizontal: true, vertical: false)
                Spacer().frame(width: 5)
            }
            ForEach(badgeModels, id: \.name) { model in
                SpaceBadges(model: model)
            }
            HStack(spacing: 2) {
                ForEach(space.windows) { window in
                    WindowView(window: window, space: space, withTitle: withTitles)
                }
            }
            Spacer().frame(width: BarStyle.pillPadding)
        }
        .frame(height: BarStyle.pillHeight(foregroundHeight: foregroundHeight))
        .background {
            ForEach(badgeModels, id: \.name) { model in
                SpaceBadgePulse(model: model)
            }
        }
        .background(
            foregroundHeight < 30 ?
            (isFocused
             ? Color.noActive
             : Color.clear) :
                (isFocused
                 ? Color.active
                 : isHovered ? Color.noActive : Color.noActive)
        )
        .clipShape(RoundedRectangle(
            cornerRadius: foregroundHeight < 30 ? 0 : BarStyle.pillRadius(foregroundHeight: foregroundHeight),
            style: .continuous))
        .shadow(color: .shadow, radius: foregroundHeight < 30 ? 0 : 2)
        .transition(.blurReplace)
        .onTapGesture {
            viewModel.switchToSpace(space, needWindowFocus: true)
        }
        .animation(.smooth, value: isHovered)
        .onHover { value in
            isHovered = value
        }
    }
}

/// Items of a `script.<name>` widget configured with `space = "<id>"`.
private struct SpaceBadges: View {
    @ObservedObject var model: ScriptWidgetModel

    var body: some View {
        ForEach(model.items) { item in
            HStack(spacing: 3) {
                if let icon = item.icon {
                    ScriptIconView(icon: icon, size: BarStyle.iconSize, weight: .regular)
                        .foregroundStyle(item.color?.style ?? AnyShapeStyle(.primary))
                }
                if let label = item.label {
                    Text(label)
                        .font(BarStyle.font)
                        .fixedSize()
                        .foregroundStyle(item.color?.labelStyle ?? AnyShapeStyle(.primary))
                }
            }
            .help(item.tooltip ?? "")
            .padding(.trailing, 5)
            .transition(.blurReplace)
        }
    }
}

/// A badge with `animation = "pulse"` pulses the whole pill in its colour,
/// like SketchyBar's blinking workspace.
private struct SpaceBadgePulse: View {
    @ObservedObject var model: ScriptWidgetModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let item = model.items.first(where: { $0.animation == .pulse }) {
            let fill = Rectangle().fill(item.color?.style ?? AnyShapeStyle(Color.accentColor))
            if reduceMotion {
                fill.opacity(0.4)
            } else {
                fill.phaseAnimator([0.0, 0.85]) { view, opacity in
                    view.opacity(opacity)
                } animation: { _ in .easeInOut(duration: 1) }
            }
        }
    }
}

/// This view shows a window and its icon.
private struct WindowView: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @EnvironmentObject var viewModel: SpacesViewModel

    var config: ConfigData { configProvider.config }
    var windowConfig: ConfigData { config["window"]?.dictionaryValue ?? [:] }
    var titleConfig: ConfigData {
        windowConfig["title"]?.dictionaryValue ?? [:]
    }

    var showTitle: Bool { withTitle && windowConfig["show-title"]?.boolValue ?? true }
    var maxLength: Int { titleConfig["max-length"]?.intValue ?? 50 }
    var alwaysDisplayAppTitleFor: [String] { titleConfig["always-display-app-name-for"]?.arrayValue?.filter({ $0.stringValue != nil }).map { $0.stringValue! } ?? [] }

    let window: AnyWindow
    let space: AnySpace
    let withTitle: Bool

    @State var isHovered = false

    var body: some View {
        let titleMaxLength = maxLength
        let effectiveMaxLength = space.windows.count > 3 ? min(titleMaxLength, 20) : titleMaxLength
        let size: CGFloat = 16
        let sameAppCount = space.windows.filter { $0.appName == window.appName }
            .count
        let title = sameAppCount > 1 && !alwaysDisplayAppTitleFor.contains { $0 == window.appName } ? window.title : (window.appName ?? "")
        let spaceIsFocused = space.windows.contains { $0.isFocused }
        HStack(spacing: 4) {
            ZStack {
                if let icon = window.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: size, height: size)
                        .shadow(
                            color: .iconShadow,
                            radius: 2
                        )
                } else {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .frame(width: size, height: size)
                }
            }
            .opacity(spaceIsFocused && !window.isFocused ? 0.5 : 1)
            .transition(.blurReplace)

            if window.isFocused, !title.isEmpty, showTitle {
                Text(
                    title.count > effectiveMaxLength
                        ? String(title.prefix(effectiveMaxLength)) + "..."
                        : title
                )
                .font(BarStyle.font)
                .fixedSize(horizontal: true, vertical: false)
                .transition(.blurReplace)
            }
        }
        .padding(.all, 2)
        .background(isHovered || (!showTitle && window.isFocused) ? .selected : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .animation(.smooth, value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.switchToSpace(space)
            usleep(100_000)
            viewModel.switchToWindow(window)
        }
        .onHover { value in
            isHovered = value
        }
    }
}
