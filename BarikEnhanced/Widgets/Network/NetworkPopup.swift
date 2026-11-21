import SwiftUI

/// Window displaying detailed network status information.
struct NetworkPopup: View {
    @ObservedObject private var viewModel = NetworkStatusViewModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: PopupStyle.sectionSpacing) {
            PopupHeader(title: "Network")

            if viewModel.wifiState != .notSupported {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        wifiIcon
                        Text(viewModel.ssid).font(PopupStyle.bodyFont)
                    }
                    if viewModel.ssid != "Not connected"
                        && viewModel.ssid != "No interface"
                    {
                        VStack(alignment: .leading, spacing: 2) {
                            detail("Signal", viewModel.wifiSignalStrength.rawValue)
                            detail("RSSI", "\(viewModel.rssi)")
                            detail("Noise", "\(viewModel.noise)")
                            detail("Channel", "\(viewModel.channel)")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .popupTile()
            }

            if viewModel.ethernetState != .notSupported {
                HStack(spacing: 10) {
                    ethernetIcon
                    Text("Ethernet").font(PopupStyle.bodyFont)
                    Spacer()
                    Text(viewModel.ethernetState.rawValue)
                        .font(PopupStyle.detailFont)
                        .foregroundStyle(.secondary)
                }
                .popupTile()
            }
        }
        .padding(PopupStyle.padding)
        .frame(width: PopupStyle.width)
    }

    private func detail(_ name: String, _ value: String) -> some View {
        HStack {
            Text(name).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit()
        }
        .font(PopupStyle.detailFont)
    }

    /// Chooses the Wi‑Fi icon based on the status and connection availability.
    private var wifiIcon: some View {
        if viewModel.ssid == "Not connected" {
            return Image(systemName: "wifi.slash")
                .padding(6)
                .background(Color.red.opacity(0.8))
                .clipShape(Circle())
                .foregroundStyle(.white)
        }
        switch viewModel.wifiState {
        case .connected:
            return Image(systemName: "wifi")
                .padding(6)
                .background(Color.blue.opacity(0.8))
                .clipShape(Circle())
                .foregroundStyle(.white)
        case .connecting:
            return Image(systemName: "wifi")
                .padding(6)
                .background(Color.yellow.opacity(0.8))
                .clipShape(Circle())
                .foregroundStyle(.white)
        case .connectedWithoutInternet:
            return Image(systemName: "wifi.exclamationmark")
                .padding(6)
                .background(Color.yellow.opacity(0.8))
                .clipShape(Circle())
                .foregroundStyle(.white)
        case .disconnected:
            return Image(systemName: "wifi.slash")
                .padding(6)
                .background(Color.gray.opacity(0.8))
                .clipShape(Circle())
                .foregroundStyle(.white)
        case .disabled:
            return Image(systemName: "wifi.slash")
                .padding(6)
                .background(Color.red.opacity(0.8))
                .clipShape(Circle())
                .foregroundStyle(.white)
        case .notSupported:
            return Image(systemName: "wifi.exclamationmark")
                .padding(6)
                .background(Color.gray.opacity(0.8))
                .clipShape(Circle())
                .foregroundStyle(.white)
        }
    }

    private var ethernetIcon: some View {
        switch viewModel.ethernetState {
        case .connected:
            return Image(systemName: "network")
                .padding(6)
                .background(Color.blue.opacity(0.8))
                .clipShape(Circle())
        case .connectedWithoutInternet:
            return Image(systemName: "network")
                .padding(6)
                .background(Color.yellow.opacity(0.8))
                .clipShape(Circle())
        case .connecting:
            return Image(systemName: "network.slash")
                .padding(6)
                .background(Color.yellow.opacity(0.8))
                .clipShape(Circle())
        case .disconnected:
            return Image(systemName: "network.slash")
                .padding(6)
                .background(Color.gray.opacity(0.8))
                .clipShape(Circle())
        case .disabled:
            return Image(systemName: "network.slash")
                .padding(6)
                .background(Color.red.opacity(0.8))
                .clipShape(Circle())
        case .notSupported:
            return Image(systemName: "questionmark.circle")
                .padding(6)
                .background(Color.gray.opacity(0.8))
                .clipShape(Circle())
        }
    }
}

struct NetworkPopup_Previews: PreviewProvider {
    static var previews: some View {
        NetworkPopup()
            .previewLayout(.sizeThatFits)
    }
}
