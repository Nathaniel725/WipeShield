# Changelog

## 1.3.0 (2026-09-20)

- **Renamed to WipeShield** (bundle id `com.wipeshield.mac`).
- **Localization**: standard `.strings` system with 8 languages — English,
  简体中文, 繁體中文, 日本語, 한국어, Deutsch, Français, Español. Follows the
  system language; add a new language by dropping a `.lproj` folder (no code
  changes needed).

## 1.2.0 (2026-09-20)

- **Fixed the crash on "Start Cleaning Mode"** (present since 1.0.1):
  `CGEventMask(~0)` inferred `~0` as `Int(-1)`, and the negative `Int → UInt64`
  conversion trapped at runtime. Now `~CGEventMask(0)`.
- Reentrancy hardening: button action may be invoked twice by AppKit during
  trackpad gesture processing — `install()` / `start()` are now idempotent and
  the session is registered before starting.

## 1.1.0 (2026-09-19)

- Dock app with a main window (replaces the menu-bar-only form).
- Button / ⌥⌘K starts cleaning mode; `esc` returns to the main window.

## 1.0.1 (2026-09-19)

- Block media keys (brightness / volume / mute / backlight / playback) — only
  the power key passes through.
- Block trackpad gestures (pinch, swipe, rotate) via a full event mask with a
  whitelist, so screen sharing and other apps no longer react while wiping.
- Fixed local dev signing so Accessibility permission survives rebuilds.

## 1.0.0 (2026-09-19)

- Initial release: full-screen black shield, CGEventTap input blocking
  (keyboard / mouse / trackpad / scroll), `esc` to exit, power key pass-through,
  sleep assertion, auto-exit on lid close, failure-safe (never "fake locked").
