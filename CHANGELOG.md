# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Changed
- Replaced `qt6ct` with `adwaita-qt` + `adwaita-qt6` for Qt theming — native Adwaita style for Qt5 and Qt6 apps without a config tool
- Niri env var changed from `QT_QPA_PLATFORMTHEME "qt6ct"` to `QT_STYLE_OVERRIDE "adwaita"`

### Planned
- Live hardware testing
- GTK3 graphical installer app (future)

---

## [0.0.2] - 2026-04-13

### Changed
- Reverted from GTK app back to bash script approach — simpler, no base DE required
- Removed greetd/tuigreet — no display manager, user types `niri-session` from TTY
- Replaced `mate-polkit` with `lxqt-policykit` — more modern, same function
- `xwayland-satellite` now explicitly spawned in config.kdl (required for X11/game compatibility)
- Removed cosmetic window-rule (rounded corners) from config append — not required
- `install.sh` moved to project root

### Fixed (from 0.0.1 testing)
- Config KDL parse error was silently preventing all `spawn-at-startup` from firing
- `scale` must be float (`1.0` not `1`) in output block
- `mode` string must have closing `"` in output block
- `position x=0 y=0` not needed for single monitor — removed from output block template
- Confirmed niri launches successfully with VirtIO GPU + 3D acceleration enabled in VM

---

## [0.0.1] - 2026-04-13

Initial release. Research-based bash script, partially tested in VM.

### Added
- `install.sh` — bash install script covering repos, packages, niri config, portals, PipeWire
- Repo setup: avengemedia/danklinux COPR (niri), terra (Noctalia)
- Package install: niri, xwayland-satellite, noctalia-shell, greetd, tuigreet, xdg-portal stack, mate-polkit, PipeWire, cliphist, adw-gtk3-theme
- Niri config: copies default if absent, comments out waybar, appends Noctalia spawn (idempotent)
- xdg-portal config to prevent Nautilus file picker
- PipeWire via loginctl linger + .wants symlinks (TTY-safe)
- Post-install display config banner
- Research docs in `docs/`

### Not included (Noctalia handles)
- Wallpaper, notifications, lock screen, night light, status bar, app launcher

[0.0.2]: https://github.com/linuxgamerlife/lgl-fedirinoc/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/linuxgamerlife/lgl-fedirinoc/releases/tag/v0.0.1
