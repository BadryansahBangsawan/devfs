import Foundation

enum ProcessRunner {
    static func run(executable: String, arguments: [String]) throws -> (status: Int32, stdout: String, stderr: String) {
        guard FileManager.default.isExecutableFile(atPath: executable) else {
            throw NSError(
                domain: DevFSPaths.bundleId,
                code: 127,
                userInfo: [NSLocalizedDescriptionKey: "Missing executable: \(executable)"]
            )
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        try process.run()
        process.waitUntilExit()
        let stdout = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (process.terminationStatus, stdout, stderr)
    }

    static func sshOptions(port: Int) -> [String] {
        [
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=8",
            "-p", "\(port)",
            "-o", "ControlMaster=auto",
            "-o", "ControlPath=\(DevFSPaths.sshControlPath)",
            "-o", "ControlPersist=60"
        ]
    }

    static func sshRemoteShell(port: Int) -> String {
        let control = DevFSPaths.sshControlPath
        return "/usr/bin/ssh -o BatchMode=yes -o ConnectTimeout=8 -p \(port) -o ControlMaster=auto -o ControlPath='\(control)' -o ControlPersist=60"
    }

    static func mapFailure(stderr: String, status: Int32) -> String {
        if stderr.localizedCaseInsensitiveContains("Permission denied") {
            return "SSH key auth failed. Add a key for this host."
        }
        let trimmed = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Process exited \(status)"
        }
        return trimmed
    }
}

enum SyncEngine {
    static let rsyncPath = "/usr/bin/rsync"
    static let scpPath = "/usr/bin/scp"

    static func sync(mount: Mount, direction: SyncDirection) throws -> SyncResult {
        try DevFSPaths.ensureSupportDirectory()
        let localRoot = URL(fileURLWithPath: mount.localRootPath, isDirectory: true)
        try FileManager.default.createDirectory(at: localRoot, withIntermediateDirectories: true)

        let remote = "\(mount.userHost):\(mount.remotePath)"
        let local = localRoot.path

        if FileManager.default.isExecutableFile(atPath: rsyncPath) {
            let result = try rsync(remote: remote, local: local, direction: direction, port: mount.port)
            if result.status == 127 {
                return try scp(remote: remote, local: local, direction: direction, port: mount.port)
            }
            if result.status != 0 {
                let message = ProcessRunner.mapFailure(stderr: result.stderr, status: result.status)
                return SyncResult(ok: false, message: message, direction: direction)
            }
            let msg = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            return SyncResult(ok: true, message: msg.isEmpty ? "ok" : msg, direction: direction)
        }
        return try scp(remote: remote, local: local, direction: direction, port: mount.port)
    }

    private static func rsync(remote: String, local: String, direction: SyncDirection, port: Int) throws -> (status: Int32, stdout: String, stderr: String) {
        let shell = ProcessRunner.sshRemoteShell(port: port)
        let src: String
        let dst: String
        switch direction {
        case .down:
            src = remote.hasSuffix("/") ? remote : remote + "/"
            dst = local.hasSuffix("/") ? local : local + "/"
        case .up:
            src = local.hasSuffix("/") ? local : local + "/"
            dst = remote.hasSuffix("/") ? remote : remote + "/"
        }
        return try ProcessRunner.run(
            executable: rsyncPath,
            arguments: ["-az", "-e", shell, src, dst]
        )
    }

    private static func scp(remote: String, local: String, direction: SyncDirection, port: Int) throws -> SyncResult {
        var args = ["-r", "-P", "\(port)"]
        args.append(contentsOf: [
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=8",
            "-o", "ControlMaster=auto",
            "-o", "ControlPath=\(DevFSPaths.sshControlPath)",
            "-o", "ControlPersist=60"
        ])
        switch direction {
        case .down:
            let src = remote.hasSuffix("/") ? remote + "." : remote + "/."
            args.append(contentsOf: [src, local])
        case .up:
            let dst = remote.hasSuffix("/") ? remote : remote + "/"
            args.append(contentsOf: [local + "/.", dst])
        }
        let result = try ProcessRunner.run(executable: scpPath, arguments: args)
        if result.status != 0 {
            return SyncResult(
                ok: false,
                message: ProcessRunner.mapFailure(stderr: result.stderr, status: result.status),
                direction: direction
            )
        }
        let msg = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        return SyncResult(ok: true, message: msg.isEmpty ? "ok" : msg, direction: direction)
    }
}

enum SyncLog {
    static func append(name: String, direction: SyncDirection, ok: Bool, message: String) throws {
        try DevFSPaths.ensureSupportDirectory()
        let ts = ISO8601DateFormatter().string(from: Date())
        let status = ok ? "ok" : "error"
        let clean = message.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
        let line = "\(ts) \(name) \(direction.rawValue) \(status) \(clean)\n"
        let url = DevFSPaths.logURL
        if FileManager.default.fileExists(atPath: url.path) {
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            if let data = line.data(using: .utf8) {
                try handle.write(contentsOf: data)
            }
            try handle.close()
        } else {
            try line.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
