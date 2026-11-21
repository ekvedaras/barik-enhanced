import SwiftUI

struct VolumePopup: View {
    @ObservedObject private var audioVisualManager = AudioVisualManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: PopupStyle.sectionSpacing) {
            PopupHeader(title: "Sound", value: volumeStatusText)

            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)
                Slider(
                    value: Binding(
                        get: { audioVisualManager.volumeLevel },
                        set: { audioVisualManager.setVolume(level: $0) }
                    ),
                    in: 0...1
                )
                .controlSize(.small)
                .disabled(audioVisualManager.isMuted)
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.secondary)
            }
            .font(PopupStyle.detailFont)
            .popupTile()

            HStack {
                Label {
                    Text("Mute").font(PopupStyle.bodyFont)
                } icon: {
                    Image(systemName: audioVisualManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundStyle(audioVisualManager.isMuted ? .red : .primary)
                }
                Spacer()
                Toggle(
                    "Mute",
                    isOn: Binding(
                        get: { audioVisualManager.isMuted },
                        set: { _ in audioVisualManager.toggleMute() }
                    )
                )
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .popupTile()
        }
        .padding(PopupStyle.padding)
        .frame(width: PopupStyle.width)
    }

    private var volumeStatusText: String {
        audioVisualManager.isMuted ? "Muted" : "\(Int(audioVisualManager.volumeLevel * 100))%"
    }
}

struct VolumePopup_Previews: PreviewProvider {
    static var previews: some View {
        VolumePopup()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
