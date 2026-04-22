# Package List

## Cinnamon Desktop Group

```bash
sudo dnf5 group install -y cinnamon-desktop
```

Installed first. Provides the display manager, PipeWire stack, polkit agent (for Cinnamon session), and core GTK environment. Niri/Noctalia layer on top — Cinnamon session remains available as a fallback.

**Provided by this group (when installed):**
- `lightdm` — display manager / greeter
- `pipewire` + `pipewire-pulse` + `wireplumber` — audio and screen share (also ships with Fedora minimal)
- `gnome-keyring` — secret storage
- `gnome-menus` — `applications.menu` for KDE app discovery
- `mate-polkit` — polkit auth agent for the Cinnamon session; not used by the niri session (Noctalia polkit plugin handles polkit there)

`gnome-keyring` and `gnome-menus` are also explicitly installed in the core package phase so they are present even when Cinnamon is skipped.

## Repos

```bash
# niri
sudo dnf copr enable avengemedia/danklinux

# Noctalia (terra)
sudo dnf install -y --nogpgcheck \
  --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' \
  terra-release
```

## Display Manager (always installed)

```bash
sudo dnf install -y lightdm lightdm-gtk-greeter
sudo systemctl set-default graphical.target
sudo systemctl enable lightdm
```

Runs after the optional Cinnamon phase so lightdm is always present — Cinnamon provides it when installed, but this ensures it's there when Cinnamon is skipped.

To remove lightdm after install for a minimal TTY-only setup:

```bash
sudo dnf remove lightdm lightdm-gtk-greeter
sudo systemctl set-default multi-user.target
```

Start niri manually from TTY with `niri-session`.

## Core Install

```bash
sudo dnf install -y --exclude=power-profiles-daemon --skip-broken \
  niri \
  noctalia-shell \
  brightnessctl \
  ImageMagick \
  python3 \
  git \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  xdg-desktop-portal-gnome \
  qt6ct \
  qt5ct \
  cliphist
  # adw-gtk3-theme  # added automatically if available in repos
```

## Noctalia Polkit Plugin

Installed via sparse-checkout (not a dnf package):

```bash
git clone --no-checkout --depth=1 --filter=blob:none \
  https://github.com/noctalia-dev/noctalia-plugins.git /tmp/noctalia-plugins
git -C /tmp/noctalia-plugins sparse-checkout set polkit-agent
git -C /tmp/noctalia-plugins checkout
cp -r /tmp/noctalia-plugins/polkit-agent ~/.config/noctalia/plugins/polkit-agent
```

## Package Notes

| Package | Reason |
|---|---|
| `lightdm-gtk-greeter` | GTK login screen for lightdm — not always pulled in by the Cinnamon group |
| `niri` | Wayland compositor — from avengemedia/danklinux COPR |
| `noctalia-shell` | Full desktop shell — bar, launcher, notifications, wallpaper, lock screen |
| `brightnessctl` | Screen brightness — Noctalia dep |
| `ImageMagick` | Image processing — Noctalia dep |
| `python3` | Noctalia dep |
| `git` | Noctalia dep; also used to install Noctalia polkit plugin |
| `xdg-desktop-portal-gnome` | Screencasting support |
| `xdg-desktop-portal-gtk` | File picker |
| `cliphist` | Clipboard history — Noctalia integrates directly |
| `adw-gtk3-theme` | GTK theme for GTK apps running under niri |
| `qt6ct` | Qt6 theme config tool (`adwaita-qt`/`adwaita-qt6` dropped F39+) |
| `qt5ct` | Qt5 theme config tool — same as qt6ct for Qt5 apps |

## Exclusions

- `power-profiles-daemon` — conflicts with `tuned-ppd`, which ships as part of `tuned` (installed by default on Fedora). Excluded via `--exclude=power-profiles-daemon`
- `xwayland-satellite` — built into niri as of 25.08; no longer a separate package
- `waybar` — not needed, Noctalia provides the bar
- `mako` — not needed, Noctalia handles notifications
- `swaybg` / `wlsunset` — not needed, Noctalia handles wallpaper and night light

## Handled by Noctalia — do not install separately

- Notifications (replaces mako)
- Wallpaper (replaces swaybg)
- Night light (replaces wlsunset)
- Lock screen (Wayland session lock protocol)
- Bar (replaces waybar)
- Launcher
