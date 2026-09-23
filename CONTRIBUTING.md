# Contributing

Thanks for improving DevFS.

End users install with `brew tap BadryansahBangsawan/mac-menu-apps` and `brew install --cask devfs`. This file is for source contributors.

## Build

macOS 14 or later and Swift 5.9+ (Xcode or Command Line Tools):

```bash
swift build
bash package-app.sh
open dist/DevFS.app
```

Do not commit `dist/`, `.build/`, `.swiftpm/`, or secrets. Do not run `dist/` next to `/Applications/DevFS.app` (same bundle ID).

## Changes

- Keep the app a menu extra (`LSUIElement`). Do not add a Dock icon or a `WindowGroup`.
- Copy `Sources/FunTheme.swift` verbatim. Call `.funPanel()` on the outermost view `RootView.body` returns. Do not use `.regularMaterial` / `.thinMaterial` on panel chrome.
- Surface failures as a red label with a useful message. Do not `fatalError` on runtime paths, swallow errors with `try?`, or use empty `catch`.
- SSH is `BatchMode=yes` only. No passwords, no askpass, no File Provider extension.
- Match existing SwiftUI / AppKit patterns in `Sources/`. Do not add a shared package or extra targets.
- App Sandbox stays off. Do not add a paid Team ID requirement.

## Pull requests

Open against `main`. Describe the user-visible change and how you ran the app after packaging.
