# WipeGuard 擦屏卫士

**Lock every input on your Mac so you can clean the screen and keyboard without shutting down.** Open WipeGuard, click *Start Cleaning Mode* — the screen goes pure black, and every keystroke, trackpad gesture, mouse move, scroll and media key is dropped at the system level. Press `esc` when you're done. That's it.

[![Download on GitHub Releases](https://img.shields.io/badge/download-GitHub%20Releases-blue)](../../releases)
![platform](https://img.shields.io/badge/platform-macOS%2010.15%2B-arm64%20%2B%20x86__64)
![license](https://img.shields.io/badge/license-MIT-green)

[中文说明](README.zh-CN.md)

<!-- TODO(record a 5s GIF and drop it here): start mode → wipe keyboard → esc -->
<!-- ![demo](docs/demo.gif) -->

## Why

You want to wipe your MacBook's screen or keyboard, but:

- you don't want to shut down, and with the system lock screen any key press wakes the display and types into the password field;
- a stray key leaves garbage in the document you're editing;
- a stray trackpad swipe triggers pinch-zoom in the screen-sharing window you left open.

WipeGuard covers every display with a pure-black shield and discards **all** input events — nothing lights up, nothing gets typed, nothing leaks to any app.

## How it compares

| | **WipeGuard** | [KeyboardCleanTool](https://folivora.ai/keyboardcleantool/) | [pristine_screen](https://github.com/RhinoInani/pristine_screen) | [LUCE](https://github.com/arinltte/LUCE) |
|---|---|---|---|---|
| Blocks keyboard | ✅ | ✅ | ✅ | ✅ |
| Blocks mouse / trackpad / scroll / gestures | ✅ | ✅ | ❌ cursor flies around | ❌ (mouse is the unlock) |
| Blocks media keys (brightness / volume / backlight / playback) | ✅ | ✅ | ❌ | ✅ |
| Full-screen black shield | ✅ | ❌ screen stays on | ✅ | ❌ |
| Exit | **single `esc` key** | hotkey combo | — | click a button |
| Prevents sleep / screensaver / auto-lock | ✅ | ❌ | ❌ | brightness check only |
| Fail-safe (never "fake locked") | ✅ | — | ❌ | partial |
| Auto-exit on lid close | ✅ | ❌ | ❌ | ❌ |
| Launch-and-click + global hotkey | ✅ ⌥⌘K | ❌ | ✅ | ❌ |
| Native, zero dependencies | ✅ ~750 KB universal | — | Flutter | SwiftUI |
| Minimum macOS | **10.15** | — | unknown | 14 |
| Open source | ✅ MIT | ❌ | ✅ | ✅ |

"Fail-safe" means: if the input blocker ever becomes invalid (permission revoked, system policy), WipeGuard **immediately ends cleaning mode and tells you**, instead of leaving a black screen that looks locked but isn't.

## Install

Download `WipeGuard-<version>-universal.zip` from [Releases](../../releases), unzip, and drag **WipeGuard.app** to `/Applications`.

- Builds are ad-hoc signed (no Apple Developer certificate yet), so on first launch: **right-click the app → Open → Open**. After that it opens normally.
- Requires macOS 10.15 or later. Universal binary (Apple Silicon + Intel).

### First launch (one-time permission)

Blocking system input requires the **Accessibility** permission (every tool in this category needs it):

1. On first launch WipeGuard shows a guide — click *Open System Settings*;
2. In **System Settings → Privacy & Security → Accessibility**, allow WipeGuard;
3. Back in the dialog, click *Granted, Retry*.

## Usage

| Action | Effect |
|---|---|
| Open app → **Start Cleaning Mode** (or `⌥⌘K` anywhere) | Screen goes black, all input blocked |
| Press `esc` | Exit cleaning mode, back to the main window |
| Power key | Native system behavior (short press = sleep dialog, hold = shutdown) |
| Close window (red button) | App stays in the Dock; click the Dock icon to bring the window back |
| `⌘Q` | Quit |

While cleaning, the app holds a power assertion so the display never sleeps, the screensaver never starts, and auto-lock never kicks in. Closing the lid or putting the system to sleep **automatically ends** cleaning mode, so you can't get stuck behind the shield.

## How it works

~1,000 lines of dependency-free Swift:

- **Input blocking** — a session-level `CGEventTap` (head-insert) subscribes to *all* event types and applies a whitelist: `esc` triggers exit; the power key (`NX_KEY_TYPE_POWER`) passes through; everything else is dropped — including media keys (`NX_SYSDEFINED`, subtype 8), trackpad gestures, pressure and tablet events. A disabled tap is re-enabled, or cleaning mode is terminated — never a "fake lock".
- **Visual shield** — one borderless, pure-black window per display at screen-saver level (1000), joining all Spaces (including full-screen apps), rebuilt automatically when displays change.
- **State keeping** — `IOPMAssertionCreateWithName(PreventUserIdleDisplaySleep)` blocks sleep/screensaver; `NSWorkspace.willSleep` ends the session as a safety net.

## Known limitations

- **Touch Bar** (2016–2019 MacBook Pro): the Touch Bar is separate hardware; touching it still lights it up (the input itself is blocked).
- **Notification banners** may float above the shield; enable Do Not Disturb while cleaning.
- System-level gestures like three-finger desktop swipe are handled below the session event tap and may still work.
- "Launch at Login" is macOS 13+ only.
- Distributing outside Releases with your own Developer ID requires re-signing + notarization.

## Privacy

No network access, no data collection, no third-party code. The entire codebase is readable in an afternoon.

## Development

Requirements: Xcode Command Line Tools (`xcode-select --install`).

```bash
./scripts/build.sh          # build universal WipeGuard.app (icon, dual-arch, lipo, sign)
```

- The build script auto-deploys to `/Applications` and stops a running instance; set `SKIP_DEPLOY=1` to skip (CI does).
- It signs with a local certificate named **WipeGuard Dev** if present (so the Accessibility permission survives rebuilds — see `scripts/create_cert.sh`), otherwise falls back to ad-hoc.
- Automated-test safety net: `WipeGuard.app/Contents/MacOS/WipeGuard --self-test <seconds>` exits cleanly after N seconds; `--self-test-start` additionally triggers the start path once.

Releases are built by GitHub Actions (`.github/workflows/release.yml`) on tag push.

## License

[MIT](LICENSE)
