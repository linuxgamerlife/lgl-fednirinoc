# Open Questions / Research Gaps

## Display Manager

- Does `cinnamon-desktop` group pull in `lightdm` or `gdm` on Fedora? Session picker UI differs between the two but `niri.desktop` location is the same either way.

## Noctalia First Launch

- Does Noctalia generate its config automatically on first launch?
- Are there env vars that must be set before `qs -c noctalia-shell` starts?

## Terra Repo

- Does `--nogpgcheck` still required or is a GPG key now available for terra?
- Confirm `$releasever` expands correctly on current Fedora version

## Niri COPR Package

- Does `avengemedia/danklinux` ship `/usr/share/wayland-sessions/niri.desktop`?
  - Script writes it if missing — but if COPR ships it, the script will skip and use theirs (check for conflicts)
- Default config.kdl location in the package?

## Noctalia Polkit Plugin

- Does the polkit-agent plugin require any additional config or env vars to activate within Noctalia?
- Confirm plugin is auto-loaded from `~/.config/noctalia/plugins/` on Noctalia start

## honor-xdg-activation-with-invalid-serial

- Is this actually needed for Noctalia app launching to work correctly?
- Currently commented out in config — test with and without
