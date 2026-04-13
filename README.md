# fedirinoc

Post-install script for Fedora Everything (minimal TTY) → [niri](https://github.com/niri-wm/niri) + [Noctalia](https://noctalia.dev) desktop.

Minimal. No bloat. GTK3 focused.

---

> [!WARNING]
> **This script has not been tested on a real system yet.**
> It is based on research and documentation only. Use at your own risk.
> Feedback and bug reports are welcome.

---

## What it does

Automates the setup of a minimal Fedora desktop after a fresh Fedora Everything install (no DE, boots to TTY):

- Enables required repos (avengemedia/dms COPR for niri, terra for Noctalia)
- Installs niri, xwayland-satellite, Noctalia shell, greetd, tuigreet, portals, PipeWire, and dependencies
- Configures niri (`~/.config/niri/config.kdl`) — appends required settings, does not overwrite
- Disables waybar autostart from default niri config
- Sets up greetd + tuigreet as the login manager (with SELinux policy and Fedora boot-wiring fix)
- Configures xdg-desktop-portal to avoid Nautilus as file picker
- Registers GTK theme (adw-gtk3) to apply on first login
- Enables PipeWire user services via linger
- Prints a banner with the one manual step required post-install (display output config)

## Prerequisites

- Fedora Everything minimal install (no desktop environment)
- Boots to TTY
- Regular user with `sudo` access
- Internet connection

## What Noctalia handles

These are **not** configured by this script — Noctalia manages them itself:

| Feature | Handler |
|---|---|
| Wallpaper | Noctalia built-in |
| Notifications | Noctalia built-in |
| Lock screen | Noctalia built-in (Wayland session lock) |
| Night light | Noctalia NightLightService |
| Status bar | Noctalia built-in |
| App launcher | Noctalia built-in |

## Usage

```bash
git clone https://github.com/linuxgamerlife/lgl-fedirinoc.git
cd lgl-fedirinoc
chmod +x install.sh
./install.sh
```

Reboot after the script completes. greetd will start on next boot.

## Post-install: Display configuration

Display output config cannot be automated (requires niri to be running). After first login:

```bash
niri msg outputs
```

Note your output name and mode, then edit `~/.config/niri/config.kdl` — find the `OUTPUT CONFIGURATION` section and fill in the commented block. Then:

```bash
niri msg action quit
```

greetd will restart the session with the new config.

## Known issues

| Issue | Status | Workaround |
|---|---|---|
| Screencasting broken | Known niri bug [#2399](https://github.com/niri-wm/niri/issues/2399) | Restart portals: stop all 3, start portal + portal-gnome only |
| Suspend → red screen / reboot | Known niri + Fedora GPU bug | Avoid suspend for now |
| greetd not starting on boot | Fedora packaging issue | Script forces correct systemd target symlink |
| Do not use `pkill niri` | Causes infinite greetd restart loop | Use `niri msg action quit` |

## Docs

Research and reference docs are in [`docs/`](docs/):

- [`packages.md`](docs/packages.md) — full package list with rationale
- [`niri-config.md`](docs/niri-config.md) — niri config.kdl reference
- [`greeter.md`](docs/greeter.md) — greetd + tuigreet setup notes
- [`install-sequence.md`](docs/install-sequence.md) — install phase breakdown
- [`open-questions.md`](docs/open-questions.md) — unresolved items

## License

[MIT](LICENSE)
