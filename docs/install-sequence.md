# Install Sequence

Assumes: Fedora minimal install, boots to TTY, internet connected, logged in as regular user with sudo.

## Phase 1: Repos

```bash
# niri COPR
sudo dnf copr enable avengemedia/danklinux

# Terra (Noctalia)
sudo dnf install -y --nogpgcheck \
  --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' \
  terra-release
```

## Phase 2: Packages

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
  gnome-keyring \
  lxqt-policykit \
  pipewire \
  pipewire-pulse \
  wireplumber \
  cliphist \
  adw-gtk3-theme
```

> `power-profiles-daemon` excluded — conflicts with `tuned-ppd` on Fedora minimal.

## Phase 3: Niri Config

1. Create config dir: `mkdir -p ~/.config/niri`
2. Copy default config from niri package if none exists (do not overwrite)
3. Comment out `spawn-at-startup "waybar"` if present
4. Append fednirinoc block (idempotent — skip if already present)

Appended block:
```kdl
// fednirinoc — appended by install.sh
spawn-at-startup "qs" "-c" "noctalia-shell"
spawn-at-startup "xwayland-satellite"
spawn-at-startup "/usr/bin/lxqt-policykit-agent"

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

## Phase 4: Portal Config

```bash
cat > ~/.config/niri/niri-portals.conf << 'EOF'
[preferred]
default=gnome;gtk;

[org.freedesktop.impl.portal.FileChooser]
default=gtk
EOF
```

## Phase 5: PipeWire User Session

```bash
sudo loginctl enable-linger $USER
# Symlink services to user default.target.wants
```

## Post-Install

```
Log in at TTY → type: niri-session
```

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
