import SwiftUI

struct MenuBarPopupView<Content: View>: View {
    let content: Content
    let isPreview: Bool

    @ObservedObject var configManager = ConfigManager.shared

    @State private var animationValue: Double = 0.01
    @State private var isShowAnimation = false
    @State private var isHideAnimation = false

    private let willShowWindow = NotificationCenter.default.publisher(
        for: .willShowWindow)
    private let willHideWindow = NotificationCenter.default.publisher(
        for: .willHideWindow)
    private let willChangeContent = NotificationCenter.default.publisher(
        for: .willChangeContent)

    init(isPreview: Bool = false, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isPreview = isPreview
        if isPreview {
            _animationValue = State(initialValue: 1.0)
        }
    }

    var body: some View {
        let isBottom = configManager.config.experimental.position == .bottom

        content
            .popupSurface()
            .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
            .blur(radius: (1.0 - (0.1 + 0.9 * animationValue)) * 20)
            .scaleEffect(
                x: 0.2 + 0.8 * animationValue, y: animationValue,
                anchor: isBottom ? .bottom : .top)
            .opacity(animationValue)
            .transaction { transaction in
                if isHideAnimation {
                    transaction.animation = .linear(duration: 0.1)
                }
            }
            .onReceive(willShowWindow) { _ in
                isShowAnimation = true
                withAnimation(
                    .smooth(
                        duration: Double(
                            Constants
                                .menuBarPopupAnimationDurationInMilliseconds
                        ) / 1000.0, extraBounce: 0.3)
                ) {
                    animationValue = 1.0
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now()
                        + .milliseconds(
                            Constants
                                .menuBarPopupAnimationDurationInMilliseconds
                        )
                ) {
                    isShowAnimation = false
                }
            }
            .onReceive(willHideWindow) { _ in
                isHideAnimation = true
                withAnimation(
                    .interactiveSpring(
                        duration: Double(
                            Constants
                                .menuBarPopupAnimationDurationInMilliseconds
                        ) / 1000.0)
                ) {
                    animationValue = 0.01
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now()
                        + .milliseconds(
                            Constants
                                .menuBarPopupAnimationDurationInMilliseconds
                        )
                ) {
                    isHideAnimation = false
                }
            }
            .onReceive(willChangeContent) { _ in
                isHideAnimation = true
                withAnimation(
                    .spring(
                        duration: Double(
                            Constants
                                .menuBarPopupAnimationDurationInMilliseconds
                        ) / 1000.0)
                ) {
                    animationValue = 0.01
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now()
                        + .milliseconds(
                            Constants
                                .menuBarPopupAnimationDurationInMilliseconds
                        )
                ) {
                    isHideAnimation = false
                }
            }
            .foregroundStyle(.white)
            .preferredColorScheme(.dark)
    }
}

extension Notification.Name {
    static let willShowWindow = Notification.Name("willShowWindow")
    static let willHideWindow = Notification.Name("willHideWindow")
    static let willChangeContent = Notification.Name("willChangeContent")
}
