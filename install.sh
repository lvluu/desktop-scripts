#!/usr/bin/env bash
# Link bin/* into ~/.local/bin and install the menu launchers and autostart entries. Re-run after adding a script.
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin" APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$BIN" "$APPS"
for f in "$SRC"/bin/*; do ln -sfn "$f" "$BIN/$(basename "$f")"; done
find "$BIN" -maxdepth 1 -xtype l -lname "$SRC/bin/*" -delete  # scripts since removed or renamed
ICONS="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/scalable/apps"
mkdir -p "$ICONS"
for f in "$SRC"/icons/*.svg; do ln -sfn "$f" "$ICONS/$(basename "$f")"; done
gtk-update-icon-cache -q "${ICONS%/scalable/apps}" 2>/dev/null || true
for f in "$SRC"/applications/*.desktop; do sed "s|@BIN@|$BIN|g" "$f" >"$APPS/$(basename "$f")"; done
update-desktop-database "$APPS" 2>/dev/null || true
AUTOSTART="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
mkdir -p "$AUTOSTART"
for f in "$SRC"/autostart/*.desktop; do sed "s|@BIN@|$BIN|g" "$f" >"$AUTOSTART/$(basename "$f")"; done
echo "installed: $(ls "$SRC/bin" | tr '\n' ' ')"
