# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Planned
- Live hardware testing
- GTK3 graphical installer app (future)

---

## [0.2.0] - 2026-04-15

### Changed
- **Architecture:** Cinnamon Desktop group now installed first as the base layer. Provides lightdm (display manager), PipeWire + WirePlumber, polkit agent, gnome-keyring, gnome-menus. Niri + Noctalia sit on top as a selectable DM session.
- **Session start:** User now reboots into the display manager and selects the Niri session — no longer requires TTY login and manual `niri` command.
- Post-install banner updated to reflect DM-based session start.

### Added
- `install_cinnamon()` phase — `dnf5 group install -y cinnamon-desktop` — runs before repos and package install
- `ensure_niri_session_file()` phase — checks for `/usr/share/wayland-sessions/niri.desktop`, writes it if the COPR didn't ship it (required for lightdm to offer the Niri session)

### Removed
- `configure_pipewire()` phase — PipeWire user session setup removed; Cinnamon Desktop group provides and manages PipeWire via its own systemd units

### Changed (packages)
- Removed from explicit package install: `pipewire`, `pipewire-pulse`, `wireplumber`, `gnome-keyring`, `gnome-menus` — all now provided by Cinnamon Desktop group

---

## [0.1.0] - 2026-04-13

### Added
- `configure_system_env` phase: writes `QT_QPA_PLATFORMTHEME=qt6ct` to `/etc/environment` — ensures polkit dialogs and other system-spawned Qt processes inherit Qt theming (niri config.kdl env block alone is insufficient)
- `offer_lgl_tools` phase: optional post-install prompts for LGL System Loadout (graphical Fedora setup wizard) and LGL SCX Scheduler Manager (Qt6 GUI for sched-ext BPF schedulers) — both default to skip

### Fixed
- Portal config written to wrong path (`~/.config/niri/niri-portals.conf`) — xdg-desktop-portal never read it as no `niri.portal` file exists in the system portals directory. Now writes to `~/.config/xdg-desktop-portal/niri-portals.conf` which is in the actual search path
- Added `org.freedesktop.impl.portal.FileChooser=gtk` to portal config — without it gnome portal intercepts FileChooser calls and fails silently on niri (requires GNOME Shell)
- Added `gnome-menus` to package list — provides `applications.menu` required by KDE apps (Dolphin) to discover installed applications; without it the "Choose Application" dialog is empty

### Changed
- Replaced `qt6ct` (then briefly `qadwaitadecorations-qt6`) back to `qt6ct` — confirmed correct for F43; `adwaita-qt`/`adwaita-qt6` dropped F39+, `qadwaitadecorations-qt6` not in F43 repos
- Niri env var: `QT_QPA_PLATFORMTHEME "qt6ct"` — qt6ct configured post-install via GUI; Qt5 per-app workaround documented (`QT_QPA_PLATFORMTHEME=qt5ct <app>`)
- Dark mode: autostart now sets both `gtk-theme adw-gtk3-dark` and `color-scheme prefer-dark` via gsettings on first login (covers GTK3, GTK4, and portal-aware apps)

---

## [0.0.2] - 2026-04-13

### Changed
- Reverted from GTK app back to bash script approach — simpler, no base DE required
- Removed greetd/tuigreet — no display manager, user types `niri` from TTY
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

[0.2.0]: https://github.com/linuxgamerlife/lgl-fednirinoc/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/linuxgamerlife/lgl-fednirinoc/compare/v0.0.2...v0.1.0
[0.0.2]: https://github.com/linuxgamerlife/lgl-fednirinoc/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/linuxgamerlife/lgl-fednirinoc/releases/tag/v0.0.1
