import Foundation

enum SmartctlError: LocalizedError {
    case notFound
    case failed(status: Int32, output: String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "smartctl was not found. Install smartmontools and ensure smartctl is in /opt/homebrew/bin, /opt/homebrew/sbin, /usr/local/bin, /usr/local/sbin, or PATH."
        case let .failed(status, output):
            return "smartctl -a disk0 failed with status \(status).\n\(output)"
        }
    }
}

enum SmartctlRunner {
    static func run() async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            guard let executable = findSmartctl() else { throw SmartctlError.notFound }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = ["-a", "disk0"]

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            try process.run()
            process.waitUntilExit()

            let stdoutText = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let stderrText = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let combined = [stdoutText, stderrText].filter { !$0.isEmpty }.joined(separator: "\n")

            guard process.terminationStatus == 0 || !stdoutText.isEmpty else {
                throw SmartctlError.failed(status: process.terminationStatus, output: combined)
            }

            return stdoutText
        }.value
    }

    private static func findSmartctl() -> String? {
        let fileManager = FileManager.default
        let candidates = [
            "/opt/homebrew/bin/smartctl",
            "/opt/homebrew/sbin/smartctl",
            "/usr/local/bin/smartctl",
            "/usr/local/sbin/smartctl"
        ]
        if let found = candidates.first(where: { fileManager.isExecutableFile(atPath: $0) }) {
            return found
        }

        let pathEntries = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .map(String.init)
        return pathEntries
            .map { URL(fileURLWithPath: $0).appendingPathComponent("smartctl").path }
            .first(where: { fileManager.isExecutableFile(atPath: $0) })
    }
}
