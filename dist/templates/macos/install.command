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
#   --electron-zip <f>  Install Electron from this local
#                       electron-v<ver>-darwin-<arch>.zip instead of downloading
#                       it. A zip with that name next to this script is used
#                       automatically.
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
ELECTRON_ZIP=""
while [ $# -gt 0 ]; do
    case "$1" in
        --models) MODELS="${2:-}"; shift 2;;
        --log)
            WANT_LOG=1
            if [ $# -ge 2 ] && [ "${2#-}" = "$2" ]; then LOG_FILE="$2"; shift 2; else shift; fi
            ;;
        --no-log) WANT_LOG=0; shift;;
        --electron-zip) ELECTRON_ZIP="${2:-}"; shift 2;;
        -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
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
# A local Electron zip (for networks where neither GitHub nor the mirror is
# reachable): --electron-zip, or electron-v*-darwin-*.zip next to this script.
if [ -z "$ELECTRON_ZIP" ]; then
    ELECTRON_ZIP="$(ls -1 "$SRC_DIR"/electron-v*-darwin-*.zip 2>/dev/null | sort -r | head -n 1 || true)"
elif [ ! -f "$ELECTRON_ZIP" ]; then
    die "Electron zip not found: $ELECTRON_ZIP"
fi
if [ -n "$ELECTRON_ZIP" ]; then
    ELECTRON_ZIP="$(cd "$(dirname "$ELECTRON_ZIP")" && pwd)/$(basename "$ELECTRON_ZIP")"
    log "Using local Electron archive $ELECTRON_ZIP (skipping the Electron download)"
fi

# The Electron binary is fetched by electron's postinstall (install.js).
# Newer npm (11.16+) does not run dependency install scripts unless they are
# approved (allowScripts), so the postinstall may silently never run. Skip it
# during npm install and run install.js explicitly below instead, so the
# result does not depend on the npm version or its script policy.
log "Installing npm dependencies (needs network)"
( cd "$APP_DIR" && ELECTRON_SKIP_BINARY_DOWNLOAD=1 npm install --omit=dev --no-audit --no-fund ) \
    || log "WARNING: npm install failed"

ELECTRON_PKG="$APP_DIR/node_modules/electron"
ELECTRON_BIN="$ELECTRON_PKG/dist/Electron.app/Contents/MacOS/Electron"
# Unpack the local zip the way electron's own install.js does: binaries in
# dist/, the executable's path (relative to dist/) in path.txt, no newline.
install_electron_zip() {
    [ -f "$ELECTRON_PKG/package.json" ] \
        || die "npm install did not set up node_modules/electron — see the npm output above"
    local want arch want_name
    want="$(node -p 'require(process.argv[1]).version' "$ELECTRON_PKG/package.json")"
    case "$(uname -m)" in
        x86_64|amd64)  arch=x64 ;;
        aarch64|arm64) arch=arm64 ;;
        armv7l)        arch=armv7l ;;
        *)             arch="$(uname -m)" ;;
    esac
    want_name="electron-v$want-darwin-$arch.zip"
    [ "$(basename "$ELECTRON_ZIP")" = "$want_name" ] \
        || die "local Electron archive is $(basename "$ELECTRON_ZIP"), but this app needs $want_name — download it from https://github.com/electron/electron/releases/tag/v$want (or https://npmmirror.com/mirrors/electron/$want/) and re-run"
    log "Unpacking $want_name"
    rm -rf "$ELECTRON_PKG/dist"
    mkdir -p "$ELECTRON_PKG/dist"
    # ditto keeps the symlinks inside Electron.app's frameworks intact.
    ditto -x -k "$ELECTRON_ZIP" "$ELECTRON_PKG/dist"
    # A browser-downloaded zip is quarantined; don't let that block the app.
    xattr -dr com.apple.quarantine "$ELECTRON_PKG/dist" 2>/dev/null || true
    printf '%s' "Electron.app/Contents/MacOS/Electron" > "$ELECTRON_PKG/path.txt"
    [ -x "$ELECTRON_BIN" ] || die "Electron executable not found after unpacking $ELECTRON_ZIP — is the archive complete?"
}

if [ -n "$ELECTRON_ZIP" ]; then
    install_electron_zip
else
    [ -f "$ELECTRON_PKG/install.js" ] \
        || die "npm install did not set up node_modules/electron — see the npm output above, then re-run"
    if [ ! -x "$ELECTRON_BIN" ]; then
        log "Downloading Electron from ${ELECTRON_MIRROR:-GitHub}"
        ( cd "$ELECTRON_PKG" && node install.js ) || true
    fi
    if [ ! -x "$ELECTRON_BIN" ] && [ -z "${ELECTRON_MIRROR:-}" ]; then
        log "Electron download from GitHub failed — retrying via mirror"
        export ELECTRON_MIRROR="https://npmmirror.com/mirrors/electron/"
        ( cd "$ELECTRON_PKG" && node install.js ) || true
    fi
    [ -x "$ELECTRON_BIN" ] \
        || die "Electron download failed (last tried $ELECTRON_MIRROR; the error is printed above) — set ELECTRON_MIRROR to a reachable mirror, or download electron-v<version>-darwin-<arch>.zip by other means, put it next to this script and re-run (the version is in $ELECTRON_PKG/package.json)"
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
