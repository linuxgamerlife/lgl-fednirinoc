# Niri Configuration

Config file: `~/.config/niri/config.kdl`

## Display / Output Setup

Run this after first niri launch to enumerate outputs:

```bash
niri msg outputs
```

Output example:
```
Output: eDP-1
  make: "BOE"
  model: "0x0BCA"
  ...
  Modes:
    2560x1600@120.000 (current, preferred)
```

Then add to config.kdl (replace output name and mode with actual values):

```kdl
output "eDP-1" {
    mode "2560x1600@120.000"
    scale 1.5
    transform "normal"
}
```

**Critical — KDL syntax rules (parse errors silently prevent all spawn-at-startup):**
- `mode` value must have closing `"` — `mode "1920x1080@60.000"` not `mode "1920x1080@60.000`
- `scale` must be a float — `scale 1.0` not `scale 1`
- `position x=0 y=0` not needed for single monitor — omit it
- Always run `niri validate` after editing config. Any parse error = no spawns fire.

> If Noctalia or other spawn-at-startup apps fail to launch, run `niri validate` first — config parse error is the most likely cause.

> Script flow: run `niri msg outputs` in a subshell, parse output names, prompt user to confirm/select, inject into config.

## Xwayland

xwayland-satellite must be explicitly spawned in config.kdl for X11/game compatibility:

```kdl
spawn-at-startup "xwayland-satellite"
```

niri auto-integrates it (handles the socket), but the process still needs to be running. Confirmed required for gaming.

## Noctalia Required Settings

These must be present for Noctalia to work correctly:

```kdl
window-rule {
  geometry-corner-radius 20
  clip-to-geometry true
}

debug {
  honor-xdg-activation-with-invalid-serial
}
```

## Noctalia Wallpaper (choose one)

**Option A — Blurred overview background (recommended):**
```kdl
layer-rule {
  match namespace="^noctalia-overview*"
  place-within-backdrop true
}
```

**Option B — Stationary wallpaper:**
```kdl
layer-rule {
  match namespace="^noctalia-wallpaper*"
  place-within-backdrop true
}

layout {
  background-color "transparent"
}

overview {
  workspace-shadow {
    off
  }
}
```

**Option C — Flat color (simplest):**
```kdl
overview {
  backdrop-color "#26233a"
}
```

## Qt Theming

`adwaita-qt` and `adwaita-qt6` dropped from Fedora 39+. Use `qt6ct` instead.

Set env var in niri config block:

```kdl
environment {
    QT_QPA_PLATFORMTHEME "qt6ct"
}
```

After first login, run `qt6ct` and apply the Noctalia color scheme: **Settings → Color Scheme → Templates → enable Qt**.

Qt5 apps won't pick up `qt6ct` — they need `qt5ct`. Since only one value can be set globally, run specific Qt5 apps with the var overridden: `QT_QPA_PLATFORMTHEME=qt5ct <app>`. Install `qt5ct` first if needed.

Noctalia (Quickshell/QML) is unaffected — styles itself independently.

## Dark Mode

Three layers needed for all apps to honour dark mode:

**1. GTK3 apps** — theme name drives it:
```bash
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
```

**2. GTK4 apps + portal-aware apps** — color-scheme drives it:
```bash
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
```

Both gsettings commands require a running dbus session (not available from TTY). The install script registers an autostart entry that runs them once on first niri login, then deletes itself.

**3. Qt apps** — configure dark palette in `qt6ct` GUI after first login. Noctalia's own color scheme is the recommended palette.

> `adw-gtk3-theme` provides both `adw-gtk3` (light) and `adw-gtk3-dark` (dark) — install script installs it if available.

## Startup Applications

Remove default Waybar entry if present. Noctalia handles: bar, notifications, wallpaper, lock screen, night light — do not spawn these separately.

**Noctalia** — use this exact command (not just `noctalia-shell`):
```kdl
spawn-at-startup "qs" "-c" "noctalia-shell"
```

**Do NOT** also enable `noctalia.service` via systemd if using spawn-at-startup — two instances will launch. Pick one method. spawn-at-startup is simpler; systemd is more robust. Recommended: spawn-at-startup for now.

**polkit** — do NOT spawn via spawn-at-startup (race condition with session init). Use systemd instead:
```bash
systemctl --user enable --now polkit-gnome-authentication-agent-1 2>/dev/null || \
  systemctl --user enable --now polkit 2>/dev/null
```
If no systemd unit exists, fall back to spawn-at-startup as last resort:
```kdl
spawn-at-startup "/usr/libexec/polkit-gnome-authentication-agent-1"
```

## Portal Config

Create `~/.config/niri/niri-portals.conf`:

```ini
[preferred]
default=gnome;gtk;

[org.freedesktop.impl.portal.FileChooser]
default=gtk
```

> Prevents Nautilus being pulled in as file picker when xdg-desktop-portal-gnome is installed.

**Known issue — screencasting conflict:** `xdg-desktop-portal-gnome` and `xdg-desktop-portal-gtk` can conflict, breaking screencasting. If screencasting fails, manually restart portals:
```bash
systemctl --user stop xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk
systemctl --user start xdg-desktop-portal xdg-desktop-portal-gnome
```
This is a known niri issue ([#2399](https://github.com/niri-wm/niri/issues/2399)) — no permanent fix yet.

## ARM / Asahi / kmsro Devices

If display doesn't appear, specify render device explicitly:

```kdl
debug {
  render-drm-device "/dev/dri/renderD128"
}
```

## Session Start

From TTY:
```bash
niri-session
```

## Blur (Experimental)

Blur is still in development and requires a custom niri build. Skip for now.
