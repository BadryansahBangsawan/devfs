import AppKit
import Foundation

@MainActor
final class MountStore: ObservableObject {
    @Published var mounts: [Mount] = []
    @Published var pausedIds: Set<UUID> = []
    @Published var lastSync: [UUID: Date] = [:]
    @Published var lastError: [UUID: String] = [:]
    @Published var lastDirection: [UUID: String] = [:]
    @Published var syncingIds: Set<UUID> = []
    @Published var banner: String?
    @Published var loadError: String?
    @Published var isSyncing = false

    private var watchers: [UUID: FSEventWatcher] = [:]
    private var ignoreUntil: [UUID: Date] = [:]
    private var downTimer: Timer?
    private let syncQueue = DispatchQueue(label: "engineer.badry.devfs.sync", qos: .utility)

    func load() {
        loadError = nil
        do {
            try DevFSPaths.ensureSupportDirectory()
            if FileManager.default.fileExists(atPath: DevFSPaths.mountsURL.path) {
                do {
                    let data = try Data(contentsOf: DevFSPaths.mountsURL)
                    mounts = try JSONDecoder().decode([Mount].self, from: data)
                } catch {
                    mounts = []
                    loadError = error.localizedDescription
                }
            } else {
                mounts = []
            }
        } catch {
            loadError = error.localizedDescription
        }
        let raw = UserDefaults.standard.stringArray(forKey: DevFSPaths.pausedIdsKey) ?? []
        pausedIds = Set(raw.compactMap(UUID.init(uuidString:)))
        rebuildWatchers()
        startTimer()
    }

    func persist() {
        do {
            try DevFSPaths.ensureSupportDirectory()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(mounts)
            try data.write(to: DevFSPaths.mountsURL, options: .atomic)
            let paused = pausedIds.map(\.uuidString)
            UserDefaults.standard.set(paused, forKey: DevFSPaths.pausedIdsKey)
            banner = nil
        } catch {
            banner = error.localizedDescription
        }
    }

    func addMount(name: String, userHost: String, port: Int, remotePath: String, localName: String?) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let host = userHost.trimmingCharacters(in: .whitespacesAndNewlines)
        let remote = remotePath.trimmingCharacters(in: .whitespacesAndNewlines)
        let local = sanitizeLocalName(localName?.isEmpty == false ? localName! : trimmedName)
        guard !trimmedName.isEmpty, !host.isEmpty, !remote.isEmpty else {
            banner = "Name, user@host, and remote path are required."
            return
        }
        let mount = Mount(name: trimmedName, userHost: host, port: port == 0 ? 22 : port, remotePath: remote, localName: local)
        do {
            try FileManager.default.createDirectory(
                at: DevFSPaths.localRoot(localName: mount.localName),
                withIntermediateDirectories: true
            )
        } catch {
            banner = error.localizedDescription
            return
        }
        mounts.append(mount)
        persist()
        rebuildWatchers()
        syncNow(mount, direction: .down)
    }

    func deleteMount(_ mount: Mount) {
        watchers[mount.id]?.stop()
        watchers[mount.id] = nil
        mounts.removeAll { $0.id == mount.id }
        pausedIds.remove(mount.id)
        lastSync.removeValue(forKey: mount.id)
        lastError.removeValue(forKey: mount.id)
        lastDirection.removeValue(forKey: mount.id)
        persist()
        rebuildWatchers()
    }

    func togglePause(_ mount: Mount) {
        if pausedIds.contains(mount.id) {
            pausedIds.remove(mount.id)
        } else {
            pausedIds.insert(mount.id)
        }
        persist()
        rebuildWatchers()
    }

    func isPaused(_ mount: Mount) -> Bool {
        pausedIds.contains(mount.id)
    }

    func openFinder(_ mount: Mount) {
        let url = DevFSPaths.localRoot(localName: mount.localName)
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            NSWorkspace.shared.open(url)
        } catch {
            banner = error.localizedDescription
        }
    }

    func syncNow(_ mount: Mount, direction: SyncDirection = .down) {
        runSync(mount, direction: direction, ignorePause: true)
    }

    private func startTimer() {
        downTimer?.invalidate()
        downTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickDown()
            }
        }
        if let downTimer {
            RunLoop.main.add(downTimer, forMode: .common)
        }
    }

    private func tickDown() {
        for mount in mounts where !pausedIds.contains(mount.id) {
            runSync(mount, direction: .down, ignorePause: false)
        }
    }

    private func rebuildWatchers() {
        for watcher in watchers.values { watcher.stop() }
        watchers.removeAll()
        for mount in mounts where !pausedIds.contains(mount.id) {
            let id = mount.id
            let local = mount.localRootPath
            do {
                try FileManager.default.createDirectory(
                    at: URL(fileURLWithPath: local, isDirectory: true),
                    withIntermediateDirectories: true
                )
            } catch {
                banner = error.localizedDescription
                continue
            }
            let watcher = FSEventWatcher(path: local, debounce: 1.0) { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    guard let current = self.mounts.first(where: { $0.id == id }) else { return }
                    if let until = self.ignoreUntil[id], until > Date() { return }
                    if self.pausedIds.contains(id) { return }
                    self.runSync(current, direction: .up, ignorePause: false)
                }
            }
            watchers[id] = watcher
        }
    }

    private func runSync(_ mount: Mount, direction: SyncDirection, ignorePause: Bool) {
        if !ignorePause && pausedIds.contains(mount.id) { return }
        if syncingIds.contains(mount.id) { return }
        syncingIds.insert(mount.id)
        isSyncing = !syncingIds.isEmpty
        if direction == .down {
            ignoreUntil[mount.id] = Date().addingTimeInterval(1.5)
        }
        let snapshot = mount
        syncQueue.async {
            let result: SyncResult
            do {
                result = try SyncEngine.sync(mount: snapshot, direction: direction)
            } catch {
                result = SyncResult(ok: false, message: error.localizedDescription, direction: direction)
            }
            do {
                try SyncLog.append(name: snapshot.name, direction: direction, ok: result.ok, message: result.message)
            } catch {
                Task { @MainActor in
                    self.banner = error.localizedDescription
                }
            }
            Task { @MainActor in
                self.syncingIds.remove(snapshot.id)
                self.isSyncing = !self.syncingIds.isEmpty
                self.lastSync[snapshot.id] = Date()
                self.lastDirection[snapshot.id] = direction.rawValue
                if result.ok {
                    self.lastError[snapshot.id] = nil
                    if self.banner?.contains(snapshot.name) == true {
                        self.banner = nil
                    }
                } else {
                    self.lastError[snapshot.id] = result.message
                    self.banner = result.message
                }
            }
        }
    }


    private func sanitizeLocalName(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
        return cleaned.isEmpty ? UUID().uuidString : cleaned
    }
}
