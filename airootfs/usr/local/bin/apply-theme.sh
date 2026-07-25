#!/usr/bin/env bash
# ============================================================================
# LinkOS — apply-theme.sh
# Applies the Fluent Dark theme (Windows 11 look) to XFCE + GTK + Qt + icons.
# Run as the regular user — modifies ~/.config and ~/.gtkrc.
# ============================================================================

set -euo pipefail

USER_HOME="${HOME:-/home/$(whoami)}"
USER_CONFIG="${USER_HOME}/.config"

# ─────────────────────── GTK2 ───────────────────────
cat > "${USER_HOME}/.gtkrc-2.0" <<'EOF'
gtk-theme-name="Fluent-Dark"
gtk-icon-theme-name="Fluent-Dark"
gtk-font-name="Cascadia Code 10"
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintfull"
gtk-xft-rgba="rgb"
EOF

# ─────────────────────── GTK3 ───────────────────────
mkdir -p "${USER_CONFIG}/gtk-3.0"
cat > "${USER_CONFIG}/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Fluent-Dark
gtk-icon-theme-name=Fluent-Dark
gtk-font-name=Cascadia Code 10
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
EOF

# ─────────────────────── GTK4 ───────────────────────
mkdir -p "${USER_CONFIG}/gtk-4.0"
cp "${USER_CONFIG}/gtk-3.0/settings.ini" "${USER_CONFIG}/gtk-4.0/settings.ini"

# ─────────────────────── Qt ───────────────────────
mkdir -p "${USER_CONFIG}"
cat > "${USER_CONFIG}/Trolltech.conf" <<'EOF'
[Qt]
style=kvantum
font="Cascadia Code,10,-1,5,50,0,0,0,0,0"
EOF

# Qt5ct + Qt6ct config (use kvantum-dark)
mkdir -p "${USER_CONFIG}/qt5ct" "${USER_CONFIG}/qt6ct"
cat > "${USER_CONFIG}/qt5ct/qt5ct.conf" <<'EOF'
[Appearance]
style=kvantum
icon_theme=Fluent-Dark
EOF
cp "${USER_CONFIG}/qt5ct/qt5ct.conf" "${USER_CONFIG}/qt6ct/qt6ct.conf"

# ─────────────────────── Kvantum ───────────────────────
mkdir -p "${USER_CONFIG}/Kvantum"
cat > "${USER_CONFIG}/Kvantum/kvantum.kvconfig" <<'EOF'
[General]
theme=Fluent-Dark
EOF

# ─────────────────────── Xfce xfconf ───────────────────────
mkdir -p "${USER_CONFIG}/xfce4/xfconf/xfce-perchannel-xml"
# Apply the bundled xfconf XML files (already in /etc/skel/.config/xfce4)
# We re-apply them in case the user's xfconf was already populated.
for f in xsettings.xml xfce4-panel.xml xfwm4.xml xfce4-desktop.xml thunar.xml; do
    src="/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/${f}"
    dst="${USER_CONFIG}/xfce4/xfconf/xfce-perchannel-xml/${f}"
    [[ -f "$src" ]] && cp "$src" "$dst"
done

# ─────────────────────── Cursor ───────────────────────
mkdir -p "${USER_CONFIG}/.icons/default"
cat > "${USER_CONFIG}/.icons/default/index.theme" <<'EOF'
[Icon Theme]
Inherits=Fluent-Dark
EOF

# ─────────────────────── Xresources ───────────────────────
cat > "${USER_HOME}/.Xresources" <<'EOF'
! Xft
Xft.antialias: true
Xft.hinting: true
Xft.hintstyle: hintfull
Xft.rgba: rgb
Xft.dpi: 96

! Cursor
Xcursor.theme: Fluent-Dark
Xcursor.size: 24

! URxvt
URxvt.font: xft:Cascadia Code:size=11
URxvt.background: #1f1f1f
URxvt.foreground: #e6e6e6
EOF

# ─────────────────────── Wallpaper ───────────────────────
# Apply the bundled wallpaper if available
WALLPAPER="/usr/share/backgrounds/linkos/linkos-wallpaper.jpg"
if [[ -f "$WALLPAPER" ]]; then
    # Use xfconf-query to set wallpaper (per workspace)
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$WALLPAPER" 2>/dev/null || true
    xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-style -s 5 2>/dev/null || true
fi

echo "✅ Fluent Dark theme applied."

# Reload xfce panels if xfce4-panel is running
if pgrep -x xfce4-panel &>/dev/null; then
    xfce4-panel -r 2>/dev/null || true
fi
