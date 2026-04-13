# App Architecture

## Overview

fednirinoc is a GTK3 install and configure app written in C.
Runs from Budgie on Fedora and guides the user through installing niri + Noctalia.

Budgie handles: login manager (GDM), PipeWire, polkit, portals, gnome-keyring.
fednirinoc only installs and configures what Budgie does not already provide.

## Environment

- **Base DE**: Budgie (Wayland-native, GTK4)
- **App framework**: GTK3
- **Language**: C
- **Build system**: Meson

## What Budgie Provides (not handled by app)

| Component | Provider |
|---|---|
| Login manager / greeter | GDM (built-in) |
| Session switching | GDM session dropdown |
| PipeWire | Budgie |
| Polkit agent | Budgie |
| xdg-desktop-portal | Budgie |
| gnome-keyring | Budgie |

## UI Structure

GtkApplicationWindow
└── GtkAssistant
    ├── Page 1: Welcome + preflight
    ├── Page 2: Repo setup
    ├── Page 3: Package install
    ├── Page 4: Niri config
    ├── Page 5: Portal config
    ├── Page 6: Display config
    └── Page 7: Complete

Each page:
- Label describing what will happen
- Apply button triggers the operation
- GtkTextView (scrolled) shows real-time command output
- Status indicator: pending / running / success / failed
- Forward button enabled only on success

## Pages Detail

**Page 1 — Welcome + preflight**
- Check sudo access
- Check internet
- Check Fedora version
- Check adw-gtk3-theme availability

**Page 2 — Repo setup**
- Enable `avengemedia/danklinux` COPR (niri)
- Install `terra-release` (Noctalia)

**Page 3 — Package install**
```
niri xwayland-satellite
noctalia-shell brightnessctl ImageMagick python3 git cliphist
adw-gtk3-theme
```
Flags: `--exclude=power-profiles-daemon --skip-broken`

**Page 4 — Niri config**
- Copy default config.kdl if absent
- Comment out `spawn-at-startup "waybar"`
- Append Noctalia required blocks (idempotent)
- Append `spawn-at-startup "xwayland-satellite"` (required for X11/gaming)
- Run `niri validate` after writing — abort page if parse error, show error output
- **Critical**: any KDL parse error silently prevents all spawn-at-startup from firing

**Page 5 — Portal config**
- Write `~/.config/niri/niri-portals.conf`
- Set FileChooser to gtk to avoid Nautilus

**Page 6 — Display config**
- Query connected outputs via `niri msg outputs` (requires niri running — run from within niri session, or defer)
- Present GtkComboBox of detected output names (e.g. Virtual-1, eDP-1, HDMI-A-1)
- Present GtkComboBox of available modes for selected output
- Scale input (default 1.0, must write as float)
- On Apply: write output block into config.kdl, then run `niri validate`
- Exact syntax:
```kdl
output "eDP-1" {
    mode "1920x1080@60.000"
    scale 1.0
    transform "normal"
}
```
- Rules: refresh rate must match exactly to 3 decimal places; scale must be float; no `position` needed for single monitor
- After writing: run `niri validate` and show result — block forward on error

**Page 7 — Complete**
- Summary of steps passed / warned / failed
- Log location
- Next steps:
```
Installation complete.

1. Log out of Budgie
2. At the login screen, click the session icon and select "Niri"
3. Log in — Noctalia will launch automatically
```

## Command Execution

`GSubprocess` with stdout+stderr merged, streamed async to GtkTextView.

```c
GSubprocess *proc = g_subprocess_new(
    G_SUBPROCESS_FLAGS_STDOUT_PIPE | G_SUBPROCESS_FLAGS_STDERR_MERGE,
    &error,
    "sudo", "dnf", "install", "-y", "niri",
    NULL
);
```

## Sudo Handling

App does not run as root. Privileged commands use `sudo`.
Preflight verifies `sudo -v` before any step runs.

## Step Struct

```c
typedef struct {
    const char  *title;
    const char  *description;
    const char **argv;
    gboolean     requires_sudo;
    gboolean     idempotent;
} FednirinocStep;
```

## Error Handling

- Per-step: show error, offer Retry or Skip
- Skip = warned (yellow), not failed (red)
- Final page: summary of all step states
- Log: `~/.local/share/fednirinoc/install.log`

## Project Structure

```
src/
  main.c
  window.c/h
  steps.c/h
  runner.c/h
  pages/
    welcome.c/h
    repos.c/h
    packages.c/h
    niri_config.c/h
    portals.c/h
    display_config.c/h
    complete.c/h
data/
  ui/
meson.build
```

## Dependencies

```
gtk+-3.0
gio-2.0
glib-2.0
```

```bash
sudo dnf install gtk3-devel glib2-devel meson ninja-build gcc
```

## Build

```bash
meson setup build
ninja -C build
./build/fednirinoc
```

## Key Design Decisions

- **GTK3** — compatible with both Budgie environment and adw-gtk3 theme
- **GtkAssistant** — built-in wizard, no custom nav needed
- **Budgie as base** — handles greeter, PipeWire, polkit — app scope is minimal
- **No threads** — GSubprocess async I/O on GLib main loop
- **No root** — sudo per command
- **Idempotent** — safe to re-run
- **Single binary** — no runtime deps beyond GTK3
