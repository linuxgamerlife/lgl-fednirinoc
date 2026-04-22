# fednirinoc

A post-install bash script that sets up [niri](https://github.com/niri-wm/niri) + [Noctalia](https://noctalia.dev) on a minimal Fedora install. Optionally uses Cinnamon Desktop as a base layer for lightdm, PipeWire, and polkit — or layers on top of an existing desktop environment.

---

> [!WARNING]
> **Tested on VMs and AMD hardware. Works fine.**
>
> **VM requirements:** GPU acceleration must be enabled with OpenGL support (e.g. VirtIO GPU + 3D acceleration in QEMU/KVM). Without this niri will not start.
>
> **Terminal:** Alacritty is installed. You will need to install any other apps. Additional app decisions have not been made for you.
>
> **To start after install:** reboot → log in via the display manager → select **Niri** from the session menu (gear/cog icon at the login screen).
>
> **First boot:** Noctalia may not appear the first time you run Niri. Log back out, select Niri again — it will start correctly.

---

## Concept

Fedora Everything (minimal) → run `install.sh` → reboot → DM login → select Niri or Cinnamon session

lightdm is always installed as the display manager. Cinnamon Desktop is optional — install it to get PipeWire, polkit, gnome-keyring, and a full GTK environment, or skip it if you already have a desktop environment installed. Niri + Noctalia sit on top as a selectable DM session.

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

1. Prompts for DNF settings (`installonly_limit`, `max_parallel_downloads`) and updates `/etc/dnf/dnf.conf`
2. Prompts whether to install Cinnamon Desktop group — skip if you already have a DE installed
3. Installs and enables lightdm + lightdm-gtk-greeter (always runs, regardless of Cinnamon choice)
4. Enables repos (avengemedia/danklinux COPR + terra)
5. Installs niri, Noctalia, and required deps
6. Ensures `/usr/share/wayland-sessions/niri.desktop` exists so lightdm offers the Niri session
7. Appends Noctalia startup config to `~/.config/niri/config.kdl`
8. Writes xdg-portal config
9. Sets `QT_QPA_PLATFORMTHEME=qt6ct` in `/etc/environment` (system-wide, covers polkit dialogs)
10. Registers a one-shot autostart to apply dark mode GTK theme on first login
11. Installs Noctalia polkit agent plugin to `~/.config/noctalia/plugins/polkit-agent`
12. Optionally installs LGL System Loadout and/or LGL SCX Scheduler Manager
13. Prints post-install instructions and prompts for reboot

## What Noctalia handles

These are not configured by the script — Noctalia manages them internally:

| Feature | Handler |
|---|---|
| Status bar | Noctalia built-in |
| App launcher | Noctalia built-in |
| Notifications | Noctalia built-in |
| Wallpaper | Noctalia built-in |
| Lock screen | Noctalia built-in |
| Night light | Noctalia NightLightService |
| Polkit | Noctalia polkit plugin (`~/.config/noctalia/plugins/polkit-agent`) |

## After install

Reboot, then at the login screen select the **Niri** session from the session picker (gear/cog icon).

On first login:
- Dark mode GTK theme is applied automatically by a one-shot autostart, then removes itself
- Run `qt6ct` to configure Qt6 app theming and `qt5ct` for Qt5 apps (apply the Noctalia color scheme)
- The Noctalia polkit plugin is pre-enabled in `plugins.json` — if polkit dialogs don't appear, open the Noctalia plugin manager and enable it manually

Display config (run inside niri after first launch):
```bash
niri msg outputs
# Note your output name and mode
# Edit ~/.config/niri/config.kdl — uncomment the OUTPUT CONFIGURATION section
# Then: niri msg action quit
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

## Removing lightdm for a minimal install

If you want a TTY-only setup after install:

```bash
sudo dnf remove lightdm lightdm-gtk-greeter
sudo systemctl set-default multi-user.target
```

Then start niri manually from TTY with `niri-session`.

## Known Issues

| Issue | Workaround |
|---|---|
| Screencasting broken — niri bug [#2399](https://github.com/niri-wm/niri/issues/2399) | Restart portals manually |
| Suspend → red screen (niri + Fedora GPU bug) | Avoid suspend |
| Display output config requires niri running | Manual step post-install (see After install above) |
| `power-profiles-daemon` conflicts with `tuned-ppd` | Excluded from install — `tuned-ppd` provides the same service |
| Noctalia polkit plugin not appearing | Enable manually via Noctalia plugin manager |

## Docs

- [`packages.md`](docs/packages.md) — full package list with rationale
- [`niri-config.md`](docs/niri-config.md) — niri config.kdl reference
- [`install-sequence.md`](docs/install-sequence.md) — install phase reference
- [`open-questions.md`](docs/open-questions.md) — unresolved items

## License

[MIT](LICENSE)
