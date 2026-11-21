import SwiftUI

struct SystemMonitorPopup: View {
    @ObservedObject private var systemMonitor = SystemMonitorManager.shared
    @State private var liveUpdatesActive = false

    private let willHideWindow = NotificationCenter.default.publisher(
        for: .willHideWindow)
    private let willChangeContent = NotificationCenter.default.publisher(
        for: .willChangeContent)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PopupStyle.sectionSpacing) {
                HStack {
                    Text("System Monitor").font(PopupStyle.titleFont)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(.green).frame(width: 5, height: 5)
                        Text("Live").font(PopupStyle.detailFont).foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    PopupHeader(title: "CPU", value: "\(Int(systemMonitor.cpuLoad))%", valueColor: cpuColor)
                    CPUChart(data: systemMonitor.cpuHistory, color: cpuColor)
                        .frame(height: 40)
                    HStack(spacing: 16) {
                        breakdown("User", systemMonitor.userLoad)
                        breakdown("System", systemMonitor.systemLoad)
                        breakdown("Idle", systemMonitor.idleLoad)
                        Spacer()
                    }
                }
                .popupTile()

                VStack(alignment: .leading, spacing: 8) {
                    PopupHeader(
                        title: "Memory",
                        value: "\(String(format: "%.1f", usedRAM)) GB · \(Int(systemMonitor.ramUsage))%",
                        valueColor: ramColor)
                    RAMChart(data: systemMonitor.ramHistory, color: ramColor)
                        .frame(height: 40)
                    VStack(spacing: 4) {
                        MemoryBar(label: "Active", value: systemMonitor.activeRAM, total: systemMonitor.totalRAM, color: .blue)
                        MemoryBar(label: "Wired", value: systemMonitor.wiredRAM, total: systemMonitor.totalRAM, color: .orange)
                        MemoryBar(label: "Compressed", value: systemMonitor.compressedRAM, total: systemMonitor.totalRAM, color: .purple)
                    }
                }
                .popupTile()

                VStack(alignment: .leading, spacing: 8) {
                    PopupHeader(title: "Network")
                    ioChannel(
                        label: "Upload",
                        speed: systemMonitor.uploadSpeed,
                        history: systemMonitor.uploadHistory,
                        color: .green)
                    ioChannel(
                        label: "Download",
                        speed: systemMonitor.downloadSpeed,
                        history: systemMonitor.downloadHistory,
                        color: .cyan)
                }
                .popupTile()

                TopProcessSection(
                    cpuProcesses: systemMonitor.topCPUProcesses,
                    ramProcesses: systemMonitor.topRAMProcesses,
                    onKill: { systemMonitor.kill(process: $0) })
                    .popupTile()
            }
            .padding(PopupStyle.padding)
        }
        .frame(width: 320)
        .onAppear { startLiveUpdates() }
        .onDisappear { stopLiveUpdates() }
        .onReceive(willHideWindow) { _ in stopLiveUpdates() }
        .onReceive(willChangeContent) { _ in stopLiveUpdates() }
    }

    private func breakdown(_ name: String, _ load: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name).foregroundStyle(.secondary)
            Text("\(Int(load))%").monospacedDigit()
        }
        .font(PopupStyle.detailFont)
    }

    /// Panels are only ordered out, so `onDisappear` is not guaranteed when the
    /// popup closes. The window notifications cover that path; the flag keeps
    /// the client count balanced when both fire.
    private func startLiveUpdates() {
        guard !liveUpdatesActive else { return }
        liveUpdatesActive = true
        systemMonitor.beginLiveUpdates()
    }

    private func stopLiveUpdates() {
        guard liveUpdatesActive else { return }
        liveUpdatesActive = false
        systemMonitor.endLiveUpdates()
    }

    private var usedRAM: Double {
        systemMonitor.activeRAM + systemMonitor.wiredRAM + systemMonitor.compressedRAM
    }

    private func ioChannel(
        label: String,
        speed: Double,
        history: [Double],
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).foregroundStyle(.secondary)
                Spacer()
                Text(formatSpeed(speed)).monospacedDigit().foregroundStyle(color)
            }
            .font(PopupStyle.detailFont)
            NetworkTrace(values: history, color: color)
                .frame(height: 22)
        }
    }

    private var cpuColor: Color {
        let cpu = Int(systemMonitor.cpuLoad)
        if cpu >= 90 {
            return .red
        } else if cpu >= 70 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private var ramColor: Color {
        let ram = Int(systemMonitor.ramUsage)
        if ram >= 90 {
            return .red
        } else if ram >= 70 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func formatSpeed(_ speed: Double) -> String {
        if speed >= 1.0 {
            return String(format: "%.2f MB/s", speed)
        } else if speed >= 0.001 {
            return String(format: "%.0f KB/s", speed * 1024)
        } else {
            return "0 B/s"
        }
    }
    
}

// MARK: - Chart Views

struct CPUChart: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(data.count - 1)
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height - (CGFloat(value) / 100.0) * height
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            
            // Add fill area
            Path { path in
                guard !data.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(data.count - 1)
                
                path.move(to: CGPoint(x: 0, y: height))
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height - (CGFloat(value) / 100.0) * height
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: geometry.size.width, y: height))
                path.closeSubpath()
            }
            .fill(LinearGradient(colors: [color.opacity(0.3), color.opacity(0.1)], startPoint: .top, endPoint: .bottom))
        }
    }
}

struct RAMChart: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        CPUChart(data: data, color: color)
    }
}

struct NetworkTrace: View {
    let values: [Double]
    let color: Color

    var body: some View {
        Canvas { context, size in
            guard values.count > 1 else { return }
            let peak = max(values.max() ?? 0, 0.05)
            var path = Path()
            for (index, value) in values.enumerated() {
                let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
                let y = size.height * (1 - CGFloat(min(max(value / peak, 0), 1)))
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            var fill = path
            fill.addLine(to: CGPoint(x: size.width, y: size.height))
            fill.addLine(to: CGPoint(x: 0, y: size.height))
            fill.closeSubpath()
            context.fill(
                fill,
                with: .linearGradient(
                    Gradient(colors: [color.opacity(0.22), color.opacity(0.01)]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)))

            context.stroke(
                path,
                with: .color(color),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

            if let last = values.last {
                let y = size.height * (1 - CGFloat(min(max(last / peak, 0), 1)))
                context.fill(
                    Path(ellipseIn: CGRect(x: size.width - 3, y: y - 2, width: 4, height: 4)),
                    with: .color(color))
            }
        }
    }
}

struct MemoryBar: View {
    let label: String
    let value: Double
    let total: Double
    let color: Color
    
    private var percentage: Double {
        total > 0 ? (value / total) * 100 : 0
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(PopupStyle.detailFont)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.gray.opacity(0.2))
                    Capsule()
                        .fill(color)
                        .frame(width: max(2, geometry.size.width * percentage / 100))
                        .animation(.easeInOut(duration: 0.3), value: percentage)
                }
            }
            .frame(height: 6)
            
            Text("\(String(format: "%.1f", value)) GB")
                .font(PopupStyle.detailFont)
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)
        }
    }
}



struct SystemMonitorPopup_Previews: PreviewProvider {
    static var previews: some View {
        SystemMonitorPopup()
            .previewLayout(.sizeThatFits)
    }
} 