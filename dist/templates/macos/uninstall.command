#!/usr/bin/env bash
#
# ScriptScreen — macOS uninstaller. Double-click in Finder or run from Terminal.
# Keeps ~/whisper.cpp (large models) unless --purge is passed.
#
set -euo pipefail

APP_DIR="${SCRIPTSCREEN_HOME:-$HOME/Library/Application Support/ScriptScreen}"
WHISPER_DIR="$HOME/whisper.cpp"
LAUNCHER="$HOME/Applications/ScriptScreen.command"

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1
log() { echo "==> $*"; }

log "Removing app at $APP_DIR"
rm -rf "$APP_DIR"
log "Removing launcher $LAUNCHER"
rm -f "$LAUNCHER"

if [ "$PURGE" -eq 1 ]; then
    log "Removing whisper.cpp and models at $WHISPER_DIR (--purge)"
    rm -rf "$WHISPER_DIR"
else
    echo "==> Kept $WHISPER_DIR (whisper.cpp + models). Run with --purge to remove it."
fi

log "ScriptScreen uninstalled."
echo "    Note: Node.js (Homebrew) was left installed."
