# Changelog

All notable changes to this project will be documented in this file.

---

## [Unreleased]

### Known gaps
- Display output configuration requires manual step post-install
- Idle lock trigger (swayidle) not yet included
- Script untested on real hardware

---

## [0.0.1] - 2026-04-13

Initial release. Research-based, untested.

### Added
- `install.sh` — full install script covering repos, packages, niri config, greeter, portals, PipeWire, GTK theme
- Repo setup: avengemedia/dms COPR (niri), terra (Noctalia)
- Package install: niri, xwayland-satellite, noctalia-shell, greetd, greetd-selinux, tuigreet, xdg-desktop-portal stack, polkit-gnome, PipeWire stack, cliphist, power-profiles-daemon, adw-gtk3-theme
- Niri config: copies default config if absent, comments out waybar spawn, appends Noctalia-required blocks (idempotent)
- greetd + tuigreet login manager with SELinux policy and Fedora boot-wiring workaround
- niri.desktop fallback creation if not shipped by COPR package
- xdg-portal config to prevent Nautilus file picker
- GTK theme autostart (applies adw-gtk3 via gsettings on first login, self-removes)
- PipeWire user services enabled via loginctl linger + manual .wants symlinks (TTY-safe)
- Post-install display config banner with instructions
- Research docs in `docs/`

### Not included (Noctalia handles)
- Wallpaper, notifications, lock screen, night light, status bar, app launcher

[0.0.1]: https://github.com/linuxgamerlife/lgl-fedirinoc/
