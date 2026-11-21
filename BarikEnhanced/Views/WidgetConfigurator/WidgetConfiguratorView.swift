import SwiftUI
import UniformTypeIdentifiers

struct WidgetConfiguratorView: View {
    @ObservedObject var configManager = ConfigManager.shared
    @State private var activeWidgetIDs: [String] = []
    @State private var isDropTargeted = false
    @State private var applyWorkItem: DispatchWorkItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Configure Widgets")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)

            Divider().background(.white.opacity(0.2))

            HStack(spacing: 0) {
                // LEFT: Available widgets
                VStack(alignment: .leading, spacing: 12) {
                    Text("Available Widgets")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(allWidgets) { widget in
                                AvailableWidgetCard(widget: widget) {
                                    withAnimation(.spring(duration: 0.3)) {
                                        activeWidgetIDs.append(widget.id)
                                    }
                                }
                                .onDrag {
                                    NSItemProvider(object: widget.id as NSString)
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)

                Divider().background(.white.opacity(0.2))

                // RIGHT: Active widgets (reorderable)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Active Widgets")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text("\(activeWidgetIDs.count) widgets")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    List {
                        ForEach(Array(activeWidgetIDs.enumerated()), id: \.offset) { entry in
                            let widgetID: String = entry.element
                            ActiveWidgetRow(
                                widget: allWidgets.first(where: { $0.id == widgetID }),
                                widgetID: widgetID,
                                onRemove: {
                                    withAnimation(.spring(duration: 0.3)) {
                                        // Find current index at removal time, not capture time
                                        if let currentIndex = activeWidgetIDs.firstIndex(of: widgetID) {
                                            activeWidgetIDs.remove(at: currentIndex)
                                        }
                                    }
                                }
                            )
                        }
                        .onMove { source, destination in
                            activeWidgetIDs.move(fromOffsets: source, toOffset: destination)
                        }
                        .onInsert(of: [.text]) { index, providers in
                            guard let provider = providers.first else { return }
                            provider.loadObject(ofClass: NSString.self) { string, _ in
                                if let widgetID = string as? String {
                                    DispatchQueue.main.async {
                                        withAnimation(.spring(duration: 0.3)) {
                                            activeWidgetIDs.insert(widgetID, at: min(index, activeWidgetIDs.count))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.blue.opacity(isDropTargeted ? 0.5 : 0), lineWidth: 2)
                    )
                }
                .padding(20)
                .frame(maxWidth: .infinity)
            }

            Divider().background(.white.opacity(0.2))

            // Bottom bar
            HStack {
                Button("Reset to Default") {
                    withAnimation {
                        activeWidgetIDs = [
                            "default.spaces", "spacer", "default.nowplaying",
                            "default.cpuram", "default.networkactivity",
                            "divider", "default.network", "default.battery",
                            "default.time",
                        ]
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundStyle(.white.opacity(0.5))

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
            .padding(20)
        }
        .frame(width: 650, height: 500)
        .background(.black)
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .onAppear {
            activeWidgetIDs = configManager.config.rootToml.widgets.displayed.map { $0.id }
        }
        .onChange(of: activeWidgetIDs) { _, _ in
            // Debounce: wait 300ms before writing to disk
            applyWorkItem?.cancel()
            let work = DispatchWorkItem { applyChanges() }
            applyWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
        }
    }

    private func applyChanges() {
        do {
            try configManager.saveDisplayedWidgets(activeWidgetIDs)
            // Force immediate reload — don't wait for file watcher
            configManager.reloadConfig()
        } catch {
            print("Error saving widget config: \(error)")
        }
    }
}

// MARK: - Subviews

struct AvailableWidgetCard: View {
    let widget: WidgetDefinition
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            VStack(spacing: 8) {
                Image(systemName: widget.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.1)))

                Text(widget.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActiveWidgetRow: View {
    let widget: WidgetDefinition?
    let widgetID: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.3))

            Image(systemName: widget?.icon ?? "questionmark.circle")
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(widget?.name ?? widgetID)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                Text(widget?.description ?? "")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}
