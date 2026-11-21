import AppKit
import SwiftUI

/// `script.<name>`: draws what the script printed last. Hidden while it has no items.
struct ScriptWidget: View {
    @ObservedObject private var model: ScriptWidgetModel

    init(name: String) {
        model = ScriptWidgets.shared.model(named: name)
    }

    var body: some View {
        if !model.items.isEmpty, ScriptWidgets.space(of: model.name) == nil {
            HStack(spacing: 4) {
                ForEach(runs(of: model.items), id: \.first!.id) { run in
                    HStack(spacing: 1) {
                        ForEach(Array(run.enumerated()), id: \.element.id) { index, item in
                            ScriptItemView(
                                item: item, model: model,
                                joinedLeading: index > 0, joinedTrailing: index < run.count - 1)
                        }
                    }
                }
            }
            .experimentalConfiguration(horizontalPadding: 5, cornerRadius: 10)
            .animation(.smooth(duration: 0.3), value: model.items)
        }
    }

    /// Consecutive items linked by `joined` draw as one segmented pill.
    private func runs(of items: [ScriptItem]) -> [[ScriptItem]] {
        var runs: [[ScriptItem]] = []
        var previousJoined = false
        for item in items {
            if previousJoined, !runs.isEmpty {
                runs[runs.count - 1].append(item)
            } else {
                runs.append([item])
            }
            previousJoined = item.joined
        }
        return runs
    }
}

private struct ScriptItemView: View {
    let item: ScriptItem
    let model: ScriptWidgetModel
    let joinedLeading: Bool
    let joinedTrailing: Bool

    @ObservedObject private var configManager = ConfigManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scriptOverflowHidden) private var overflowHidden
    @State private var rect: CGRect = .zero

    private var overflowEntry: ScriptOverflow.Entry {
        ScriptOverflow.Entry(name: model.name, itemID: item.id, frame: rect)
    }
    private var isOverflowing: Bool { overflowHidden.contains(overflowEntry.key) }

    private var foregroundHeight: CGFloat { configManager.config.experimental.foreground.resolveHeight() }
    private var pillHeight: CGFloat { min(26, max(16, foregroundHeight - 8)) }
    private var animation: ScriptItem.Animation { reduceMotion ? .none : item.animation }

    private var shape: UnevenRoundedRectangle {
        let radius = pillHeight * 0.3
        let inner: CGFloat = 2
        return UnevenRoundedRectangle(
            topLeadingRadius: joinedLeading ? inner : radius,
            bottomLeadingRadius: joinedLeading ? inner : radius,
            bottomTrailingRadius: joinedTrailing ? inner : radius,
            topTrailingRadius: joinedTrailing ? inner : radius,
            style: .continuous)
    }

    var body: some View {
        content
            .modifier(Pulse(active: animation == .pulse))
            .padding(.horizontal, item.style == .pill ? 8 : 2)
            .frame(height: pillHeight)
            .background {
                if item.style == .pill {
                    shape.fill(Color.noActive)
                }
            }
            .overlay {
                if item.outline {
                    shape.strokeBorder(item.color?.style ?? AnyShapeStyle(Color.foreground), lineWidth: 1)
                }
            }
            .shadow(color: item.style == .pill ? .shadow : .clear, radius: 2)
            .modifier(Shake(active: animation == .shake))
            .foregroundStyle(item.style == .pill ? AnyShapeStyle(Color.foreground) : AnyShapeStyle(.primary))
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear { rect = geometry.frame(in: .global) }
                        .onChange(of: geometry.frame(in: .global)) { _, newRect in rect = newRect }
                        .preference(
                            key: ScriptOverflow.FramesKey.self,
                            value: [ScriptOverflow.Entry(
                                name: model.name, itemID: item.id, frame: geometry.frame(in: .global))])
                }
            )
            .background {
                if let rightClickAction, !isOverflowing {
                    RightClickCatcher(action: rightClickAction)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { leftClick() }
            .help(item.tooltip ?? "")
            .opacity(isOverflowing ? 0 : 1)
            .allowsHitTesting(!isOverflowing)
            .transition(.blurReplace)
    }

    private var content: some View {
        HStack(spacing: 4) {
            if let icon = item.icon {
                ScriptIconView(icon: icon, size: 13)
                    .modifier(Spin(active: animation == .spin))
            }
            if let label = item.label {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .fixedSize()
            }
        }
        .foregroundStyle(item.color?.style ?? AnyShapeStyle(.primary))
    }

    private var popupID: String { "\(ScriptWidgets.idPrefix)\(model.name).\(item.id)" }

    private func leftClick() {
        if let click = item.click {
            model.run(click)
        } else if !item.popup.isEmpty {
            showPopup()
        }
    }

    /// Nil lets the right click through to the bar's own context menu.
    private var rightClickAction: (() -> Void)? {
        if let rightClick = item.rightClick {
            return { [model] in model.run(rightClick) }
        }
        if item.click != nil, !item.popup.isEmpty {
            return { showPopup() }
        }
        return nil
    }

    private func showPopup() {
        let itemID = item.id
        MenuBarPopup.show(rect: rect, id: popupID) { [model] in
            ScriptPopupView(model: model, itemID: itemID)
        }
    }
}

/// Rows of an item's `popup`, kept live while the script keeps printing.
struct ScriptPopupView: View {
    @ObservedObject var model: ScriptWidgetModel
    let itemID: String

    var body: some View {
        let item = model.items.first { $0.id == itemID }
        VStack(alignment: .leading, spacing: 12) {
            if let item, item.icon != nil || item.label != nil {
                HStack(spacing: 10) {
                    if let icon = item.icon {
                        ScriptIconView(icon: icon, size: 18)
                            .foregroundStyle(item.color?.style ?? AnyShapeStyle(.white))
                    }
                    if let label = item.label {
                        Text(label).font(.headline)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array((item?.popup ?? []).enumerated()), id: \.offset) { _, row in
                    ScriptPopupRowView(row: row, model: model)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(25)
        .frame(minWidth: 220, alignment: .leading)
        .fixedSize()
    }
}

struct ScriptPopupRowView: View {
    let row: ScriptPopupRow
    let model: ScriptWidgetModel
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 10) {
            if let icon = row.icon {
                ScriptIconView(icon: icon, size: 14)
                    .frame(width: 18)
                    .foregroundStyle(row.color?.style ?? AnyShapeStyle(.white))
            }
            if let label = row.label {
                Text(label)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(row.click == nil ? 0 : hovered ? 0.2 : 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .onTapGesture {
            if let click = row.click { model.run(click) }
        }
        .animation(.smooth(duration: 0.15), value: hovered)
    }
}

struct ScriptIconView: View {
    let icon: ScriptIcon
    let size: CGFloat

    var body: some View {
        switch icon {
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: size, weight: .semibold))
        case .text(let text):
            Text(text)
                .font(.system(size: size, weight: .semibold))
                .fixedSize()
        case .app(let bundleID):
            image(Self.appIcon(bundleID))
        case .file(let path):
            image(Self.fileImage(path))
        }
    }

    @ViewBuilder
    private func image(_ image: NSImage?) -> some View {
        if let image {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size + 4, height: size + 4)
        } else {
            Image(systemName: "questionmark.square.dashed")
                .font(.system(size: size, weight: .semibold))
        }
    }

    private static func appIcon(_ bundleID: String) -> NSImage? {
        let key = "app:\(bundleID)" as NSString
        if let cached = ImageCache.shared.object(forKey: key) { return cached }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        let image = NSWorkspace.shared.icon(forFile: url.path)
        ImageCache.shared.setObject(image, forKey: key)
        return image
    }

    /// Keyed by modification time, so a script can rewrite the same file.
    private static func fileImage(_ path: String) -> NSImage? {
        let modified = (try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date)
        guard let modified else { return nil }
        let key = "file:\(path)@\(modified.timeIntervalSince1970)" as NSString
        if let cached = ImageCache.shared.object(forKey: key) { return cached }
        guard let image = NSImage(contentsOfFile: path) else { return nil }
        ImageCache.shared.setObject(image, forKey: key)
        return image
    }
}

// MARK: - Animations

private struct Pulse: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.phaseAnimator([1.0, 0.4]) { view, opacity in
                view.opacity(opacity)
            } animation: { _ in .easeInOut(duration: 1) }
        } else {
            content
        }
    }
}

/// A short wiggle, then a rest, repeated.
private struct Shake: ViewModifier {
    let active: Bool
    private static let offsets: [CGFloat] = [0, -2.5, 2.5, -2, 2, -1, 0]

    func body(content: Content) -> some View {
        if active {
            content.phaseAnimator(Array(Self.offsets.indices)) { view, phase in
                view.offset(x: Self.offsets[phase])
            } animation: { phase in
                phase == 0 ? .linear(duration: 0.05).delay(1.6) : .linear(duration: 0.06)
            }
        } else {
            content
        }
    }
}

private struct Spin: ViewModifier {
    let active: Bool
    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        if active {
            content
                .rotationEffect(.degrees(angle))
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        angle = 360
                    }
                }
        } else {
            content
        }
    }
}
