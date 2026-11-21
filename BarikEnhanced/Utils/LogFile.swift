import Foundation

/// Copies everything the app prints (stdout and stderr) to ~/Library/Logs/Barik/barik.log,
/// so errors are readable when the app runs from Finder or at login.
enum LogFile {
    static let url = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/Barik/barik.log")
    private static let maxBytesBeforeRotation = 5_000_000
    private static var pipe: Pipe?

    static func start() {
        let fileManager = FileManager.default
        try? fileManager.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let size = try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int,
            size > maxBytesBeforeRotation
        {
            let previous = url.appendingPathExtension("1")
            try? fileManager.removeItem(at: previous)
            try? fileManager.moveItem(at: url, to: previous)
        }

        let logFd = open(url.path, O_WRONLY | O_CREAT | O_APPEND, 0o644)
        guard logFd != -1 else { return }
        let originalStdout = dup(STDOUT_FILENO)

        let pipe = Pipe()
        LogFile.pipe = pipe
        setvbuf(stdout, nil, _IOLBF, 0)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        let timestamp = ISO8601DateFormatter()
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            data.withUnsafeBytes { _ = write(originalStdout, $0.baseAddress, data.count) }

            let prefix = timestamp.string(from: Date()) + " "
            let text = String(decoding: data, as: UTF8.self)
            let stamped = text.split(separator: "\n", omittingEmptySubsequences: false)
                .map { $0.isEmpty ? "" : prefix + $0 }
                .joined(separator: "\n")
            _ = stamped.withCString { write(logFd, $0, strlen($0)) }
        }
    }
}
