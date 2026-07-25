#!/usr/bin/env bash
# ============================================================================
# LinkOS — linkos-welcome.sh
# First-boot welcome wizard. Shows a brief tour, offers to install NVIDIA
# drivers, set up the gaming stack, and apply Fluent Dark theme.
# ============================================================================

set -euo pipefail

APP_NAME="LinkOS Welcome"

# YAD / zenity detection
if command -v yad &>/dev/null; then
    GUI="yad"
elif command -v zenity &>/dev/null; then
    GUI="zenity"
else
    GUI=""
fi

show_info() {
    if [[ "$GUI" == "yad" ]]; then
        yad --info --title="$APP_NAME" --text="$1" --width=400 --height=200
    elif [[ "$GUI" == "zenity" ]]; then
        zenity --info --title="$APP_NAME" --text="$1"
    else
        echo "[INFO] $1"
    fi
}

show_question() {
    if [[ "$GUI" == "yad" ]]; then
        yad --question --title="$APP_NAME" --text="$1" --width=400
    elif [[ "$GUI" == "zenity" ]]; then
        zenity --question --title="$APP_NAME" --text="$1"
    else
        read -p "$1 [y/N]: " ans
        [[ "$ans" =~ ^[Yy] ]] && return 0 || return 1
    fi
}

# Main flow
cat << 'BANNER'
  ╔═══════════════════════════════════════════════════════════╗
  ║                  Welcome to LinkOS!                         ║
  ║                                                             ║
  ║  A modern, ultra-lightweight Arch-based distribution       ║
  ║  for ex-Windows users and gamers.                           ║
  ╚═══════════════════════════════════════════════════════════╝
BANNER

# 1. Theme check
if ! show_question "Apply Fluent Dark theme now? (Recommended for Windows-like UX)"; then
    if [[ -x /usr/local/bin/apply-theme.sh ]]; then
        /usr/local/bin/apply-theme.sh
        show_info "✅ Fluent Dark theme applied."
    fi
fi

# 2. Gaming setup
if show_question "Set up the gaming suite (Wine/Proton/Lutris/Steam)? Recommended for gamers."; then
    if [[ -x /usr/local/bin/install-gaming.sh ]]; then
        /usr/local/bin/install-gaming.sh
        show_info "✅ Gaming stack ready. Launch Lutris or Steam from the menu."
    fi
fi

# 3. NVIDIA driver prompt
if lspci | grep -qi 'vga.*nvidia\|3d controller.*nvidia'; then
    if show_question "NVIDIA GPU detected. Install proprietary NVIDIA drivers now?"; then
        sudo pacman -Sy --noconfirm --needed nvidia nvidia-utils nvidia-settings lib32-nvidia-utils
        show_info "✅ NVIDIA drivers installed. Reboot to activate."
    fi
fi

# 4. Flatpak setup
if command -v flatpak &>/dev/null; then
    if show_question "Add Flathub repository for Flatpak apps?"; then
        flatpak remote-add --user --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo
        show_info "✅ Flathub added. Install apps via 'bauh' or 'gnome-software'."
    fi
fi

# 5. Final tip
show_info "Tip: Right-click the desktop for settings. Polybar (top) shows system stats. Press Super+Space for Rofi app launcher."

echo "Welcome wizard finished."
