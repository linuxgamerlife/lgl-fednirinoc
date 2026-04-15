# fednirinoc

A post-install bash script that sets up [niri](https://github.com/niri-wm/niri) + [Noctalia](https://noctalia.dev) on a minimal Fedora install, using Cinnamon Desktop as the base layer for the display manager and core deps.

---

> [!WARNING]
> **Tested on VMs and AMD hardware. Works fine.**
>
> **VM requirements:** GPU acceleration must be enabled with OpenGL support (e.g. VirtIO GPU + 3D acceleration in QEMU/KVM). Without this niri will not start.
>
> **Minimal install:** The only pre-installed terminal is Alacritty. Install whatever else you want — no guarantees on what other apps work.
>
> **To start after install:** reboot → log in via the display manager → select **Niri** from the session menu (gear/cog icon at the login screen).
>
> **First boot:** Noctalia may not appear the first time you run Niri. Log back out, select Niri again — it will start correctly.

---

## Concept

Fedora Everything (minimal) → run `install.sh` → reboot → DM login → select Niri or Cinnamon session

Cinnamon Desktop is installed as the base layer. It provides the display manager (lightdm), PipeWire, polkit, and GTK environment. Niri + Noctalia sit on top as a selectable session — no TTY login, no manual session start.

## Install

Download the [Fedora Everything ISO](https://fedoraproject.org/misc/#everything) and install it. During setup, **do not select any software options** — leave the software selection empty so the system boots to a TTY with no desktop environment.

From a fresh Fedora Everything TTY login:

```bash
sudo dnf install -y git
git clone https://github.com/linuxgamerlife/lgl-fednirinoc.git
cd lgl-fednirinoc
chmod +x install.sh
./install.sh
```

## What it does

1. Installs Cinnamon Desktop group (provides lightdm, PipeWire, polkit, GTK env)
2. Enables repos (avengemedia/danklinux COPR + terra)
3. Installs niri, Noctalia, and required deps
4. Ensures `/usr/share/wayland-sessions/niri.desktop` exists so lightdm offers the Niri session
5. Appends Noctalia startup config to `~/.config/niri/config.kdl`
6. Writes xdg-portal config
7. Sets Qt theme env var in `/etc/environment` (system-wide, covers polkit dialogs)
8. Registers a one-shot autostart to apply dark mode GTK theme on first login
9. Optionally installs LGL System Loadout and/or LGL SCX Scheduler Manager
10. Prints post-install instructions

## What Noctalia handles

These are not configured by the script — Noctalia manages them internally:

| Feature | Handler |
|---|---|
| Wallpaper | Noctalia built-in |
| Notifications | Noctalia built-in |
| Lock screen | Noctalia built-in |
| Night light | Noctalia NightLightService |
| Status bar | Noctalia built-in |
| App launcher | Noctalia built-in |

## After install

Reboot, then at the login screen select the **Niri** session from the session picker (gear/cog icon).

On first login, a one-shot autostart applies dark mode GTK theme automatically, then removes itself.

Run `qt6ct` to configure Qt app theming (apply the Noctalia color scheme).

Display config (run inside niri after first launch):
```bash
niri msg outputs
# Note your output name and mode
# Edit ~/.config/niri/config.kdl — uncomment the OUTPUT CONFIGURATION section
```

## Optional LGL Tools

The script will offer to install these at the end:

| Tool | Description |
|---|---|
| [LGL System Loadout](https://github.com/linuxgamerlife/lgl-system-loadout) | Graphical setup wizard — browse and install curated packages across gaming, multimedia, content creation, and dev |
| [LGL SCX Scheduler Manager](https://github.com/linuxgamerlife/lgl-scxctl-manager) | Qt6 GUI for managing sched-ext BPF CPU schedulers with status monitoring and system tray |

Both default to skip — press Enter to pass.

## Browser File Picker

The install script configures the GTK portal as the FileChooser handler. If the file picker still doesn't work in Firefox, in `about:config` set `widget.use-xdg-desktop-portal.file-picker` to `0` to use the native GTK file picker as a fallback.

## Known Issues

| Issue | Status | Workaround |
|---|---|---|
| Screencasting broken | Known niri bug [#2399](https://github.com/niri-wm/niri/issues/2399) | Restart portals manually |
| Suspend → red screen | Known niri + Fedora GPU bug | Avoid suspend |
| Display output config | Requires running niri | Manual step post-install |
| `power-profiles-daemon` conflicts with `tuned-ppd` | `tuned` (and `tuned-ppd`) ship by default on Fedora — `power-profiles-daemon` always conflicts | Excluded from install |

## Docs

- [`packages.md`](docs/packages.md) — full package list with rationale
- [`niri-config.md`](docs/niri-config.md) — niri config.kdl reference
- [`install-sequence.md`](docs/install-sequence.md) — install phase reference
- [`open-questions.md`](docs/open-questions.md) — unresolved items

## License

[MIT](LICENSE)
