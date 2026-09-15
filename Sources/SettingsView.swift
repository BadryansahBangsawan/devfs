import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: MountStore
    @State private var loginError: String?
    @State private var name = ""
    @State private var userHost = ""
    @State private var port = "22"
    @State private var remotePath = ""
    @State private var localName = ""

    private var loginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    var body: some View {
        Form {
            Section("Add mount") {
                TextField("Name", text: $name)
                TextField("user@host", text: $userHost)
                    .textContentType(.username)
                TextField("Port", text: $port)
                TextField("Remote path", text: $remotePath)
                TextField("Local folder name (optional)", text: $localName)
                Button("Save mount") {
                    let parsedPort = Int(port).flatMap { $0 > 0 ? $0 : nil } ?? 22
                    store.addMount(
                        name: name,
                        userHost: userHost,
                        port: parsedPort,
                        remotePath: remotePath,
                        localName: localName.isEmpty ? nil : localName
                    )
                    if store.banner == nil {
                        name = ""
                        userHost = ""
                        port = "22"
                        remotePath = ""
                        localName = ""
                    }
                }
            }

            Section("Mounts") {
                if store.mounts.isEmpty {
                    Text("Add an SSH mount (key-based auth)")
                } else {
                    ForEach(store.mounts) { mount in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(mount.name)
                                Text("\(mount.userHost) \(mount.remotePath)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Delete") { store.deleteMount(mount) }
                        }
                    }
                }
            }

            Section("Login") {
                Toggle("Open at Login", isOn: Binding(
                    get: { loginEnabled },
                    set: { setLogin($0) }
                ))
                if let loginError {
                    Label(loginError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 520)
        .onAppear { store.load() }
    }

    private func setLogin(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginError = nil
        } catch {
            loginError = error.localizedDescription
        }
    }
}
