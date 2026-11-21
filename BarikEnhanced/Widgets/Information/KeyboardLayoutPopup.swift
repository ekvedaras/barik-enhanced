import SwiftUI

struct KeyboardLayoutPopup: View {
    @ObservedObject private var keyboardLayoutManager = KeyboardLayoutManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: PopupStyle.rowSpacing) {
            PopupHeader(title: "Keyboard Layout")
                .popupRow(isInteractive: false)

            if keyboardLayoutManager.availableInputSources.isEmpty {
                Text("No additional layouts available")
                    .font(PopupStyle.bodyFont)
                    .foregroundStyle(.secondary)
                    .popupRow(isInteractive: false)
            } else {
                ForEach(keyboardLayoutManager.availableInputSources, id: \.self) { source in
                    PopupMenuItem(
                        icon: source.contains(keyboardLayoutManager.currentInputSource) ? "checkmark" : nil,
                        title: source
                    ) {
                        keyboardLayoutManager.switchToInputSource(name: source)
                    }
                }

                PopupMenuDivider()

                PopupMenuItem(icon: "arrow.right.circle", title: "Switch to Next Layout") {
                    keyboardLayoutManager.switchToNextInputSource()
                }
            }
        }
        .padding(PopupStyle.menuInset)
        .frame(width: 240)
    }
}
