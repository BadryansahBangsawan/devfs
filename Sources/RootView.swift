import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: MountStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: FunTheme.sectionSpacing) {
            if let loadError = store.loadError {
                Label(loadError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let banner = store.banner {
                Label(banner, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if store.mounts.isEmpty {
                ExtraEmptyState(
                    title: "No mounts",
                    detail: "Add an SSH mount. Key-based auth only.",
                    actionTitle: "Open Settings",
                    action: { openSettings() }
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: FunTheme.innerSpacing) {
                        ForEach(store.mounts) { mount in
                            MountRow(mount: mount)
                        }
                    }
                }
                .frame(maxHeight: 320)
            }

            ExtraSettingsFooter()
        }
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.mounts.count)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.banner)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.isSyncing)
        .funPanel()
        .onAppear { store.load() }
    }
}

struct MountRow: View {
    @EnvironmentObject private var store: MountStore
    let mount: Mount

    private var lastSyncText: String {
        if let date = store.lastSync[mount.id] {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let dir = store.lastDirection[mount.id] ?? ""
            return "Last sync \(formatter.string(from: date)) \(dir)"
        }
        return "Last sync — never"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(mount.name)
                    .font(.system(.headline))
                if store.syncingIds.contains(mount.id) {
                    ProgressView()
                        .controlSize(.small)
                }
                Spacer()
                if store.isPaused(mount) {
                    Text("Paused")
                        .font(.system(.caption))
                        .foregroundStyle(.secondary)
                }
            }
            Text("\(mount.userHost):\(mount.port) \(mount.remotePath)")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text(lastSyncText)
                .font(.system(.caption))
                .foregroundStyle(.secondary)
            if let err = store.lastError[mount.id] {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.system(.caption))
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button("Open in Finder") { store.openFinder(mount) }
                Button("Sync now") { store.syncNow(mount, direction: .down) }
                    .disabled(store.syncingIds.contains(mount.id))
                Button(store.isPaused(mount) ? "Resume" : "Pause") {
                    store.togglePause(mount)
                }
                Button("Delete") { store.deleteMount(mount) }
            }
            .controlSize(.small)
        }
        .extraRowSurface()
    }
}
