# GOAL
Post-install bash script for Fedora minimal (TTY) that sets up Cinnamon + niri + Noctalia.

User logs in at TTY after Fedora minimal install, runs the script, then reboots into the display manager and selects the Niri session.

# Approach

## Script: install.sh
Single bash script. Phases:
1. Preflight checks (sudo, internet, Fedora)
2. Cinnamon Desktop group install (provides DM, PipeWire, polkit, GTK env)
3. Repos (avengemedia/danklinux COPR + terra)
4. Packages (niri-specific — Cinnamon-provided deps excluded)
5. Niri session file (write /usr/share/wayland-sessions/niri.desktop if missing)
6. Niri config (append to config.kdl, do not overwrite)
7. Portal config
8. System env (QT_QPA_PLATFORMTHEME)
9. GTK theme autostart
10. LGL optional tools
11. Banner with post-install instructions

Cinnamon provides the display manager (lightdm). Niri appears as a selectable session at the DM login screen.

## To Start niri
Reboot → log in at DM → select **Niri** session from session picker (gear/cog icon).

# Cinnamon
- Installed via `dnf5 group install cinnamon-desktop`
- Provides: lightdm, PipeWire + WirePlumber, polkit agent, gnome-keyring, gnome-menus, GTK env
- Cinnamon session remains available as fallback

# Niri
- Install via avengemedia/danklinux COPR
- Session file: /usr/share/wayland-sessions/niri.desktop — written by script if COPR doesn't ship it
- Config: append to default config.kdl, never overwrite
- Comment out spawn-at-startup "waybar" if present
- KDL parse errors silently prevent all spawns — always validate after editing

# Noctalia
- Install via terra repo
- Spawn: `qs -c noctalia-shell` via spawn-at-startup
- Handles: bar, notifications, wallpaper, lock screen, night light, launcher
- External deps: brightnessctl, ImageMagick, python3, git, cliphist

# Polkit
- Use Noctalia Polkit to keep in style with the theme. NEEDS TO BE ADDED SEE BELOW

# Xwayland-satellite no longer needs to be added as it's built into Niri as of 25.08 
- Needs to be removed frome script  >> xwayland-satellite spawned via spawn-at-startup in config.kdl- Required for X11/game compatibility

# Known Issues
- power-profiles-daemon conflicts with tuned-ppd — exclude from dnf install
- Display output config requires niri running — manual post-install step
- KDL syntax: scale must be float (1.0 not 1), strings need closing quotes

# To add Noctalia polkit once ins

```git clone --no-checkout --depth=1 --filter=blob:none https://github.com/noctalia-dev/noctalia-plugins.git
cd noctalia-plugins
git sparse-checkout set polkit-agent
git checkout```

destination needs to be placed in ~/.config/noctalia/plugins/ which might need to be created
