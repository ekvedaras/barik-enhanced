import SwiftUI

/// Top CPU/RAM consumers with a two-step kill control.
struct TopProcessSection: View {
    enum Metric: String, CaseIterable {
        case cpu = "CPU"
        case ram = "RAM"
    }

    let cpuProcesses: [TopProcess]
    let ramProcesses: [TopProcess]
    let onKill: (TopProcess) -> Void

    @State private var metric: Metric = .cpu
    @State private var killCandidate: Int32?

    private var displayedProcesses: [TopProcess] {
        metric == .cpu ? cpuProcesses : ramProcesses
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Top Processes")
                    .font(PopupStyle.titleFont)
                Spacer()
                Picker("", selection: $metric) {
                    ForEach(Metric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .labelsHidden()
                .frame(width: 96)
            }

            if displayedProcesses.isEmpty {
                Text("Sampling processes...")
                    .font(PopupStyle.detailFont)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(displayedProcesses) { process in
                        processRow(process)
                        if process.id != displayedProcesses.last?.id {
                            Divider().overlay(.white.opacity(0.06))
                        }
                    }
                }
            }

            Text("Press ✕ twice to send SIGTERM. Unsaved work in that app may be lost.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func processRow(_ process: TopProcess) -> some View {
        HStack(spacing: 7) {
            Text(String(process.id))
                .font(.system(size: 10).monospacedDigit())
                .foregroundStyle(.tertiary)
                .frame(width: 34, alignment: .trailing)

            Text(process.name)
                .font(PopupStyle.detailFont)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 4)

            Text(metric == .cpu
                 ? String(format: "%.1f%%", process.cpuPercent)
                 : process.memoryText)
                .font(PopupStyle.detailFont.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 62, alignment: .trailing)

            Button {
                confirmKill(process)
            } label: {
                Text(killCandidate == process.id ? "KILL?" : "✕")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 36, height: 16)
            }
            .buttonStyle(.plain)
            .foregroundStyle(killCandidate == process.id ? .red : .gray)
            .help("Send SIGTERM to \(process.name) (\(process.id))")
        }
        .padding(.vertical, 3)
    }

    private func confirmKill(_ process: TopProcess) {
        if killCandidate == process.id {
            onKill(process)
            killCandidate = nil
        } else {
            killCandidate = process.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if killCandidate == process.id {
                    killCandidate = nil
                }
            }
        }
    }
}
