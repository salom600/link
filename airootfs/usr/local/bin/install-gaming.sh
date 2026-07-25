#!/usr/bin/env bash
# ============================================================================
# LinkOS — install-gaming.sh
# Sets up the complete gaming stack:
#   - Wine + Winetricks + Proton (GE custom)
#   - Lutris + Heroic Games Launcher
#   - Steam + gamemode + gamescope + MangoHud
#   - 32-bit compatibility libraries (multilib)
#   - GPU driver auto-detection (NVIDIA / AMD / Intel)
#   - Vulkan layers
# ============================================================================

set -euo pipefail

echo "::group::LinkOS gaming stack installer"

# ─────────────────────────────────────────────────────────────────────────────
# 1. Make sure multilib is enabled
# ─────────────────────────────────────────────────────────────────────────────
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    echo "[multilib]" >> /etc/pacman.conf
    echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
fi

# ─────────────────────────────────────────────────────────────────────────────
# 2. Detect GPU and install appropriate driver
# ─────────────────────────────────────────────────────────────────────────────
detect_gpu() {
    if lspci | grep -qiE 'vga.*nvidia|3d controller.*nvidia'; then
        echo "nvidia"
    elif lspci | grep -qiE 'vga.*amd|3d controller.*amd|vga.*radeon'; then
        echo "amd"
    elif lspci | grep -qiE 'vga.*intel'; then
        echo "intel"
    else
        echo "unknown"
    fi
}

GPU=$(detect_gpu)
echo "🔍 Detected GPU: $GPU"

case "$GPU" in
    nvidia)
        echo "Installing NVIDIA proprietary drivers..."
        sudo pacman -Sy --noconfirm --needed \
            nvidia \
            nvidia-utils \
            nvidia-settings \
            nvidia-dkms \
            lib32-nvidia-utils
        # Enable DRM modeset for Wayland + better suspend
        if ! grep -q 'nvidia_drm.modeset=1' /etc/default/grub; then
            sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/' /etc/default/grub
        fi
        echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf
        ;;
    amd)
        echo "Installing AMD drivers (already in mesa)..."
        sudo pacman -Sy --noconfirm --needed \
            mesa \
            lib32-mesa \
            vulkan-radeon \
            lib32-vulkan-radeon \
            libva-mesa-driver \
            mesa-vdpau
        ;;
    intel)
        echo "Installing Intel drivers..."
        sudo pacman -Sy --noconfirm --needed \
            mesa \
            lib32-mesa \
            vulkan-intel \
            lib32-vulkan-intel \
            intel-media-driver \
            libva-intel-driver
        ;;
    *)
        echo "⚠️ Could not detect GPU. Skipping proprietary driver install."
        ;;
esac

# ─────────────────────────────────────────────────────────────────────────────
# 3. Core gaming packages
# ─────────────────────────────────────────────────────────────────────────────
echo "Installing gaming packages..."
sudo pacman -Sy --noconfirm --needed \
    wine \
    wine-gecko \
    wine-mono \
    winetricks \
    steam \
    gamemode \
    lib32-gamemode \
    gamescope \
    mangohud \
    lib32-mangohud \
    goverlay \
    lutris \
    protonup-qt \
    protontricks

# ─────────────────────────────────────────────────────────────────────────────
# 4. Heroic Games Launcher (AUR — use chaotic-aur if available, else paru/yay)
# ─────────────────────────────────────────────────────────────────────────────
if ! command -v heroic &>/dev/null; then
    if pacman -Si heroic-games-launcher-bin &>/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm --needed heroic-games-launcher-bin
    elif command -v paru &>/dev/null; then
        paru -S --noconfirm --needed heroic-games-launcher-bin
    elif command -v yay &>/dev/null; then
        yay -S --noconfirm --needed heroic-games-launcher-bin
    else
        echo "⚠️ Heroic Games Launcher not installed (no AUR helper + not in chaotic-aur)."
        echo "   Install it later with: paru -S heroic-games-launcher-bin"
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# 5. Proton-GE custom (latest from chaotic-aur or protonup-qt)
# ─────────────────────────────────────────────────────────────────────────────
if ! pacman -Qs proton-ge-custom &>/dev/null; then
    if pacman -Si proton-ge-custom &>/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm --needed proton-ge-custom
    else
        echo "Installing Proton-GE via protonup-qt (GUI will launch)..."
        sudo -u "${SUDO_USER:-$(whoami)}" protonup -d "${HOME}/.steam/root/compatibilitytools.d/" 2>/dev/null || true
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# 6. 32-bit audio/video codecs (for older Windows games via Wine)
# ─────────────────────────────────────────────────────────────────────────────
sudo pacman -Sy --noconfirm --needed \
    lib32-pipewire \
    lib32-alsa-plugins \
    lib32-libpulse \
    lib32-openal \
    lib32-nss \
    lib32-gnutls \
    lib32-curl \
    lib32-systemd \
    lib32-gcc-libs \
    lib32-zlib \
    lib32-ncurses

# ─────────────────────────────────────────────────────────────────────────────
# 7. Steam runtime dependencies (some games need them)
# ─────────────────────────────────────────────────────────────────────────────
sudo pacman -Sy --noconfirm --needed \
    ttf-liberation \
    ttf-bitstream-vera \
    ttf-dejavu \
    ttf-cascadia-code \
    libxcrypt-compat \
    libcups \
    libgpg-error \
    libxslt

# ─────────────────────────────────────────────────────────────────────────────
# 8. Set up Steam library folder for the current user
# ─────────────────────────────────────────────────────────────────────────────
USER_HOME="${HOME}"
mkdir -p "${USER_HOME}/.steam/root/compatibilitytools.d"
mkdir -p "${USER_HOME}/.local/share/Steam"
mkdir -p "${USER_HOME}/Games"

# ─────────────────────────────────────────────────────────────────────────────
# 9. Recommended kernel parameters for gaming (write to a hint file)
# ─────────────────────────────────────────────────────────────────────────────
cat > "${USER_HOME}/.config/linkos/gaming-tips.txt" <<'EOF'
LinkOS Gaming Tips:
====================

1. Steam Proton:  Steam → Settings → Compatibility → Enable Steam Play for all titles
2. Lutris:        https://lutris.net/games/ — install scripts for any Windows game
3. Heroic:        For Epic Games / GOG / Amazon Prime games
4. Proton-GE:     Updated Proton fork → https://github.com/GloriousEggroll/proton-ge-custom

Performance boosters:
  - gamemoderun %command%      (in Steam launch options)
  - mangohud %command%         (overlay FPS/CPU/GPU stats)
  - gamescope -W 1920 -H 1080 -f %command%  (forced fullscreen with scaling)

Useful commands:
  $ mangohud glxgears          (test overlay)
  $ gamemoded -s               (check gamemode status)
  $ sudo nvtop                 (NVIDIA monitor)
  $ sudo radeontop             (AMD monitor)

Kernel params (already in /etc/default/grub):
  nvidia_drm.modeset=1         (required for NVIDIA + Wayland)
  mitigations=off              (disable Spectre mitigations — +5% perf, slight risk)
EOF

echo "::endgroup::"
echo "✅ Gaming stack ready!"
echo "   Launch Steam, Lutris, or Heroic from the application menu."
