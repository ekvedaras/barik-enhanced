import Foundation

/// Runs widget scripts with `/bin/bash -c`. Foundation's `Process` starts each
/// child as the leader of its own process group, so killing the group also
/// kills what the script started (`hc events`, `sleep`, pipelines).
enum ScriptProcess {
    static func make(_ command: String, environment: [String: String]) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        process.environment = environment
        process.currentDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())
        process.standardInput = FileHandle.nullDevice
        return process
    }

    static func killGroup(of process: Process, signal: Int32 = SIGTERM) {
        let pid = process.processIdentifier
        if pid > 0 { kill(-pid, signal) }
    }

    /// Click actions: started and forgotten. Their output goes to the log.
    static func runDetached(_ command: String, environment: [String: String]) {
        do {
            try make(command, environment: environment).run()
        } catch {
            print("[script] could not run \(command): \(error)")
        }
    }

    struct PollResult {
        let status: Int32
        let output: Data
        let timedOut: Bool
    }

    /// Blocks until the script exits or `timeout` passes; then its whole
    /// process group is killed.
    static func poll(_ command: String, environment: [String: String],
                     timeout: TimeInterval = 10) -> PollResult? {
        let process = make(command, environment: environment)
        let stdout = Pipe()
        process.standardOutput = stdout
        do {
            try process.run()
        } catch {
            print("[script] could not run \(command): \(error)")
            return nil
        }

        let lock = NSLock()
        var timedOut = false
        let killer = DispatchWorkItem {
            lock.withLock { timedOut = true }
            killGroup(of: process, signal: SIGKILL)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: killer)
        // EOF arrives when every process holding the pipe has exited, so a
        // background child that outlives the script runs into the timeout.
        let output = stdout.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        killer.cancel()

        return PollResult(
            status: process.terminationStatus, output: output,
            timedOut: lock.withLock { timedOut })
    }
}

/// Keeps one stream script running: every stdout line goes to `onLine`. When
/// the script exits it is restarted after 1 s, doubling to 60 s; a run that
/// lasted a minute resets the delay.
final class ScriptStream {
    private let name: String
    private let settings: ScriptWidgetSettings
    private let onLine: (Data) -> Void
    private let lock = NSLock()
    private let wake = DispatchSemaphore(value: 0)
    private var stopped = false
    private var process: Process?

    init(name: String, settings: ScriptWidgetSettings, onLine: @escaping (Data) -> Void) {
        self.name = name
        self.settings = settings
        self.onLine = onLine
    }

    func start() {
        let thread = Thread { [self] in loop() }
        thread.name = "script.\(name)"
        thread.start()
    }

    func stop() {
        let process = lock.withLock {
            stopped = true
            return self.process
        }
        if let process { ScriptProcess.killGroup(of: process) }
        wake.signal()
    }

    private func loop() {
        var delay: TimeInterval = 1
        while !lock.withLock({ stopped }) {
            let startedAt = Date()
            runOnce()
            if lock.withLock({ stopped }) { return }

            if Date().timeIntervalSince(startedAt) >= 60 { delay = 1 }
            print("[script.\(name)] stream exited, restarting in \(Int(delay)) s")
            _ = wake.wait(timeout: .now() + delay)
            delay = min(delay * 2, 60)
        }
    }

    private func runOnce() {
        let process = ScriptProcess.make(settings.command, environment: settings.environment)
        let stdout = Pipe()
        process.standardOutput = stdout
        let started: Bool = lock.withLock {
            guard !stopped else { return false }
            do {
                try process.run()
            } catch {
                print("[script.\(name)] could not run \(settings.command): \(error)")
                return false
            }
            self.process = process
            return true
        }
        guard started else { return }

        let reader = stdout.fileHandleForReading
        var buffer = Data()
        while true {
            let chunk = reader.availableData
            if chunk.isEmpty { break }
            buffer.append(chunk)
            while let newline = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                let line = buffer[buffer.startIndex..<newline]
                buffer.removeSubrange(buffer.startIndex...newline)
                if !line.allSatisfy({ $0 == UInt8(ascii: " ") || $0 == UInt8(ascii: "\r") }) {
                    onLine(Data(line))
                }
            }
        }
        // The script may have exited while a child it started keeps running.
        ScriptProcess.killGroup(of: process)
        process.waitUntilExit()
        lock.withLock { self.process = nil }
        if process.terminationStatus != 0 {
            print("[script.\(name)] stream exited with status \(process.terminationStatus)")
        }
    }
}
