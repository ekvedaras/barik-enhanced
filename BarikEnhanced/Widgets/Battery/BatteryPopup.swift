import SwiftUI

struct BatteryPopup: View {
    @ObservedObject private var batteryManager = BatteryManager.shared
    @ObservedObject private var lowPowerMode = LowPowerMode.shared

    var body: some View {
        VStack(alignment: .leading, spacing: PopupStyle.sectionSpacing) {
            VStack(alignment: .leading, spacing: 4) {
                PopupHeader(title: "Battery", value: "\(batteryManager.batteryLevel)%", valueColor: batteryColor)
                Text(powerSource)
                    .font(PopupStyle.detailFont)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label {
                        Text("Low Power Mode").font(PopupStyle.bodyFont)
                    } icon: {
                        Image(systemName: "battery.50percent")
                            .foregroundStyle(lowPowerMode.isOn ? .yellow : .white)
                    }
                    Spacer()
                    Toggle(
                        "Low Power Mode",
                        isOn: Binding(get: { lowPowerMode.isOn }, set: { lowPowerMode.set($0) })
                    )
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
                if let failure = lowPowerMode.failure {
                    Text(failure)
                        .font(PopupStyle.detailFont)
                        .foregroundStyle(.orange)
                }
            }
            .popupTile()
        }
        .padding(PopupStyle.padding)
        .frame(width: PopupStyle.width)
    }

    private var powerSource: String {
        let source = batteryManager.isPluggedIn ? "Power Adapter" : "Battery"
        return "Power Source: \(source)" + (batteryManager.isCharging ? " · Charging" : "")
    }

    private var batteryColor: Color {
        if batteryManager.isCharging {
            return .green
        } else {
            if batteryManager.batteryLevel <= 10 {
                return .red
            } else if batteryManager.batteryLevel <= 20 {
                return .yellow
            } else {
                return .primary
            }
        }
    }
}

struct BatteryPopup_Previews: PreviewProvider {
    static var previews: some View {
        BatteryPopup()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
