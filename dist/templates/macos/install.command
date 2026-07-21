#!/usr/bin/env bash
#
# ScriptScreen — macOS installer.
#
# Double-click in Finder, or run from Terminal. Installs into your home folder
# only. Homebrew is used (and offered for install) when Node.js is missing.
#
# Options:
#   --models "<a> <b>"  Models to ensure are present (default: $SCRIPTSCREEN_MODELS
#                       or "small"). Missing ones are downloaded.
#   --log <file>        Write the install log to a custom file
#                       (default: ~/Library/Application Support/ScriptScreen/install.log).
#   --no-log            Do not write a log file.
#
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPTSCREEN_HOME:-$HOME/Library/Application Support/ScriptScreen}"
WHISPER_DIR="$HOME/whisper.cpp"
LAUNCHER="$HOME/Applications/ScriptScreen.command"

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*"; }

MODELS="${SCRIPTSCREEN_MODELS:-small}"
WANT_LOG=1
LOG_FILE=""
while [ $# -gt 0 ]; do
    case "$1" in
        --models) MODELS="${2:-}"; shift 2;;
        --log)
            WANT_LOG=1
            if [ $# -ge 2 ] && [ "${2#-}" = "$2" ]; then LOG_FILE="$2"; shift 2; else shift; fi
            ;;
        --no-log) WANT_LOG=0; shift;;
        -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
        *) die "unknown argument: $1";;
    esac
done

[ -d "$SRC_DIR/app" ] || die "run this from the unpacked archive (app/ not found)"

# Logging (on by default, --no-log disables): tee all output to a file too.
if [ "$WANT_LOG" -eq 1 ]; then
    [ -n "$LOG_FILE" ] || LOG_FILE="$APP_DIR/install.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    exec > >(tee -a "$LOG_FILE") 2>&1
    log "Logging to $LOG_FILE"
fi

# ---------------------------------------------------------------------------
# 1. Node.js + npm (via Homebrew)
# ---------------------------------------------------------------------------
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    if ! command -v brew >/dev/null 2>&1; then
        log "Homebrew not found — installing it (you may be prompted for your password)"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Make brew available in this shell (Apple Silicon vs Intel).
        [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
        [ -x /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"
    fi
    log "Installing Node.js via Homebrew"
    brew install node
fi
command -v node >/dev/null 2>&1 || die "Node.js still not available after install"
log "Using node $(node --version), npm $(npm --version)"

# ---------------------------------------------------------------------------
# 2. App + npm dependencies
# ---------------------------------------------------------------------------
log "Installing app to $APP_DIR"
mkdir -p "$APP_DIR"
cp -a "$SRC_DIR/app/." "$APP_DIR/"
log "Installing npm dependencies (downloads Electron — needs network)"
( cd "$APP_DIR" && npm install --omit=dev --no-audit --no-fund ) \
    || log "WARNING: npm install failed — retrying the Electron download below"

# The Electron binary is fetched from GitHub releases by a postinstall step.
# On networks where that download is blocked or reset, npm leaves
# node_modules/electron in place without the binary — and a plain re-run of
# npm install then skips the postinstall, so the tree never heals itself.
# Verify the binary and, if missing, retry the download through a mirror.
ELECTRON_PKG="$APP_DIR/node_modules/electron"
ELECTRON_BIN="$ELECTRON_PKG/dist/Electron.app/Contents/MacOS/Electron"
if [ ! -x "$ELECTRON_BIN" ]; then
    log "Electron binary missing (GitHub download failed?) — retrying via mirror"
    export ELECTRON_MIRROR="${ELECTRON_MIRROR:-https://npmmirror.com/mirrors/electron/}"
    if [ -f "$ELECTRON_PKG/install.js" ]; then
        ( cd "$ELECTRON_PKG" && node install.js ) || true
    else
        # npm rolled the tree back on failure — run the whole install again
        # with the mirror active so the postinstall fetches from it.
        ( cd "$APP_DIR" && npm install --omit=dev --no-audit --no-fund ) || true
    fi
    [ -x "$ELECTRON_BIN" ] \
        || die "Electron download failed even via mirror ($ELECTRON_MIRROR) — set ELECTRON_MIRROR to a reachable mirror and re-run"
fi

# ---------------------------------------------------------------------------
# 3. whisper.cpp + models -> ~/whisper.cpp
# ---------------------------------------------------------------------------
if [ -d "$SRC_DIR/whisper/build" ] || [ -d "$SRC_DIR/whisper/models" ]; then
    log "Installing whisper.cpp to $WHISPER_DIR"
    mkdir -p "$WHISPER_DIR"
    cp -a "$SRC_DIR/whisper/." "$WHISPER_DIR/"
    [ -f "$WHISPER_DIR/build/bin/whisper-cli" ]    && chmod +x "$WHISPER_DIR/build/bin/whisper-cli"
    [ -f "$WHISPER_DIR/build/bin/whisper-stream" ] && chmod +x "$WHISPER_DIR/build/bin/whisper-stream"
    # Clear Gatekeeper quarantine so the unsigned binaries can run.
    xattr -dr com.apple.quarantine "$WHISPER_DIR" 2>/dev/null || true
else
    log "WARNING: no whisper payload — transcription will not work until ~/whisper.cpp is populated"
fi

# ---------------------------------------------------------------------------
# 3a. SDL2 — required by whisper-stream (live transcription). The shipped
#     binaries link SDL2 dynamically, so install it via Homebrew if missing.
# ---------------------------------------------------------------------------
if [ -f "$WHISPER_DIR/build/bin/whisper-stream" ]; then
    bundled_sdl2="$(ls "$WHISPER_DIR/build/bin/"libSDL2*.dylib 2>/dev/null | head -1 || true)"
    if [ -n "$bundled_sdl2" ]; then
        log "SDL2 bundled with the binaries"
    elif command -v brew >/dev/null 2>&1; then
        brew list sdl2 >/dev/null 2>&1 && log "SDL2 already present" || { log "Installing SDL2 (needed for live transcription)"; brew install sdl2; }
    else
        log "WARNING: Homebrew not found — install SDL2 manually (brew install sdl2) for live transcription."
    fi
fi

# ---------------------------------------------------------------------------
# 3b. Ensure speech models are present — download any missing ones.
# ---------------------------------------------------------------------------
HF_BASE="https://huggingface.co/ggerganov/whisper.cpp/resolve/main"
download_model() {  # $1 = UI model name (as selected in ScriptScreen)
    local name="$1" remote="$1" dest="$WHISPER_DIR/models/ggml-$1.bin"
    [ -f "$dest" ] && { log "Model '$name' already present"; return; }
    [ "$name" = turbo ] && remote="large-v3-turbo"   # UI 'turbo' -> large-v3-turbo weights
    log "Downloading model '$name' (ggml-$remote.bin)"
    mkdir -p "$WHISPER_DIR/models"
    curl -fL "$HF_BASE/ggml-$remote.bin" -o "$dest.part" && mv "$dest.part" "$dest" \
        || { rm -f "$dest.part"; log "WARNING: failed to download model '$name'"; }
}
for m in $MODELS; do download_model "$m"; done

# ---------------------------------------------------------------------------
# 4. Bundled ffmpeg -> ~/whisper.cpp/bin
# ---------------------------------------------------------------------------
if [ -f "$SRC_DIR/ffmpeg/ffmpeg" ]; then
    log "Installing bundled ffmpeg to $WHISPER_DIR/bin"
    mkdir -p "$WHISPER_DIR/bin"
    cp -a "$SRC_DIR/ffmpeg/ffmpeg" "$WHISPER_DIR/bin/ffmpeg"
    chmod +x "$WHISPER_DIR/bin/ffmpeg"
    xattr -dr com.apple.quarantine "$WHISPER_DIR/bin/ffmpeg" 2>/dev/null || true
elif command -v ffmpeg >/dev/null 2>&1; then
    log "Using system ffmpeg ($(command -v ffmpeg))"
else
    log "WARNING: no bundled ffmpeg and none on PATH — non-WAV transcription will fail"
fi

# ---------------------------------------------------------------------------
# 5. Launcher
# ---------------------------------------------------------------------------
log "Creating launcher $LAUNCHER"
mkdir -p "$(dirname "$LAUNCHER")"
cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
# ScriptScreen launcher (generated by install.command)
export PATH="\$HOME/whisper.cpp/bin:\$PATH"   # prefer bundled ffmpeg
cd "$APP_DIR" || exit 1
exec ./node_modules/.bin/electron . "\$@"
EOF
chmod +x "$LAUNCHER"
xattr -dr com.apple.quarantine "$APP_DIR" 2>/dev/null || true

echo
log "ScriptScreen installed."
echo "    Launch by double-clicking: $LAUNCHER"
echo "    (Finder > Go > Home > Applications > ScriptScreen.command)"
echo "    To uninstall: run ./uninstall.command from this archive."
