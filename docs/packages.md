# Package List

## Cinnamon Desktop Group

```bash
sudo dnf5 group install -y cinnamon-desktop
```

Installed first. Provides the display manager, PipeWire stack, polkit agent, and core GTK environment. Niri/Noctalia layer on top — Cinnamon session remains available as a fallback.

**Provided by this group (not installed separately):**
- `lightdm` — display manager / greeter
- `pipewire` + `pipewire-pulse` + `wireplumber` — audio and screen share
- `gnome-keyring` — secret storage
- `gnome-menus` — `applications.menu` for KDE app discovery
- polkit agent

## Repos

```bash
# niri
sudo dnf copr enable avengemedia/danklinux

# Noctalia (terra)
sudo dnf install -y --nogpgcheck \
  --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' \
  terra-release
```

## Core Install

```bash
sudo dnf install -y --exclude=power-profiles-daemon --skip-broken \
  niri \
  xwayland-satellite \
  noctalia-shell \
  brightnessctl \
  ImageMagick \
  python3 \
  git \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  xdg-desktop-portal-gnome \
  lxqt-policykit \
  qt6ct \
  cliphist
  # adw-gtk3-theme  # added automatically if available in repos
  # qt5ct  # uncomment for Qt5 app theming
```

## Package Notes

| Package | Reason |
|---|---|
| `niri` | Wayland compositor — from avengemedia/danklinux COPR |
| `xwayland-satellite` | X11 compatibility for games/legacy apps |
| `noctalia-shell` | Full desktop shell — bar, launcher, notifications, wallpaper, lock screen |
| `brightnessctl` | Screen brightness — Noctalia dep |
| `ImageMagick` | Image processing — Noctalia dep |
| `python3` | Noctalia dep |
| `git` | Noctalia dep |
| `xdg-desktop-portal-gnome` | Screencasting support |
| `xdg-desktop-portal-gtk` | File picker |
| `lxqt-policykit` | Polkit auth agent for niri session — replaces polkit-gnome (removed F41+); Cinnamon session uses its own agent |
| `cliphist` | Clipboard history — Noctalia integrates directly |
| `adw-gtk3-theme` | GTK theme for GTK apps running under niri |
| `qt6ct` | Qt6 theme config tool — set style/palette for Qt6 apps (`adwaita-qt`/`adwaita-qt6` dropped F39+) |
| `qt5ct` | Optional — same for Qt5 apps if needed |

## Exclusions

- `power-profiles-daemon` — conflicts with `tuned-ppd`, which ships as part of `tuned` (installed by default on Fedora). Excluded via `--exclude=power-profiles-daemon`
- `pipewire` / `wireplumber` / `gnome-keyring` / `gnome-menus` — provided by the Cinnamon Desktop group
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
