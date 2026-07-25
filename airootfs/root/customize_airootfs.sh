#!/usr/bin/env bash
# ============================================================================
# LinkOS — customize_airootfs.sh
# ----------------------------------------------------------------------------
# This script runs INSIDE the chroot during mkarchiso build, AFTER all packages
# from packages.x86_64 have been installed. It customizes the live environment
# and the skel directory that becomes the default user's home.
#
# Everything here is idempotent and safe to re-run on incremental builds.
# ============================================================================

set -euo pipefail

echo "::group::LinkOS airootfs customization"

# ─────────────────────────────────────────────────────────────────────────────
# 1. System identity
# ─────────────────────────────────────────────────────────────────────────────
echo "linkos" > /etc/hostname
cat > /etc/os-release <<'EOF'
NAME="LinkOS"
PRETTY_NAME="LinkOS (Arch-based)"
ID=linkos
ID_LIKE=arch
ANSI_COLOR="0;36"
HOME_URL="https://github.com/salom600/link"
DOCUMENTATION_URL="https://github.com/salom600/link/wiki"
SUPPORT_URL="https://github.com/salom600/link/issues"
BUG_REPORT_URL="https://github.com/salom600/link/issues"
LOGO=linkos
EOF

# Issue / motd
cat > /etc/issue <<'EOF'

  ╔═══════════════════════════════════════════════════════════╗
  ║                    Welcome to LinkOS                       ║
  ║          A modern, lightweight Arch Linux distro           ║
  ╚═══════════════════════════════════════════════════════════╝

  Default user:    linkos
  Default password: linkos

  To install LinkOS to disk, run:  sudo linkos-install
  Or click the desktop "Install LinkOS" icon.

EOF

# Locale + timezone
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us"        > /etc/vconsole.conf
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
echo "en_US.UTF-8 UTF-8"  > /etc/locale.gen
echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen
echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
echo "es_ES.UTF-8 UTF-8" >> /etc/locale.gen
echo "ar_SA.UTF-8 UTF-8" >> /etc/locale.gen
echo "fa_IR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# ─────────────────────────────────────────────────────────────────────────────
# 2. Create the default live user
# ─────────────────────────────────────────────────────────────────────────────
# Live user — non-root, with sudo, autologin on tty1.
echo "Creating default user 'linkos'..."
if ! id linkos &>/dev/null; then
    useradd -m -G wheel,lp,sys,audio,video,optical,storage,network,power,games -s /usr/bin/zsh linkos
    echo "linkos:linkos" | chpasswd
fi

# Sudo: wheel group can sudo without password (live environment)
echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/10-linkos-wheel
chmod 0440 /etc/sudoers.d/10-linkos-wheel

# Root password (also for debugging)
echo "root:linkos" | chpasswd

# ─────────────────────────────────────────────────────────────────────────────
# 3. Copy skel into the live user's home
# ─────────────────────────────────────────────────────────────────────────────
echo "Populating /home/linkos from /etc/skel..."
if [[ -d /etc/skel ]]; then
    cp -aT /etc/skel /home/linkos/
fi
chown -R linkos:linkos /home/linkos

# ─────────────────────────────────────────────────────────────────────────────
# 4. Enable systemd services
# ─────────────────────────────────────────────────────────────────────────────
echo "Enabling systemd services..."
# Use `|| true` for ALL service enables — if a service unit is missing (e.g.
# because the package providing it was renamed/removed), the build should
# continue, not fail. Critical services are listed first.
systemctl enable NetworkManager.service       || true
systemctl enable lightdm.service              || true
systemctl enable bluetooth.service            || true
systemctl enable systemd-timesyncd.service    || true
systemctl enable systemd-resolved.service     || true
systemctl enable systemd-oomd.service         || true
systemctl enable reflector.timer              || true
systemctl enable paccache.timer               || true
systemctl enable firewalld.service            || true
systemctl enable cups.service                 || true
systemctl enable tlp.service                  || true
systemctl enable ufw.service                  || true
systemctl enable auto-cpufreq.service         || true

# LightDM autologin for the live environment (no password prompt)
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/10-linkos-autologin.conf <<'EOF'
[Seat:*]
autologin-user=linkos
autologin-user-timeout=0
autologin-session=xfce
user-session=xfce
EOF

# Add linkos to autologin group (required by some DMs)
groupadd -f autologin
gpasswd -a linkos autologin || true

# ─────────────────────────────────────────────────────────────────────────────
# 5. TTY autologin (fallback if lightdm fails)
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin linkos %I $TERM
EOF

# ─────────────────────────────────────────────────────────────────────────────
# 6. Makefile-style initramfs preset tweaks
# ─────────────────────────────────────────────────────────────────────────────
# Ensure mkinitcpio includes the modules needed for NVIDIA/AMD live boot
if [[ -f /etc/mkinitcpio.conf ]]; then
    sed -i 's/^MODULES=().*/MODULES=(bcc vfat nls_cp437 nls_iso8859-1 loop nvme nvme-core nvidia amdgpu radeon i915 nouveau)/' \
        /etc/mkinitcpio.conf || true
fi

# ─────────────────────────────────────────────────────────────────────────────
# 7. chaotic-aur is already configured in /etc/pacman.conf (see repo's
#    pacman.conf). We just need to make sure the chaotic-mirrorlist file exists
#    inside the live environment. mkarchiso copies the build container's
#    /etc/pacman.d/chaotic-mirrorlist into the ISO's airootfs automatically
#    (because the chaotic-mirrorlist package was installed via `pacman -U`
#    earlier in the CI workflow). So there's nothing to do here.
#
#    NOTE: On the INSTALLED system (post-Calamares), the user will need to
#    re-install the chaotic-keyring + chaotic-mirrorlist packages manually
#    if they want to keep using chaotic-aur. This is documented in the
#    linkos-welcome.sh wizard.
# ─────────────────────────────────────────────────────────────────────────────
# (intentional no-op — kept as a placeholder for future customization)

# ─────────────────────────────────────────────────────────────────────────────
# 8. Flatpak — pre-add Flathub remote
# ─────────────────────────────────────────────────────────────────────────────
if command -v flatpak &>/dev/null; then
    flatpak remote-add --if-not-exists flathub \
        https://flathub.org/repo/flathub.flatpakrepo || true
fi

# ─────────────────────────────────────────────────────────────────────────────
# 9. Desktop: Create "Install LinkOS" launcher on the desktop
# ─────────────────────────────────────────────────────────────────────────────
mkdir -p /home/linkos/Desktop
cat > /home/linkos/Desktop/linkos-install.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Install LinkOS
Name[de]=LinkOS installieren
Name[es]=Instalar LinkOS
Name[fr]=Installer LinkOS
Name[fa]=نصب LinkOS
Name[ar]=تثبيت LinkOS
GenericName=System Installer
Comment=Install LinkOS to your hard drive
Comment[de]=LinkOS auf Ihrer Festplatte installieren
Comment[es]=Instalar LinkOS en su disco duro
Comment[fr]=Installer LinkOS sur votre disque dur
Exec=pkexec /usr/bin/calamares
Icon=calamares
Terminal=false
StartupNotify=true
Categories=Qt;System;Installer;
Keywords=calamares;system;installer;
EOF
chmod +x /home/linkos/Desktop/linkos-install.desktop
chown linkos:linkos /home/linkos/Desktop/linkos-install.desktop

# Also drop a desktop file for the welcome wizard
cat > /home/linkos/Desktop/linkos-welcome.desktop <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=LinkOS Welcome
GenericName=Welcome Wizard
Comment=Get started with LinkOS
Exec=/usr/local/bin/linkos-welcome.sh
Icon=linkos-welcome
Terminal=false
StartupNotify=true
Categories=System;Utility;
EOF
chmod +x /home/linkos/Desktop/linkos-welcome.desktop
chown linkos:linkos /home/linkos/Desktop/linkos-welcome.desktop

# ─────────────────────────────────────────────────────────────────────────────
# 10. Bootloader defaults
# ─────────────────────────────────────────────────────────────────────────────
# Make sure /etc/default/grub has sensible defaults (used by Calamares)
cat > /etc/default/grub <<'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="LinkOS"
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet nvidia_drm.modeset=1"
GRUB_CMDLINE_LINUX=""
GRUB_PRELOAD_MODULES="part_gpt part_msdos diskfilter rw"
GRUB_TERMINAL_INPUT=console
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_RECOVERY=true
GRUB_DISABLE_SUBMENU=y
GRUB_DISABLE_OS_PROBER=false
GRUB_ENABLE_CRYPTODISK=y
GRUB_THEME=/boot/grub/themes/linkos/theme.txt
EOF

# ─────────────────────────────────────────────────────────────────────────────
# 11. Make scripts executable
# ─────────────────────────────────────────────────────────────────────────────
chmod +x /usr/local/bin/*.sh 2>/dev/null || true
chmod +x /usr/local/bin/polybar-launch 2>/dev/null || true

# ─────────────────────────────────────────────────────────────────────────────
# 12. Clean up — strip manpages caches, docs, etc. to keep ISO small
# ─────────────────────────────────────────────────────────────────────────────
echo "Cleaning up to reduce ISO size..."
# Remove unused firmware blobs (keep GPU + common wifi)
# rm -rf /usr/lib/firmware/{amdgpu,mesa,radeon}  # NOT removed — needed for live GPU

# Clean pacman cache (keep only installed package versions)
yes | pacman -Scc --noconfirm >/dev/null 2>&1 || true

# Remove docs that bloat the ISO
find /usr/share/doc -type f -delete 2>/dev/null || true
find /usr/share/man -type f -name '*.gz' -delete 2>/dev/null || true
rm -rf /usr/share/info/* 2>/dev/null || true

# Remove localedb for unused locales (keep only generated ones)
# find /usr/share/locale -maxdepth 1 -type d \
#   ! -name 'en*' ! -name 'de*' ! -name 'fr*' ! -name 'es*' \
#   ! -name 'ar*' ! -name 'fa*' ! -name 'C*' ! -name 'locale*' \
#   -exec rm -rf {} + 2>/dev/null || true

# Truncate machine-id so installer regenerates it
echo "" > /etc/machine-id

# Remove SSH host keys (regenerated on first boot by sshd service)
rm -f /etc/ssh/ssh_host_* 2>/dev/null || true

echo "::endgroup::"
echo "✅ LinkOS airootfs customization complete."
