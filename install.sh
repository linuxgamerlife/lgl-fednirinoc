#!/bin/bash
# fednirinoc v0.2.0
# Post-install script: Fedora minimal TTY -> Cinnamon + niri + Noctalia
# Installs Cinnamon Desktop group first (provides DM, PipeWire, polkit, GTK env),
# then layers niri + Noctalia on top as a selectable session in lightdm.
# Run as your regular user with sudo access.

set -euo pipefail

SCRIPT_USER="${USER}"
SCRIPT_HOME="${HOME}"
NIRI_CONFIG_DIR="${SCRIPT_HOME}/.config/niri"
NIRI_CONFIG="${NIRI_CONFIG_DIR}/config.kdl"
ADW_AVAILABLE=false
INSTALL_CINNAMON=true

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
# Cinnamon prompt
# ─────────────────────────────────────────────

ask_cinnamon() {
    echo ""
    echo "  ----------------------------------------------------------------"
    echo "          Cinnamon Desktop"
    echo "  ----------------------------------------------------------------"
    echo "  fednirinoc uses Cinnamon as its base desktop environment."
    echo "  It provides: lightdm, PipeWire, polkit, GTK env, and core deps."
    echo ""
    echo "  Skip this if you already have a desktop environment installed."
    echo "  ----------------------------------------------------------------"
    echo ""
    read -rp "  Install Cinnamon Desktop? [Y/n] " yn_cinnamon
    if [[ "${yn_cinnamon,,}" == "n" ]]; then
        INSTALL_CINNAMON=false
        info "Skipping Cinnamon install — existing DE assumed."
    else
        INSTALL_CINNAMON=true
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
# Phase 1: Cinnamon Desktop group
# ─────────────────────────────────────────────

install_cinnamon() {
    info "Installing Cinnamon Desktop group..."
    info "This provides: lightdm, PipeWire, polkit, GTK env, and core desktop deps."

    sudo dnf5 group install -y cinnamon-desktop

    sudo systemctl set-default graphical.target
    success "Default target set to graphical.target."

    success "Cinnamon Desktop group installed."
}

# ─────────────────────────────────────────────
# Phase 2: Repos
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
# Phase 3: Packages
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

        # Portals
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome

        # Qt theming (qt6ct — config tool for Qt6 apps; adwaita-qt/adwaita-qt6 dropped F39+)
        qt6ct
        # qt5ct  # uncomment if you have Qt5 apps that don't honour the Qt6 theme

        # Optional but integrated by Noctalia
        cliphist
        # power-profiles-daemon conflicts with tuned-ppd on Fedora minimal
        # tuned-ppd is already installed and provides the same ppd-service
    )

    if [[ "${ADW_AVAILABLE}" == "true" ]]; then
        PACKAGES+=(adw-gtk3-theme)
    fi

    sudo dnf install -y --exclude=power-profiles-daemon --skip-broken "${PACKAGES[@]}"
    success "Packages installed."
}

# ─────────────────────────────────────────────
# Phase 4: Niri session file
# ─────────────────────────────────────────────

ensure_niri_session_file() {
    info "Checking for niri wayland session file..."

    NIRI_SESSION="/usr/share/wayland-sessions/niri.desktop"

    if [[ -f "${NIRI_SESSION}" ]]; then
        success "niri.desktop already present — lightdm will offer Niri session."
        return
    fi

    warn "niri.desktop not found — writing manually so lightdm can see the session."

    sudo mkdir -p /usr/share/wayland-sessions
    sudo tee "${NIRI_SESSION}" > /dev/null << 'EOF'
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=niri-session
Type=Application
DesktopNames=niri
EOF

    success "Wrote ${NIRI_SESSION}"
}

# ─────────────────────────────────────────────
# Phase 5: Niri config
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

    # Append fednirinoc block (idempotent — skip if already present)
    if grep -q "# fednirinoc" "${NIRI_CONFIG}"; then
        info "fednirinoc config block already present — skipping append."
        return
    fi

    cat >> "${NIRI_CONFIG}" << 'EOF'

// ---------------------------------------------
// fednirinoc -- appended by install.sh v0.2.0
// ---------------------------------------------

// Qt theming — qt6ct reads ~/.config/qt6ct/qt6ct.conf (configure via: qt6ct)
// Qt5 apps won't pick this up — run them with: QT_QPA_PLATFORMTHEME=qt5ct <app>
environment {
    QT_QPA_PLATFORMTHEME "qt6ct"
}

// Noctalia shell
spawn-at-startup "qs" "-c" "noctalia-shell"

// Xwayland (required for X11/game compatibility)
spawn-at-startup "xwayland-satellite"

// Polkit agent — mate-polkit installed by Cinnamon Desktop group, provides polkit-gnome-authentication-agent-1
spawn-at-startup "/usr/libexec/polkit-gnome-authentication-agent-1"

// Uncomment if apps fail to focus when launched via Noctalia
// debug {
//     honor-xdg-activation-with-invalid-serial
// }

// OUTPUT CONFIGURATION
// After first login run: niri msg outputs
// Note your output name and mode, then uncomment and edit below, then:
//   niri msg action quit
//
// output "Virtual-1" {
//     mode "1920x1080@60.000"
//     scale 1.0
//     transform "normal"
// }

// # fednirinoc
EOF

    success "Appended niri config block."
}

# ─────────────────────────────────────────────
# Phase 6: Portal config
# ─────────────────────────────────────────────

configure_portals() {
    info "Writing portal config..."

    PORTAL_CONF="${SCRIPT_HOME}/.config/xdg-desktop-portal/niri-portals.conf"
    mkdir -p "${SCRIPT_HOME}/.config/xdg-desktop-portal"

    if [[ -f "${PORTAL_CONF}" ]]; then
        info "niri-portals.conf already exists — skipping."
        return
    fi

    cat > "${PORTAL_CONF}" << 'EOF'
[preferred]
default=gnome;gtk;
org.freedesktop.impl.portal.Access=gtk;
org.freedesktop.impl.portal.Notification=gtk;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.FileChooser=gtk;
EOF

    success "Portal config written."
}

# ─────────────────────────────────────────────
# Phase 7: System environment
# ─────────────────────────────────────────────

configure_system_env() {
    info "Writing system environment vars..."

    # Qt theme must be in /etc/environment so polkit agents and other
    # privileged/system-spawned Qt processes inherit it — niri's config.kdl
    # environment block is not always propagated outside the user session.
    ENV_FILE="/etc/environment"
    ENV_LINE='QT_QPA_PLATFORMTHEME=qt6ct'

    if grep -q "QT_QPA_PLATFORMTHEME" "${ENV_FILE}" 2>/dev/null; then
        info "QT_QPA_PLATFORMTHEME already set in ${ENV_FILE} — skipping."
    else
        echo "${ENV_LINE}" | sudo tee -a "${ENV_FILE}" > /dev/null
        success "Added ${ENV_LINE} to ${ENV_FILE}"
    fi
}

# ─────────────────────────────────────────────
# Phase 8: GTK theme
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
    AUTOSTART_FILE="${AUTOSTART_DIR}/fednirinoc-gtk-theme.desktop"

    mkdir -p "${AUTOSTART_DIR}"

    cat > "${AUTOSTART_FILE}" << EOF
[Desktop Entry]
Type=Application
Name=fednirinoc GTK theme setup
Exec=bash -c 'gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark && gsettings set org.gnome.desktop.interface color-scheme prefer-dark && rm -f ${AUTOSTART_FILE}'
X-GNOME-Autostart-enabled=true
EOF

    success "GTK theme autostart registered (runs once on first login)."
}

# ─────────────────────────────────────────────
# Phase 9: Optional LGL tools
# ─────────────────────────────────────────────

offer_lgl_tools() {
    echo ""
    echo "  ================================================================"
    echo "          Linux Gamer Life -- Optional Tools"
    echo "          Community tools from LGL, built for Fedora gamers."
    echo "          Both are optional -- skip either with 'n'."
    echo "  ================================================================"
    echo ""

    # ── LGL System Loadout ──────────────────────────────────────────────
    echo "  ----------------------------------------------------------------"
    echo "          LGL System Loadout"
    echo "  ----------------------------------------------------------------"
    echo "  A graphical setup wizard for Fedora. Browse and install curated"
    echo "  packages across gaming, multimedia, content creation, and dev --"
    echo "  nothing installs without your confirmation."
    echo "  https://github.com/linuxgamerlife/lgl-system-loadout"
    echo "  ----------------------------------------------------------------"
    echo ""
    read -rp "  Install LGL System Loadout? [y/N] " yn_loadout
    if [[ "${yn_loadout,,}" == "y" ]]; then
        info "Installing LGL System Loadout..."
        sudo dnf copr enable -y linuxgamerlife/lgl-system-loadout
        sudo dnf install -y lgl-system-loadout
        success "LGL System Loadout installed."
    else
        info "Skipping LGL System Loadout."
    fi

    echo ""

    # ── LGL SCX Scheduler Manager ────────────────────────────────────────
    echo "  ----------------------------------------------------------------"
    echo "          LGL SCX Scheduler Manager"
    echo "  ----------------------------------------------------------------"
    echo "  A Qt6 GUI for managing sched-ext BPF CPU schedulers. Start, stop,"
    echo "  or switch schedulers with custom flags. Includes status monitor,"
    echo "  command log, and system tray integration."
    echo "  https://github.com/linuxgamerlife/lgl-scxctl-manager"
    echo "  ----------------------------------------------------------------"
    echo ""
    read -rp "  Install LGL SCX Scheduler Manager? [y/N] " yn_scx
    if [[ "${yn_scx,,}" == "y" ]]; then
        info "Installing LGL SCX Scheduler Manager..."
        sudo dnf copr enable -y linuxgamerlife/lgl-scxctl-manager
        sudo dnf install -y lgl-scxctl-manager
        success "LGL SCX Scheduler Manager installed."
    else
        info "Skipping LGL SCX Scheduler Manager."
    fi
}

# ─────────────────────────────────────────────
# Phase 10: Post-install banner + reboot prompt
# ─────────────────────────────────────────────

display_banner() {
    echo ""
    echo "================================================================"
    echo "  fednirinoc v0.2.0 -- Install Complete"
    echo "================================================================"
    echo ""
    echo "  TO START:"
    echo "    Reboot -> log in via the display manager -> select 'Niri'"
    echo "    from the session menu (gear/cog icon at login screen)."
    echo ""
    echo "  DISPLAY CONFIGURATION (after first login, inside niri):"
    echo "    1. Run: niri msg outputs"
    echo "    2. Note your output name (e.g. eDP-1) and mode"
    echo "       (e.g. 1920x1080@60.000)"
    echo "    3. Edit: ~/.config/niri/config.kdl"
    echo "    4. Find the OUTPUT CONFIGURATION section and uncomment:"
    echo ""
    echo "         output \"YOUR-OUTPUT-NAME\" {"
    echo "             mode \"WIDTHxHEIGHT@REFRESH\""
    echo "             scale 1.0"
    echo "             transform \"normal\""
    echo "         }"
    echo ""
    echo "    5. Restart niri: niri msg action quit"
    echo ""
    echo "  KNOWN ISSUE:"
    echo "    - Noctalia may not appear the first time you run Niri after first boot"
    echo "      Log back out, select Niri again, and it will start correctly."
    echo ""
    echo "================================================================"
    echo ""
    echo "  !! MAKE A NOTE OF THE ABOVE BEFORE REBOOTING !!"
    echo ""
    read -rp "  Reboot now? [y/N] " yn_reboot
    if [[ "${yn_reboot,,}" == "y" ]]; then
        sudo reboot
    else
        echo ""
        echo "  Reboot manually when ready: sudo reboot"
        echo ""
    fi
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

main() {
    echo ""
    echo "  fednirinoc v0.2.0 -- Fedora minimal -> Cinnamon + niri + Noctalia"
    echo "  ------------------------------------------------------------------"
    echo ""

    ask_cinnamon
    preflight
    if [[ "${INSTALL_CINNAMON}" == "true" ]]; then
        install_cinnamon
    fi
    setup_repos
    install_packages
    ensure_niri_session_file
    configure_niri
    configure_portals
    configure_system_env
    configure_gtk_theme
    offer_lgl_tools
    display_banner
}

main
