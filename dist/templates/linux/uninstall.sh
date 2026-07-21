#!/usr/bin/env bash
#
# ScriptScreen — Linux uninstaller.
#
# Removes the app, launcher and menu entry. Whisper models live in
# ~/whisper.cpp and are kept by default (they are large and may be shared);
# pass --purge to remove them too.
#
set -euo pipefail

APP_DIR="${SCRIPTSCREEN_HOME:-$HOME/.local/share/scriptscreen}"
WHISPER_DIR="$HOME/whisper.cpp"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

log() { echo "==> $*"; }

log "Removing app at $APP_DIR"
rm -rf "$APP_DIR"

log "Removing launcher and desktop entry"
rm -f "$BIN_DIR/scriptscreen"
rm -f "$DESKTOP_DIR/scriptscreen.desktop"
update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true

if [ "$PURGE" -eq 1 ]; then
    log "Removing whisper.cpp and models at $WHISPER_DIR (--purge)"
    rm -rf "$WHISPER_DIR"
else
    echo "==> Kept $WHISPER_DIR (whisper.cpp + models). Run with --purge to remove it."
fi

log "ScriptScreen uninstalled."
echo "    Note: Node.js/npm and any system ffmpeg were left installed."
