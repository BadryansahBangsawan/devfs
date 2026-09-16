# DevFS

Sync a remote directory over SSH/rsync from the menu bar. Key-based auth only — never a password prompt.

Menu extra for macOS 14+. It lives in the menu bar and does not show a Dock icon.

## Features

- Mounts: name, `user@host`, port, remote path, local folder name.
- `ssh`/`scp`/`rsync` with `BatchMode=yes` (no passwords, no askpass).
- Sync now, Pause/Resume, Open in Finder, Delete.
- Local file changes can trigger sync via FSEvents.
- `Permission denied` maps to **SSH key auth failed. Add a key for this host.**

## Requirements

- macOS 14 Sonoma or later
- Swift 5.9 or later
- `/usr/bin/ssh` and `/usr/bin/rsync` (or scp fallback)
- An SSH key already accepted by the remote host

## Install

Homebrew (macOS 14+):

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew install --cask devfs
```

Opens as a menu extra (no Dock icon). The cask is ad-hoc signed. If Gatekeeper blocks it:

```bash
xattr -cr /Applications/DevFS.app
```

Build from source:

```bash
git clone https://github.com/BadryansahBangsawan/devfs.git
cd devfs
bash package-app.sh
open dist/DevFS.app
```

Enable **Open at Login** from Settings if you want it after reboot.

## Usage

- Settings → **Add mount** (name, user@host, port, remote path).
- Local files live under `~/Library/Application Support/DevFS/<localName>/`.
- **Sync now** pulls down. Resolve/SSH/rsync errors show as a red banner.

## Permissions

- No File Provider extension. This is process-based sync, not a Finder mount plugin.

Denied permissions must not crash the app. You should see a banner and a button to open System Settings.

## Privacy

SSH only, BatchMode. No passwords stored. Mounts: `~/Library/Application Support/DevFS/mounts.json`.

Bundle ID: `engineer.badry.devfs`.

## Development

```bash
swift build
swift build -c release --product DevFS
```

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`.

## Auth

Password auth is intentionally unsupported. Add a key for the host (`ssh-copy-id` or equivalent) before Sync now.


## License

[MIT](LICENSE)
