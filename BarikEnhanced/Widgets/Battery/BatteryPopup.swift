import SwiftUI

struct BatteryPopup: View {
    @ObservedObject private var batteryManager = BatteryManager.shared
    @ObservedObject private var lowPowerMode = LowPowerMode.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Battery").font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(batteryManager.batteryLevel)%")
                    .font(.system(size: 13))
                    .foregroundStyle(batteryColor)
            }
            Text(powerSource)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label {
                        Text("Low Power Mode").font(.system(size: 13))
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
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                }
            }
            .popupTile()
        }
        .padding(PopupStyle.padding)
        .frame(width: 260)
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
                return .white
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
