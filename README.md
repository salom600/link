# 🚀 LinkOS

A modern, ultra-lightweight Arch Linux distribution designed for **ex-Windows users** and **gamers**, with a Windows 11 / macOS-inspired look (Fluent Dark theme + rounded corners + acrylic blur) and one-click Calamares installer.

[![Build ISO](https://github.com/salom600/link/actions/workflows/build.yml/badge.svg)](https://github.com/salom600/link/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/salom600/link?include_prereleases)](https://github.com/salom600/link/releases)
[![License](https://img.shields.io/badge/license-GPLv3-blue)](LICENSE)

---

## 📊 Specifications

| Spec | Target |
|---|---|
| **Idle RAM** | < 200 MB |
| **Idle CPU** | < 2% |
| **ISO size** | 2.5–3.5 GB |
| **Build time (CI)** | 1.5–4 hours (within GitHub Actions 6-hour free-tier limit) |
| **Architectures** | x86_64 (BIOS + UEFI) |
| **Base** | Arch Linux |
| **Desktop** | Custom XFCE (no GNOME bloat) |
| **Panel** | Polybar (top) + bottom dock |
| **Launcher** | Rofi (Super+Space) |
| **Compositor** | Picom (rounded corners + acrylic blur) |
| **Theme** | Fluent Dark (Windows 11 look) |
| **Installer** | Calamares (one-click GUI) |
| **Browser** | Brave (default) + Firefox |
| **Gaming** | Steam, Wine, Proton-GE, Lutris, Heroic, gamemode, MangoHud, gamescope |

---

## 🗂 Repository Structure

```
link/
├── .github/
│   └── workflows/
│       └── build.yml                 # CI/CD pipeline (6-hour timeout, layer caching)
├── airootfs/                          # Live environment + Calamares configs
│   ├── root/
│   │   └── customize_airootfs.sh      # Post-install customization script
│   ├── etc/
│   │   ├── calamares/                 # Calamares installer configs
│   │   │   ├── settings.conf
│   │   │   └── modules/
│   │   │       ├── welcome.conf
│   │   │       ├── partition.conf
│   │   │       ├── mount.conf
│   │   │       ├── unpackfs.conf
│   │   │       ├── machineid.conf
│   │   │       ├── fstab.conf
│   │   │       ├── locale.conf
│   │   │       ├── keyboard.conf
│   │   │       ├── users.conf
│   │   │       ├── displaymanager.conf
│   │   │       ├── networkcfg.conf
│   │   │       ├── services-systemd.conf
│   │   │       ├── packages.conf
│   │   │       ├── packages-remove-live.conf
│   │   │       ├── grubcfg.conf
│   │   │       ├── bootloader.conf
│   │   │       ├── initramfs.conf
│   │   │       ├── luksbootkeyfile.conf
│   │   │       ├── luksopenswaphook.conf
│   │   │       ├── finished.conf
│   │   │       ├── hwclock.conf
│   │   │       ├── preservefiles.conf
│   │   │       ├── linkos-postinstall.conf
│   │   │       └── linkos-cleanup.conf
│   │   ├── lightdm/                   # Login manager
│   │   ├── skel/                      # Skeleton home dir (becomes /home/linkos)
│   │   │   └── .config/
│   │   │       ├── polybar/           # Top bar + bottom dock
│   │   │       ├── rofi/              # App launcher + power menu
│   │   │       ├── picom/             # Compositor (blur + corners)
│   │   │       ├── dunst/             # Notifications
│   │   │       └── xfce4/xfconf/      # XFCE theme settings
│   │   ├── hostname
│   │   ├── locale.conf
│   │   └── vconsole.conf
│   └── usr/
│       └── local/
│           └── bin/
│               ├── linkos-install     # Calamares wrapper
│               ├── linkos-welcome.sh  # First-boot wizard
│               ├── apply-theme.sh     # Fluent Dark applier
│               ├── install-gaming.sh  # Gaming stack installer
│               └── polybar-launch
├── efiboot/                           # UEFI boot (systemd-boot)
│   └── loader/
│       ├── loader.conf
│       └── entries/
│           ├── linkos.conf
│           ├── linkos-nvidia.conf
│           └── linkos-fallback.conf
├── isolinux/                          # BIOS boot (ISOLINUX)
│   └── isolinux.cfg
├── packages.x86_64                    # Pacman package list
├── pacman.conf                        # pacman config (with chaotic-aur + multilib)
├── profiledef.sh                      # archiso profile definition
├── docs/
│   ├── SETUP-GITHUB-SECRETS.md        # Step-by-step secrets guide
│   └── LOCAL-BUILD.md                 # Local build instructions
└── README.md
```

---

## 🔧 CI/CD Pipeline

The build is fully automated via `.github/workflows/build.yml`:

### Pipeline stages
1. **Bootstrap** — Arch container + pacman keyring + reflector mirror selection
2. **Layer cache 1** — `/var/cache/pacman/pkg` (keyed on package list hash)
3. **Layer cache 2** — `work/` directory (keyed on airootfs customizations)
4. **Install** — `archiso`, `github-cli`, `squashfs-tools`, etc.
5. **chaotic-aur** — pre-built AUR packages (saves 1–2h vs local compilation)
6. **Build ISO** — `mkarchiso -c zstd -X compression-level=15 -w work -o out ./`
7. **Checksums** — `sha256sum *.iso`
8. **Artifact upload** — ISO + checksum as Actions artifact (14-day retention)
9. **Release** — `gh release create` on every push to `main` (rolling nightly tag) and on every `v*` tag

### Why it fits in 6 hours
- **ZSTD compression** (vs default xz) — saves ~60% of squashfs time
- **chaotic-aur** pre-built packages for Brave, Proton-GE, Heroic — skips ~1.5h of AUR compilation
- **Pacman cache layer** — install phase drops from ~25 min → ~3 min on cache hits
- **`work/` dir cache** — incremental builds skip re-extracting base packages
- **`timeout-minutes: 350`** — 5h50m budget, 10m safety buffer

---

## 🚀 Quick Start

### For end users (when ISO is released)
1. Download the latest `linkos-*.iso` from [Releases](https://github.com/salom600/link/releases)
2. Flash to a USB drive (4 GB+):
   ```bash
   sudo dd if=linkos-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
   # Or use Rufus / BalenaEtcher on Windows
   ```
3. Boot from USB (BIOS or UEFI both work)
4. Login: `linkos` / `linkos`
5. Double-click **"Install LinkOS"** on the desktop → follow Calamares

### For maintainers (set up CI)
See **[docs/SETUP-GITHUB-SECRETS.md](docs/SETUP-GITHUB-SECRETS.md)** for the step-by-step guide to configuring GitHub Secrets and triggering the first build.

---

## 🎨 Theming

The Fluent Dark theme is applied via:
- **xsettings.xml** — GTK theme/icon/cursor/font
- **xfwm4.xml** — Window manager theme + Windows-style keybindings (Super+Left/Right for snapping)
- **xfce4-panel.xml** — Hidden by default (Polybar takes over)
- **polybar/config.ini** — Top bar (clock, workspaces, system tray) + bottom dock (app shortcuts)
- **rofi/config.rasi** — Fluent Dark app launcher (Super+Space)
- **picom.conf** — Rounded corners + dual-kawase blur (Windows 11 acrylic)
- **dunst/dunstrc** — Fluent Dark notification bubbles

Apply / re-apply with:
```bash
/usr/local/bin/apply-theme.sh
```

---

## 🎮 Gaming

Pre-installed:
- **Steam** — with Proton + Proton-GE custom
- **Lutris** — Windows game install scripts
- **Heroic Games Launcher** — Epic Games / GOG / Amazon Prime
- **Wine + Winetricks** — manual Windows apps
- **gamemode + MangoHud + gamescope** — performance boosters

GPU driver auto-detection:
```bash
/usr/local/bin/install-gaming.sh
```
Auto-detects NVIDIA / AMD / Intel and installs the right driver + 32-bit libraries.

---

## 📦 Default Credentials

| User | Password |
|---|---|
| `linkos` | `linkos` |
| `root` | `linkos` |

**⚠️ Change passwords immediately after install via:**
```bash
passwd
sudo passwd root
```

---

## 🛠 Local Build (No GitHub)

See **[docs/LOCAL-BUILD.md](docs/LOCAL-BUILD.md)**.

TL;DR (requires Arch Linux host):
```bash
sudo pacman -S archiso git
git clone https://github.com/salom600/link.git
cd link
sudo mkarchiso -v -c zstd -w work -o out ./
ls out/  # → linkos-YYYY.MM.DD-x86_64.iso
```

---

## 📝 License

GPLv3 — see [LICENSE](LICENSE) for details.

This project includes:
- Arch Linux packages (various licenses — see each package)
- Calamares installer (GPLv3)
- Fluent Dark GTK theme (GPLv3)
- picom (GPLv2/MPL2)

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b my-feature`
3. Commit: `git commit -m "feat: my feature"`
4. Push: `git push origin my-feature`
5. Open a Pull Request

CI will build a test ISO on the PR — download it from the Actions artifacts to test.

---

## 📚 Useful Links

- [Arch Wiki — archiso](https://wiki.archlinux.org/title/Archiso)
- [Calamares documentation](https://github.com/calamares/calamares/wiki)
- [chaotic-aur](https://aur.chaotic.cx/)
- [Proton GE releases](https://github.com/GloriousEggroll/proton-ge-custom/releases)
