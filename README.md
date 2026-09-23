<div align="center">

# DevFS

**Sync a remote directory over SSH. `BatchMode=yes` only — rsync, then scp. Never a password prompt.**

Menu extra for macOS 14+. Lives on the **right** of the menu bar. No Dock icon.

<br/>

[![Build](https://github.com/BadryansahBangsawan/devfs/actions/workflows/ci.yml/badge.svg)](https://github.com/BadryansahBangsawan/devfs/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/BadryansahBangsawan/devfs?style=flat-square)](https://github.com/BadryansahBangsawan/devfs/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/BadryansahBangsawan/devfs/releases/latest)

<br/>

| | |
|---|---|
| Product | `DevFS` |
| Bundle ID | `engineer.badry.devfs` |
| Cask | `devfs` |
| Status item | SF Symbol `externaldrive.connected.to.line.below` |
| Panel | opaque ~360×420 pt |

</div>

---

## What you get

| Piece | Behavior |
|---|---|
| **Mount** | name, `user@host`, port (default 22), remote path, local folder name. |
| **Auth** | `/usr/bin/ssh` `-o BatchMode=yes`. `Permission denied` → **SSH key auth failed. Add a key for this host.** |
| **Sync** | **Sync now** pulls down (`rsync -az`, scp fallback). Local FSEvents push up. A 10s timer also pulls down. |
| **Pause** | **Pause** / **Resume**. Paused ids: UserDefaults `engineer.badry.devfs.pausedIds`. |
| **Local** | Trees under `~/Library/Application Support/DevFS/<localName>/`. **Open in Finder**. |
| **Log** | `~/Library/Application Support/DevFS/log.txt`. |
| **Empty** | **No mounts** → **Open Settings**. Settings hint: *Add an SSH mount (key-based auth)*. |
| **Login** | Open at Login from Settings (`SMAppService`). |

---

## Download

| File | Use |
|---|---|
| **`DevFS.app.zip`** | Homebrew cask / unzip, drag **DevFS** onto **Applications** |

**[Releases](https://github.com/BadryansahBangsawan/devfs/releases/latest)**

---

## Install

### Homebrew

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew trust BadryansahBangsawan/mac-menu-apps
brew install --cask devfs
```

`brew trust` is required on Homebrew 6 or `brew install --cask` refuses the tap.

First open (ad-hoc signed):

```bash
xattr -cr /Applications/DevFS.app
open /Applications/DevFS.app
```

Still blocked: System Settings → Privacy & Security → Open Anyway.

Do not run `dist/DevFS.app` while `/Applications/DevFS.app` is running (same bundle ID).

---

## How to open

This is an `LSUIElement` extra. Proof it is running is the **externaldrive.connected.to.line.below** status item on the **right** of the menu bar, not a window from Finder or Launchpad.

1. Click that extra. The panel is opaque ~360×420 pt, not a 10px strip.
2. If the bar is full, look behind the Control Center overflow chevron **«**.
3. Double-clicking in Finder/Launchpad only changes the left-side app name. That is expected. There is no Dock icon.

---

## Usage

1. Settings → **Add mount** (Name, `user@host`, Port, Remote path, optional Local folder name) → **Save mount**.
2. Local files live under `~/Library/Application Support/DevFS/<localName>/`.
3. **Sync now** pulls down. **Pause** / **Resume**, **Open in Finder**, **Delete** on each row.
4. Resolve / SSH / rsync errors show as a red banner. Last sync line: `Last sync — never` until a run succeeds.
5. **Settings** at the bottom of the panel (and **Open Settings** on the empty state).

Password auth is unsupported. Add a key for the host (`ssh-copy-id` or equivalent) before **Sync now**.

---

## Permissions

No TCC prompts. This is process-based `ssh` / `rsync` / `scp`, not a File Provider extension.

---

## Data

| What | Where |
|---|---|
| Mounts | `~/Library/Application Support/DevFS/mounts.json` |
| Local trees | `~/Library/Application Support/DevFS/<localName>/` |
| Sync log | `~/Library/Application Support/DevFS/log.txt` |
| SSH control path | `~/Library/Application Support/DevFS/.ssh-%C` |
| Paused mounts | UserDefaults `engineer.badry.devfs.pausedIds` |
| Open at Login | `SMAppService.mainApp` (Settings toggle) |

Decode failure → empty list plus a red banner. The extra does not crash.

---

## Privacy

SSH only, `BatchMode=yes`. No passwords stored. Hosts and paths stay on this Mac except the SSH session you start.

---

## Uninstall

```bash
brew uninstall --cask devfs
```

Or delete `/Applications/DevFS.app`. Then:

```bash
rm -rf "$HOME/Library/Application Support/DevFS"
```

Turn off **DevFS** in System Settings → General → Login Items if it remains.

---

## Troubleshooting

| What you see | What to do |
|---|---|
| Finder “opens” nothing / no Dock icon | Click the **externaldrive.connected.to.line.below** extra on the right of the menu bar. |
| Extra missing | Overflow **«**, or `pgrep -x DevFS` then `open /Applications/DevFS.app`. |
| “Damaged” / cannot verify | `xattr -cr /Applications/DevFS.app`. `spctl --assess` is `rejected` even when it runs. |
| `brew install --cask` refuses the tap | `brew trust BadryansahBangsawan/mac-menu-apps` |
| **SSH key auth failed. Add a key for this host.** | `ssh user@host` with a key. `BatchMode=yes` will not prompt for a password. |
| **No mounts** | Add a mount in Settings. |
| **Paused** | **Resume** on that row, or it will not sync. |
| ~10px empty strip under the bar | Reinstall from this repo. |

---

## Build from source

```bash
git clone https://github.com/BadryansahBangsawan/devfs.git
cd devfs
swift build -c release --product DevFS
bash package-app.sh
open dist/DevFS.app
```

Tag `v*` runs CI: `DevFS.app.zip`. Never commit `dist/`.

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`. `FunTheme.swift` is copied verbatim (no shared package).

---

## FAQ

**Why is there no Dock icon?**  
It is a menu extra. Click the externaldrive.connected.to.line.below item on the **right** of the menu bar.

**Will it ask for an SSH password?**  
No. `BatchMode=yes` fails instead. Add a key for that host first.

**Where do local files land?**  
`~/Library/Application Support/DevFS/<localName>/`.

**How do I stop it opening at login?**  
Settings in the panel, or System Settings → General → Login Items → **DevFS**.

---

<div align="center">

[MIT](LICENSE)

</div>
