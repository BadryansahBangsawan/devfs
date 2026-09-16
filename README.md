<div align="center">

# DevFS

**SSH/rsync folder sync straight from the macOS menu bar.**  
macOS menu extra — lives in the menu bar, no Dock icon.

<br/>

[![Latest Release](https://img.shields.io/github/v/release/BadryansahBangsawan/devfs?style=flat-square&color=76B900&label=latest)](https://github.com/BadryansahBangsawan/devfs/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/BadryansahBangsawan/devfs/releases/latest)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)

<br/>

</div>

---

## Download

| Platform | File |
|---|---|
| **macOS** (Apple Silicon & Intel, macOS 14+) | `DevFS-*-macos.zip` |

[Go to Releases](https://github.com/BadryansahBangsawan/devfs/releases/latest)

---

## Installation

### Homebrew (recommended)

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew install --cask devfs
```

A **DevFS** icon appears in the menu bar. If Gatekeeper blocks it on first launch:

```bash
xattr -cr /Applications/DevFS.app && open /Applications/DevFS.app
```

Or: right-click the app, Open, then Open again. Still blocked? **System Settings → Privacy & Security → Open Anyway**.

### GitHub Releases

1. Download `DevFS-*-macos.zip` from [Releases](https://github.com/BadryansahBangsawan/devfs/releases/latest)
2. Unzip and drag **DevFS** into Applications
3. On first launch, run the xattr command above if Gatekeeper blocks it

### Build from source

```bash
git clone https://github.com/BadryansahBangsawan/devfs.git
cd devfs
bash package-app.sh
open dist/DevFS.app
```

Requires Xcode Command Line Tools and Swift 5.9+.

---

## Notes

– Requires rsync and ssh on PATH (included on macOS by default).
– Uses your existing ~/.ssh config and keys.
– Full Disk Access may be required to sync protected directories.
– No Dock icon; lives entirely in the menu bar.

---

<div align="center">

Made with ♥ for developers who prefer staying in the flow.

</div>
