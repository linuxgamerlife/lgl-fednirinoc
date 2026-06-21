# GOAL
Post-install bash script for Fedora minimal (TTY) that sets up Cinnamon + niri + Noctalia.

User logs in at TTY after Fedora minimal install, runs the script, then reboots into the display manager and selects the Niri session.

# Approach

## Script: install.sh
Single bash script. Phases:
1. Cinnamon Desktop prompt
2. Preflight checks (sudo, internet, Fedora)
3. DNF configuration
4. Optional Cinnamon Desktop group install (provides DM, PipeWire, polkit, GTK env)
5. Display manager install/enable (lightdm)
6. Repos (avengemedia/danklinux COPR + lionheartp/Hyprland COPR)
7. Core packages
8. Noctalia v5 beta via `noctalia-git` from lionheartp/Hyprland
9. Niri session file (write /usr/share/wayland-sessions/niri.desktop if missing)
10. Niri config (append to config.kdl, do not overwrite)
11. Portal config
12. System env (QT_QPA_PLATFORMTHEME)
13. GTK theme autostart
14. LGL optional tools
15. Banner with post-install instructions

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
- Install v5 beta (`noctalia-git`) via lionheartp/Hyprland
- Spawn: `noctalia` via spawn-at-startup
- Handles: bar, notifications, wallpaper, lock screen, night light, launcher
- External deps: brightnessctl, ImageMagick, python3, git, cliphist

# Polkit
- Noctalia v5 has polkit built in. No plugin install required.

# Xwayland-satellite no longer needs to be added as it's built into Niri as of 25.08 
- Needs to be removed frome script  >> xwayland-satellite spawned via spawn-at-startup in config.kdl- Required for X11/game compatibility

# Known Issues
- power-profiles-daemon conflicts with tuned-ppd — exclude from dnf install
- Display output config requires niri running — manual post-install step
- KDL syntax: scale must be float (1.0 not 1), strings need closing quotes
