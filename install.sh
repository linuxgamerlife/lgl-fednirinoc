#!/bin/bash
# fedirinoc v0.0.1
# Post-install script: Fedora minimal TTY -> niri + Noctalia
# Run as your regular user with sudo access.

set -euo pipefail

SCRIPT_USER="${USER}"
SCRIPT_HOME="${HOME}"
NIRI_CONFIG_DIR="${SCRIPT_HOME}/.config/niri"
NIRI_CONFIG="${NIRI_CONFIG_DIR}/config.kdl"
ADW_AVAILABLE=false

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

info()    { echo "  [INFO] $*"; }
success() { echo "  [ OK ] $*"; }
warn()    { echo "  [WARN] $*"; }
die()     { echo "  [FAIL] $*" >&2; exit 1; }

require_sudo() {
    if ! sudo -v 2>/dev/null; then
        die "sudo access required. Run as a regular user with sudo."
    fi
}

# ─────────────────────────────────────────────
# Preflight checks
# ─────────────────────────────────────────────

preflight() {
    info "Running preflight checks..."

    require_sudo

    # Must not be root
    if [[ "${EUID}" -eq 0 ]]; then
        die "Do not run as root. Run as your regular user."
    fi

    # Internet check
    if ! ping -c1 -W3 8.8.8.8 &>/dev/null; then
        die "No internet connection detected."
    fi

    # Fedora check
    if ! grep -q "Fedora" /etc/os-release 2>/dev/null; then
        die "This script is for Fedora only."
    fi

    # xwayland-satellite version check
    if command -v xwayland-satellite &>/dev/null; then
        XWS_VER=$(xwayland-satellite --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
        XWS_MAJOR=$(echo "$XWS_VER" | cut -d. -f1)
        XWS_MINOR=$(echo "$XWS_VER" | cut -d. -f2)
        if [[ "$XWS_MAJOR" -eq 0 && "$XWS_MINOR" -lt 7 ]]; then
            warn "xwayland-satellite ${XWS_VER} found — need >= 0.7 for niri auto-integration."
            warn "Will install/upgrade from repos."
        fi
    fi

    # adw-gtk3-theme package name check
    if ! sudo dnf info adw-gtk3-theme &>/dev/null; then
        warn "adw-gtk3-theme not found in repos. GTK theming step will be skipped."
        ADW_AVAILABLE=false
    else
        ADW_AVAILABLE=true
    fi

    success "Preflight passed. User: ${SCRIPT_USER}, Home: ${SCRIPT_HOME}"
}

# ─────────────────────────────────────────────
# Phase 1: Repos
# ─────────────────────────────────────────────

setup_repos() {
    info "Enabling repos..."

    # niri COPR (avengemedia/danklinux — niri moved here from avengemedia/dms)
    if ! sudo dnf copr list --enabled 2>/dev/null | grep -q "avengemedia/danklinux"; then
        sudo dnf copr enable -y avengemedia/danklinux
        success "Enabled COPR: avengemedia/danklinux"
    else
        info "COPR avengemedia/danklinux already enabled."
    fi

    # Terra (Noctalia)
    if ! rpm -q terra-release &>/dev/null; then
        sudo dnf install -y --nogpgcheck \
            --repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" \
            terra-release
        success "Installed terra-release"
    else
        info "terra-release already installed."
    fi

    sudo dnf makecache -q
    success "Repos configured."
}

# ─────────────────────────────────────────────
# Phase 2: Packages
# ─────────────────────────────────────────────

install_packages() {
    info "Installing packages..."

    PACKAGES=(
        # Core compositor + xwayland
        niri
        xwayland-satellite

        # Noctalia shell + runtime deps
        noctalia-shell
        brightnessctl
        ImageMagick
        python3
        git

        # Greeter
        greetd
        greetd-selinux
        tuigreet

        # Portals
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
        gnome-keyring

        # Session essentials (polkit-gnome removed in F41+, mate-polkit is GTK equivalent)
        mate-polkit
        pipewire
        pipewire-pulse
        wireplumber

        # Optional but integrated by Noctalia
        cliphist
        power-profiles-daemon
    )

    if [[ "${ADW_AVAILABLE}" == "true" ]]; then
        PACKAGES+=(adw-gtk3-theme)
    fi

    sudo dnf install -y "${PACKAGES[@]}"
    success "Packages installed."
}

# ─────────────────────────────────────────────
# Phase 3: Niri config
# ─────────────────────────────────────────────

configure_niri() {
    info "Configuring niri..."

    mkdir -p "${NIRI_CONFIG_DIR}"

    # Copy default config if none exists
    if [[ ! -f "${NIRI_CONFIG}" ]]; then
        DEFAULT_CONFIG=$(rpm -ql niri 2>/dev/null | grep "default-config.kdl" | head -1)
        if [[ -n "${DEFAULT_CONFIG}" && -f "${DEFAULT_CONFIG}" ]]; then
            cp "${DEFAULT_CONFIG}" "${NIRI_CONFIG}"
            info "Copied default config from ${DEFAULT_CONFIG}"
        else
            # Fallback: create minimal stub
            touch "${NIRI_CONFIG}"
            warn "No default config found in niri package. Created empty config.kdl."
        fi
    else
        info "config.kdl already exists — leaving untouched, appending only."
    fi

    # Comment out spawn-at-startup "waybar" if present
    if grep -q '^spawn-at-startup "waybar"' "${NIRI_CONFIG}"; then
        sed -i 's|^spawn-at-startup "waybar"|// spawn-at-startup "waybar"  // disabled: Noctalia replaces waybar|' "${NIRI_CONFIG}"
        success "Commented out waybar spawn."
    else
        info "No active waybar spawn found."
    fi

    # Append fedirinoc block (idempotent — skip if already present)
    if grep -q "# fedirinoc" "${NIRI_CONFIG}"; then
        info "fedirinoc config block already present — skipping append."
        return
    fi

    cat >> "${NIRI_CONFIG}" << 'EOF'

// ─────────────────────────────────────────────
// fedirinoc — appended by install.sh v0.0.1
// ─────────────────────────────────────────────

// Noctalia shell
spawn-at-startup "qs" "-c" "noctalia-shell"

// Polkit agent (mate-polkit, polkit-gnome removed in F41+)
spawn-at-startup "/usr/libexec/polkit-mate-authentication-agent-1"

// Noctalia required: rounded corners
window-rule {
    geometry-corner-radius 20
    clip-to-geometry true
}

// Noctalia required: xdg-activation fix
debug {
    honor-xdg-activation-with-invalid-serial
}

// Noctalia wallpaper integration (blurred overview)
layer-rule {
    match namespace="^noctalia-overview*"
    place-within-backdrop true
}

// OUTPUT CONFIGURATION
// After first login run: niri msg outputs
// Note your output name and mode, then uncomment and edit below, then:
//   niri msg action quit   (greetd will restart the session)
//
// output "eDP-1" {
//     mode "1920x1080@60.000"
//     scale 1.0
//     transform "normal"
// }

// # fedirinoc
EOF

    success "Appended niri config block."
}

# ─────────────────────────────────────────────
# Phase 4: Portal config
# ─────────────────────────────────────────────

configure_portals() {
    info "Writing portal config..."

    PORTAL_CONF="${NIRI_CONFIG_DIR}/niri-portals.conf"

    if [[ -f "${PORTAL_CONF}" ]]; then
        info "niri-portals.conf already exists — skipping."
        return
    fi

    cat > "${PORTAL_CONF}" << 'EOF'
[preferred]
default=gnome;gtk;

[org.freedesktop.impl.portal.FileChooser]
default=gtk
EOF

    success "Portal config written."
}

# ─────────────────────────────────────────────
# Phase 5: GTK theme
# ─────────────────────────────────────────────

configure_gtk_theme() {
    if [[ "${ADW_AVAILABLE}" != "true" ]]; then
        warn "Skipping GTK theme — adw-gtk3-theme not available."
        return
    fi

    info "Applying GTK theme..."

    # gsettings needs a dbus session — write an autostart script instead
    # that runs once on first login, then removes itself
    AUTOSTART_DIR="${SCRIPT_HOME}/.config/autostart"
    AUTOSTART_FILE="${AUTOSTART_DIR}/fedirinoc-gtk-theme.desktop"

    mkdir -p "${AUTOSTART_DIR}"

    cat > "${AUTOSTART_FILE}" << EOF
[Desktop Entry]
Type=Application
Name=fedirinoc GTK theme setup
Exec=bash -c 'gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3 && rm -f ${AUTOSTART_FILE}'
X-GNOME-Autostart-enabled=true
EOF

    success "GTK theme autostart registered (runs once on first login)."
}

# ─────────────────────────────────────────────
# Phase 6: Greeter
# ─────────────────────────────────────────────

configure_greeter() {
    info "Configuring greetd + tuigreet..."

    # Write greetd config
    sudo tee /etc/greetd/config.toml > /dev/null << 'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --sessions /usr/share/wayland-sessions --asterisks"
user = "greeter"
EOF

    # Permissions
    sudo chmod -R go+r /etc/greetd
    success "greetd config written."

    # SELinux policy
    info "Applying greetd SELinux policy..."
    sudo semanage fcontext -a -ff -t xdm_exec_t /usr/bin/greetd 2>/dev/null || \
        sudo semanage fcontext -m -t xdm_exec_t /usr/bin/greetd 2>/dev/null || \
        warn "semanage fcontext failed — SELinux may block greetd. Check audit.log."
    sudo restorecon /usr/bin/greetd
    success "SELinux context applied."

    # niri.desktop session file
    WAYLAND_SESSIONS="/usr/share/wayland-sessions"
    NIRI_DESKTOP="${WAYLAND_SESSIONS}/niri.desktop"
    sudo mkdir -p "${WAYLAND_SESSIONS}"

    if [[ ! -f "${NIRI_DESKTOP}" ]]; then
        warn "niri.desktop not found — creating fallback."
        sudo tee "${NIRI_DESKTOP}" > /dev/null << 'EOF'
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=niri-session
Type=Application
EOF
        success "Created ${NIRI_DESKTOP}"
    else
        success "niri.desktop already present."
    fi

    # Enable greetd + force correct systemd target wiring
    sudo systemctl enable greetd
    sudo ln -sf /usr/lib/systemd/system/greetd.service \
        /etc/systemd/system/multi-user.target.wants/greetd.service
    sudo systemctl daemon-reload
    success "greetd enabled and wired to multi-user.target."

    # Disable other display managers if present
    for DM in gdm sddm lightdm; do
        if systemctl is-enabled "${DM}" &>/dev/null; then
            sudo systemctl disable "${DM}"
            warn "Disabled existing display manager: ${DM}"
        fi
    done
}

# ─────────────────────────────────────────────
# Phase 7: PipeWire user session
# ─────────────────────────────────────────────

configure_pipewire() {
    info "Enabling PipeWire user services..."

    # These need a running user session — use loginctl enable-linger
    # so user services activate at boot even before login
    sudo loginctl enable-linger "${SCRIPT_USER}"

    # Drop .wants symlinks manually since systemctl --user may not work from TTY
    USER_SYSTEMD="${SCRIPT_HOME}/.config/systemd/user"
    mkdir -p "${USER_SYSTEMD}/default.target.wants"

    for SVC in pipewire.service pipewire-pulse.service wireplumber.service; do
        UNIT_PATH=$(systemctl --user show -p FragmentPath "${SVC}" 2>/dev/null \
            | cut -d= -f2 || true)
        if [[ -z "${UNIT_PATH}" ]]; then
            # Fallback paths
            for DIR in /usr/lib/systemd/user /usr/share/systemd/user; do
                if [[ -f "${DIR}/${SVC}" ]]; then
                    UNIT_PATH="${DIR}/${SVC}"
                    break
                fi
            done
        fi
        if [[ -n "${UNIT_PATH}" && -f "${UNIT_PATH}" ]]; then
            ln -sf "${UNIT_PATH}" "${USER_SYSTEMD}/default.target.wants/${SVC}"
            success "Enabled ${SVC}"
        else
            warn "Could not find unit file for ${SVC} — enable manually after first login:"
            warn "  systemctl --user enable --now ${SVC}"
        fi
    done
}

# ─────────────────────────────────────────────
# Phase 8: Display config banner
# ─────────────────────────────────────────────

display_banner() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║         fedirinoc v0.0.1 — Install Complete                  ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║                                                              ║"
    echo "║  MANUAL STEP REQUIRED: Display Configuration                 ║"
    echo "║                                                              ║"
    echo "║  After first login, open a terminal and run:                 ║"
    echo "║    niri msg outputs                                          ║"
    echo "║                                                              ║"
    echo "║  Note your output name (e.g. eDP-1) and mode                ║"
    echo "║  (e.g. 1920x1080@60.000), then edit:                        ║"
    echo "║    ~/.config/niri/config.kdl                                 ║"
    echo "║                                                              ║"
    echo "║  Find the OUTPUT CONFIGURATION section and uncomment:        ║"
    echo "║    output \"YOUR-OUTPUT-NAME\" {                               ║"
    echo "║      mode \"WIDTHxHEIGHT@REFRESH\"                            ║"
    echo "║      scale 1.0                                               ║"
    echo "║      transform \"normal\"                                      ║"
    echo "║    }                                                         ║"
    echo "║                                                              ║"
    echo "║  Then: niri msg action quit   (greetd restarts session)      ║"
    echo "║                                                              ║"
    echo "║  KNOWN ISSUES:                                               ║"
    echo "║  - Screencasting: restart portals if broken (see docs)       ║"
    echo "║  - Suspend may cause red screen — known niri+Fedora bug      ║"
    echo "║  - Do NOT pkill niri — use: niri msg action quit             ║"
    echo "║                                                              ║"
    echo "║  Reboot now to start greetd.                                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

main() {
    echo ""
    echo "  fedirinoc v0.0.1 — Fedora minimal -> niri + Noctalia"
    echo "  ────────────────────────────────────────────────────"
    echo ""

    preflight
    setup_repos
    install_packages
    configure_niri
    configure_portals
    configure_gtk_theme
    configure_greeter
    configure_pipewire
    display_banner
}

main
