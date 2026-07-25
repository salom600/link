#!/usr/bin/env bash
# shellcheck disable=SC2034

# ============================================================================
# LinkOS - Profile definition for mkarchiso
# A modern, ultra-lightweight Arch Linux distribution for ex-Windows users
# and gamers. Uses custom XFCE + Polybar + Rofi with Fluent Dark theme.
# ============================================================================

# Image file name (without extensions)
iso_name="linkos"

# Publisher
iso_publisher="LinkOS Project <https://github.com/salom600/link>"

# Application URL
iso_application="LinkOS Live/Install Media"

# Version string (auto-incremented by CI; fallback to date)
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"

# Build architecture
arch=("x86_64")

# Use ZSTD for fast compression (vs xz) — saves ~30% build time at the cost of ~10% size.
# Critical for staying within the 6h GitHub Actions limit on free runners.
iso_label="LINKOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"

# Installer
install_dir="arch"

# Boot modes:
#   bios.syslinux.mbr      -> Legacy BIOS via ISOLINUX (MBR)
#   bios.syslinux.eltorito -> Legacy BIOS via ISOLINUX (El Torito)
#   uefi-x64.systemd-boot.esp -> UEFI via systemd-boot (ESP)
#   uefi-x64.systemd-boot.eltorito -> UEFI via El Torito
bootmodes=(
    "bios.syslinux.mbr"
    "bios.syslinux.eltorito"
    "uefi-x64.systemd-boot.esp"
    "uefi-x64.systemd-boot.eltorito"
)

# Kernel/initramfs pairs to embed
bootmodes_default=("uefi-x64.systemd-boot.esp")

# pacman configuration to use
pacman_conf="pacman.conf"

# AI root filesystem skeleton directory
airootfs_dir="airootfs"

# File permissions for the live environment
# Format: "<path> <mode> <owner> <group>"
file_permissions=(
    "/etc/shadow 0400 root root"
    "/etc/gshadow 0400 root root"
    "/root 0700 root root"
    "/etc/sudoers.d 0750 root root"
    "/usr/local/bin/linkos-setup.sh 0755 root root"
    "/usr/local/bin/install-gaming.sh 0755 root root"
    "/usr/local/bin/apply-theme.sh 0755 root root"
    "/usr/local/bin/linkos-welcome.sh 0755 root root"
    "/usr/local/bin/polybar-launch 0755 root root"
    "/etc/systemd/system/display-manager.service 0777 root root"
)
