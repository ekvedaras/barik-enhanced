import SwiftUI

/// Script items in the bar's left section that do not fit are hidden and
/// counted in a `+N` pill; its popup lists them with their clicks.
enum ScriptOverflow {
    struct Entry: Equatable {
        let name: String
        let itemID: String
        let frame: CGRect

        var key: String { "\(name)/\(itemID)" }
    }

    /// Global frames of the script items drawn below the view that reads it.
    struct FramesKey: PreferenceKey {
        static let defaultValue: [Entry] = []
        static func reduce(value: inout [Entry], nextValue: () -> [Entry]) {
            value.append(contentsOf: nextValue())
        }
    }

    static let badgeReserve: CGFloat = 48

    /// Items that end past `visibleMaxX`, or past the room left for the badge once anything overflows.
    static func hidden(_ entries: [Entry], visibleMaxX: CGFloat) -> [Entry] {
        let sorted = entries.sorted { $0.frame.minX < $1.frame.minX }
        guard sorted.contains(where: { $0.frame.maxX > visibleMaxX }) else { return [] }
        return sorted.filter { $0.frame.maxX > visibleMaxX - badgeReserve }
    }
}

private struct OverflowHiddenKey: EnvironmentKey {
    static let defaultValue: Set<String> = []
}

extension EnvironmentValues {
    /// `ScriptOverflow.Entry.key`s of the items the `+N` pill stands for.
    var scriptOverflowHidden: Set<String> {
        get { self[OverflowHiddenKey.self] }
        set { self[OverflowHiddenKey.self] = newValue }
    }
}

/// Counts and lists only labelled items: a bare mark (a group's leading icon) hides without a row.
struct ScriptOverflowBadge: View {
    let hidden: [ScriptOverflow.Entry]

    private var listed: [ScriptOverflow.Entry] {
        hidden.filter { entry in
            ScriptWidgets.shared.model(named: entry.name).items.contains { $0.id == entry.itemID && $0.label != nil }
        }
    }

    @ObservedObject private var configManager = ConfigManager.shared
    @State private var rect: CGRect = .zero

    private var pillHeight: CGFloat {
        min(26, max(16, configManager.config.experimental.foreground.resolveHeight() - 8))
    }

    var body: some View {
        Text("+\(listed.count)")
            .font(.system(size: 12, weight: .semibold))
            .fixedSize()
            .padding(.horizontal, 8)
            .frame(height: pillHeight)
            .background(RoundedRectangle(cornerRadius: pillHeight * 0.3, style: .continuous).fill(Color.noActive))
            .shadow(color: .shadow, radius: 2)
            .foregroundStyle(Color.foreground)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear { rect = geometry.frame(in: .global) }
                        .onChange(of: geometry.frame(in: .global)) { _, newRect in rect = newRect }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                let listed = listed
                MenuBarPopup.show(rect: rect, id: "script-overflow") {
                    ScriptOverflowPopup(hidden: listed)
                }
            }
    }
}

/// One row per hidden item: its icon, label and colour; a click runs the item's `click`.
private struct ScriptOverflowPopup: View {
    let hidden: [ScriptOverflow.Entry]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(hidden, id: \.key) { entry in
                let model = ScriptWidgets.shared.model(named: entry.name)
                if let item = model.items.first(where: { $0.id == entry.itemID }) {
                    ScriptPopupRowView(
                        row: ScriptPopupRow(icon: item.icon, label: item.label, color: item.color, click: item.click),
                        model: model)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(25)
        .frame(minWidth: 220, alignment: .leading)
        .fixedSize()
    }
}
