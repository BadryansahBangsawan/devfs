import Foundation

enum DevFSPaths {
    static let bundleId = "engineer.badry.devfs"
    static let displayName = "DevFS"
    static let defaultsPrefix = bundleId + "."
    static let pausedIdsKey = defaultsPrefix + "pausedIds"

    static var supportDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/\(displayName)", isDirectory: true)
    }

    static var mountsURL: URL { supportDirectory.appendingPathComponent("mounts.json") }
    static var logURL: URL { supportDirectory.appendingPathComponent("log.txt") }
    static var sshControlPath: String {
        supportDirectory.appendingPathComponent(".ssh-%C").path
    }

    static func localRoot(localName: String) -> URL {
        supportDirectory.appendingPathComponent(localName, isDirectory: true)
    }

    static func ensureSupportDirectory() throws {
        try FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
    }
}

struct Mount: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var userHost: String
    var port: Int
    var remotePath: String
    var localName: String

    enum CodingKeys: String, CodingKey {
        case id, name, userHost, port, remotePath, localName
    }

    init(id: UUID = UUID(), name: String, userHost: String, port: Int = 22, remotePath: String, localName: String) {
        self.id = id
        self.name = name
        self.userHost = userHost
        self.port = port == 0 ? 22 : port
        self.remotePath = remotePath
        self.localName = localName
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        userHost = try c.decode(String.self, forKey: .userHost)
        port = try c.decodeIfPresent(Int.self, forKey: .port) ?? 22
        remotePath = try c.decode(String.self, forKey: .remotePath)
        localName = try c.decode(String.self, forKey: .localName)
    }

    var localRootPath: String {
        DevFSPaths.localRoot(localName: localName).path
    }
}

enum SyncDirection: String {
    case up
    case down
}

struct SyncResult {
    var ok: Bool
    var message: String
    var direction: SyncDirection
}
