import Foundation

/// `Barik trigger <event>` and `Barik reload`: the app binary run as a CLI
/// posts a distributed notification to the running bar and exits.
enum BarikPushChannel {
    static let trigger = Notification.Name("com.ekvedaras.barik.trigger")
    static let reload = Notification.Name("com.ekvedaras.barik.reload")
    /// Posted by the bar itself after the Mac wakes from sleep.
    static let systemWokeEvent = "system_woke"

    /// Returns only when the arguments are not a CLI command.
    static func handleCommandLine(_ arguments: [String] = CommandLine.arguments) {
        guard arguments.count > 1 else { return }
        let center = DistributedNotificationCenter.default()
        switch arguments[1] {
        case "trigger":
            guard arguments.count == 3, !arguments[2].isEmpty else {
                FileHandle.standardError.write(Data("usage: barik trigger <event>\n".utf8))
                exit(64)
            }
            center.postNotificationName(trigger, object: arguments[2], userInfo: nil, deliverImmediately: true)
            exit(0)
        case "reload":
            center.postNotificationName(reload, object: nil, userInfo: nil, deliverImmediately: true)
            exit(0)
        default:
            return
        }
    }
}
