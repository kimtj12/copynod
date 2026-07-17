# CopyNod

A tiny macOS menu bar utility that shows a small check-mark HUD **only when ⌘C / ⌘X actually copied something** — so you never have to paste just to find out.

- **No false positives** — a key press is only a *trigger*; the HUD appears only after the clipboard `changeCount` actually changes. No selection, or the app refused to copy? Nothing is shown.
- **Near-zero footprint** — event-driven (no polling while idle), ~0% idle CPU, small resident memory. Verification polls the clipboard counter for at most ~300 ms after a copy shortcut.
- **Stays out of the way** — click-through HUD, never steals focus, works over full-screen apps. Three positions: near cursor (default), bottom center, top right.
- **English + Korean**, light/dark aware, Liquid Glass material on macOS 26+ with a native HUD fallback on macOS 14–15.

## Install

Requires macOS 14 or later.

1. Download the latest `CopyNod-x.y.z.zip` from [Releases](https://github.com/kimtj12/copynod/releases), unzip, and move **CopyNod.app** to Applications.
2. On first launch, grant **Accessibility** permission (System Settings → Privacy & Security → Accessibility). CopyNod needs it to observe the ⌘C/⌘X key events globally — key events are never modified or blocked.
3. Optionally enable **Launch at Login** from the menu bar icon.

Updates are delivered in-app via [Sparkle](https://sparkle-project.org) (EdDSA-signed, checked once a day).

## Privacy

- **CopyNod never reads your clipboard contents.** It only compares the integer [`changeCount`](https://developer.apple.com/documentation/appkit/nspasteboard/changecount) of the pasteboard to know *that* something was copied — never *what*.
- No analytics, no crash reporting, no data collection of any kind.
- The only network access is Sparkle's daily update check against this repository's appcast.
- It's open source — you can verify all of the above in the code.

## Build from source

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project CopyNod.xcodeproj -scheme CopyNod build
```

Design docs (Korean) live in [`docs/`](docs/), starting with [planning.md](docs/planning.md).

## License

[MIT](LICENSE)
