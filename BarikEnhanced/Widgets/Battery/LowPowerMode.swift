import Foundation

/// macOS Low Power Mode. Turning it on or off needs root, so it runs
/// `sudo -n pmset`, which works only with a sudoers rule for exactly those commands:
///
///     <user> ALL = (root) NOPASSWD: /usr/bin/pmset -a lowpowermode 0, /usr/bin/pmset -a lowpowermode 1
final class LowPowerMode: ObservableObject {
    static let shared = LowPowerMode()

    @Published private(set) var isOn = ProcessInfo.processInfo.isLowPowerModeEnabled
    /// Why the last change failed; nil after a change that worked.
    @Published private(set) var failure: String?

    private init() {
        NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.isOn = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    func set(_ on: Bool) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = ["-n", "/usr/bin/pmset", "-a", "lowpowermode", on ? "1" : "0"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.terminationHandler = { [weak self] finished in
            DispatchQueue.main.async {
                self?.failure = finished.terminationStatus == 0 ? nil : "Needs the pmset sudoers rule"
                self?.isOn = ProcessInfo.processInfo.isLowPowerModeEnabled
            }
        }
        do {
            try process.run()
        } catch {
            failure = "Could not run sudo: \(error.localizedDescription)"
        }
    }
}
