# 🛠 Local Build (Without GitHub Actions)

If you want to build the ISO locally (faster, no time limit), you need an Arch Linux host.

---

## Prerequisites

### Option A — Arch Linux host (native)
```bash
sudo pacman -Syu --needed archiso git squashfs-tools dosfstools e2fsprogs mtools xorriso grub
```

### Option B — Any Linux with Docker
```bash
docker run --rm -it --privileged \
    -v "$(pwd):/work" \
    -w /work \
    archlinux:latest \
    bash -c "pacman -Syu --noconfirm archiso git squashfs-tools && mkarchiso -v -c zstd -w work -o out ./"
```

### Option C — VM with Arch (VirtualBox / VMware)
- Boot Arch live ISO
- `pacman -Sy archiso`
- `git clone https://github.com/salom600/link.git`
- `cd link && sudo mkarchiso -v -c zstd -w work -o out ./`

---

## Build Steps

```bash
# 1. Clone
git clone https://github.com/salom600/link.git
cd link

# 2. (Optional) Enable multilib + chaotic-aur manually
#    If not, the build still works — it just skips brave-bin / proton-ge-custom
sudo sed -i 's/^#\(\[multilib\]\)/\1/' /etc/pacman.conf
sudo sed -i 's/^#\(Include = \/etc\/pacman.d\/mirrorlist\)$/\1/' /etc/pacman.conf

# 3. Build (this takes 1–4 hours depending on your hardware)
sudo mkarchiso -v -c zstd -X compression-level=15 -w work -o out ./

# 4. Verify
ls -la out/
# → linkos-YYYY.MM.DD-x86_64.iso
# → linkos-YYYY.MM.DD-x86_64.iso.sha256

# 5. Test in QEMU (optional)
sudo pacman -S qemu-desktop
qemu-system-x86_64 -m 4G -enable-kvm -cdrom out/*.iso
```

---

## Iterative Development

The `work/` directory is reused between builds, so subsequent runs are much faster:

```bash
# First build (cold)
sudo mkarchiso -v -c zstd -w work -o out ./       # 1–4 hours

# Edit a config file, e.g. add a package
$EDITOR packages.x86_64

# Rebuild (warm) — rootfs cache is reused
sudo mkarchiso -v -c zstd -w work -o out ./       # 15–30 min

# To force a clean build (wipe cache)
sudo rm -rf work out
sudo mkarchiso -v -c zstd -w work -o out ./       # 1–4 hours
```

---

## Debugging Build Failures

### "package not found" errors
- Edit `pacman.conf` to enable `[multilib]`
- Add `[chaotic-aur]` block (see main `pacman.conf`)
- Refresh the keyring: `sudo pacman-key --init && sudo pacman-key --populate archlinux`

### "no space left on device"
- `work/` directory needs ~10 GB free
- `out/` directory needs ~3 GB free
- Total: 15+ GB free recommended

### Calamares test
After booting the ISO, test Calamares without installing:
```bash
sudo calamares -d    # debug mode, doesn't actually install
```

### Live environment logs
On the live ISO:
```bash
journalctl -b 0                  # full boot log
systemctl status lightdm         # display manager
~/.xprofile                      # X session startup
~/.config/polybar/launch.sh      # polybar launcher
```

---

## Customizing the ISO

### Add a package
Edit `packages.x86_64`:
```
# Add your package
my-package-name
```

### Change the wallpaper
Replace `airootfs/usr/share/backgrounds/linkos/linkos-wallpaper.jpg` (must be JPG, ~1920×1080)

### Change the theme
1. Install a new GTK theme: `sudo pacman -S <theme-name>`
2. Edit `airootfs/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml`:
   ```xml
   <property name="ThemeName" type="string" value="<theme-name>"/>
   ```

### Add a custom application
1. Create a `.desktop` file in `airootfs/usr/share/applications/`
2. Optionally add a desktop icon: `airootfs/etc/skel/Desktop/<app>.desktop`
3. Add the binary to `packages.x86_64` (if from official repos)

### Change default browser
Edit `airootfs/etc/skel/.bashrc` and `airootfs/etc/skel/.xprofile`:
```bash
export BROWSER=firefox    # was: brave
```
And in `airootfs/etc/calamares/modules/linkos-postinstall.conf`:
```
"-xdg-mime default firefox.desktop x-scheme-handler/http"
```
