# Install Sequence

Assumes: Fedora minimal install, boots to TTY, internet connected, logged in as regular user with sudo.

## Phase 1: Cinnamon Desktop Group (optional)

The script prompts before this phase. Answer `n` to skip if you already have a desktop environment installed.

```bash
sudo dnf5 group install -y cinnamon-desktop
sudo systemctl set-default graphical.target
```

Provides: lightdm (display manager), PipeWire + WirePlumber, polkit agent, gnome-keyring, gnome-menus, GTK environment. Niri + Noctalia layer on top as a selectable DM session.

> Fedora minimal defaults to `multi-user.target` — `set-default graphical.target` is required or the display manager won't start on reboot. Skipped automatically when Cinnamon install is declined.

## Phase 2: Repos

```bash
# niri COPR
sudo dnf copr enable avengemedia/danklinux

# Terra (Noctalia)
sudo dnf install -y --nogpgcheck \
  --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' \
  terra-release
```

## Phase 3: Packages

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
  qt6ct \
  cliphist \
  adw-gtk3-theme
```

> `power-profiles-daemon` excluded — conflicts with `tuned-ppd` on Fedora minimal.
> `pipewire`, `wireplumber`, `gnome-keyring`, `gnome-menus`, `mate-polkit` omitted — provided by Cinnamon group.

## Phase 4: Niri Session File

Check for `/usr/share/wayland-sessions/niri.desktop` — write it if the COPR didn't ship it:

```bash
sudo mkdir -p /usr/share/wayland-sessions
sudo tee /usr/share/wayland-sessions/niri.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=niri-session
Type=Application
DesktopNames=niri
EOF
```

This is what makes lightdm offer Niri as a selectable session.

## Phase 5: Niri Config

1. Create config dir: `mkdir -p ~/.config/niri`
2. Copy default config from niri package if none exists (do not overwrite)
3. Comment out `spawn-at-startup "waybar"` if present
4. Append fednirinoc block (idempotent — skip if already present)

Appended block:
```kdl
// fednirinoc — appended by install.sh
environment {
    QT_QPA_PLATFORMTHEME "qt6ct"
}
spawn-at-startup "qs" "-c" "noctalia-shell"
spawn-at-startup "xwayland-satellite"
spawn-at-startup "/usr/libexec/polkit-gnome-authentication-agent-1"

// Uncomment if apps fail to focus when launched via Noctalia
// debug {
//     honor-xdg-activation-with-invalid-serial
// }

// OUTPUT CONFIGURATION
// After first login run: niri msg outputs
// Note your output name and mode, then uncomment and edit below:
//
// output "eDP-1" {
//     mode "1920x1080@60.000"
//     scale 1.0
//     transform "normal"
// }
```

**KDL rules — parse errors silently prevent all spawns:**
- `scale` must be float: `1.0` not `1`
- `mode` string must have closing `"`
- `position x=0 y=0` not needed for single monitor

## Phase 6: Portal Config

```bash
mkdir -p ~/.config/xdg-desktop-portal
cat > ~/.config/xdg-desktop-portal/niri-portals.conf << 'EOF'
[preferred]
default=gnome;gtk;
org.freedesktop.impl.portal.Access=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.FileChooser=gtk;
EOF
```

## Phase 7: System Environment

```bash
echo 'QT_QPA_PLATFORMTHEME=qt6ct' | sudo tee -a /etc/environment
```

## Phase 8: GTK Theme Autostart

Write `~/.config/autostart/fednirinoc-gtk-theme.desktop` — fires once on first login, sets dark mode via gsettings, then deletes itself.

## Post-Install

Reboot → log in via display manager → select **Niri** from the session picker (gear/cog icon).

Display config (first login inside niri):
```bash
niri msg outputs
# Note output name and mode, edit ~/.config/niri/config.kdl
# Uncomment and fill the OUTPUT CONFIGURATION section
# scale must be float (e.g. 1.0)
```

## Known Issues

| Issue | Workaround |
|---|---|
| Screencasting broken | Restart portals: stop all 3, start portal + portal-gnome only |
| Suspend → red screen | Known niri+Fedora GPU bug. Avoid suspend. |
| Noctalia not launching | Run `niri validate` — config parse error kills all spawns |
| Two Noctalia instances | Only use spawn-at-startup, not systemd unit |
