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

# Build mode (just ISO, no netboot/bootstrap)
buildmodes=('iso')

# Boot modes (BIOS + UEFI dual boot)
# NOTE: Modern archiso (v60+) uses simplified names:
#   - 'bios.syslinux'        (was: bios.syslinux.mbr + bios.syslinux.eltorito)
#   - 'uefi.systemd-boot'    (was: uefi-x64.systemd-boot.esp + uefi-x64.systemd-boot.eltorito)
# The old names are deprecated and emit warnings.
bootmodes=(
    "bios.syslinux"
    "uefi.systemd-boot"
)

# ──────────────── Compression — ZSTD for fast squashfs ────────────────
# Default Arch uses xz (slow, ~3-4h). We use zstd -15 -T0 for ~60% speedup.
# NOTE: -Xbcj x86 is ONLY valid for xz compression — zstd doesn't support
# BCJ filters. mksquashfs will fail with 'Unrecognised compressor option -Xbcj'
# if we try to use it with zstd.
#   -comp zstd              : use zstd compressor
#   -Xcompression-level 15  : high ratio, still fast (1..22, default 15)
#   -b 1M                   : 1MB block size (good balance)
#   -T0                    : use all CPU cores (multi-threaded)
airootfs_image_type="squashfs"
airootfs_image_tool_options=(
    '-comp' 'zstd'
    '-Xcompression-level' '15'
    '-b' '1M'
    '-T0'
)

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
