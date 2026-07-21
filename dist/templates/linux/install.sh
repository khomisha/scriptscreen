#!/usr/bin/env bash
#
# ScriptScreen — Linux installer.
#
# Unpacks nothing of its own: run it from inside the unpacked archive directory.
# Installs into your home directory only — no root required for ScriptScreen
# itself (root is only used, with your confirmation, to install Node.js/ffmpeg/
# SDL2/Vulkan-loader system packages when they are missing).
#
# Options:
#   --models "<a> <b>"  Models to ensure are present (default: $SCRIPTSCREEN_MODELS
#                       or "small"). Missing ones are downloaded.
#   --log <file>        Write the install log to a custom file
#                       (default: ~/.local/share/scriptscreen/install.log).
#   --no-log            Do not write a log file.
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"        # the unpacked archive
APP_DIR="${SCRIPTSCREEN_HOME:-$HOME/.local/share/scriptscreen}" # installed app
WHISPER_DIR="$HOME/whisper.cpp"                                 # whisper.cpp + models (hardcoded in app)
BIN_DIR="$HOME/.local/bin"                                      # launcher
DESKTOP_DIR="$HOME/.local/share/applications"                  # menu entry

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*"; }

# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------
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
        -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
        *) die "unknown argument: $1";;
    esac
done

[ -d "$SRC_DIR/app" ] || die "this script must be run from the unpacked archive (app/ not found)"

# Logging (on by default, --no-log disables): tee all output to a file too.
if [ "$WANT_LOG" -eq 1 ]; then
    [ -n "$LOG_FILE" ] || LOG_FILE="$APP_DIR/install.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    exec > >(tee -a "$LOG_FILE") 2>&1
    log "Logging to $LOG_FILE"
fi

# ---------------------------------------------------------------------------
# 1. Ensure Node.js + npm
# ---------------------------------------------------------------------------
detect_pm() {
    if command -v apt-get >/dev/null 2>&1; then echo apt; return; fi
    if command -v dnf     >/dev/null 2>&1; then echo dnf; return; fi
    if command -v pacman  >/dev/null 2>&1; then echo pacman; return; fi
    if command -v zypper  >/dev/null 2>&1; then echo zypper; return; fi
    echo ""
}

install_node() {
    local pm; pm="$(detect_pm)"
    [ -n "$pm" ] || die "could not detect a package manager. Install Node.js 18+ manually, then re-run."
    log "Node.js/npm not found — installing via $pm (sudo required)"
    case "$pm" in
        apt)    sudo apt-get update && sudo apt-get install -y nodejs npm ;;
        dnf)    sudo dnf install -y nodejs npm ;;
        pacman) sudo pacman -Sy --noconfirm nodejs npm ;;
        zypper) sudo zypper install -y nodejs npm ;;
    esac
}

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    install_node
fi
command -v node >/dev/null 2>&1 || die "Node.js still not available after install"
log "Using node $(node --version), npm $(npm --version)"

# ---------------------------------------------------------------------------
# 2. Install the app and its npm dependencies (electron, pdf-lib)
# ---------------------------------------------------------------------------
log "Installing app to $APP_DIR"
mkdir -p "$APP_DIR"
cp -a "$SRC_DIR/app/." "$APP_DIR/"

log "Installing npm dependencies (this downloads Electron — needs network)"
( cd "$APP_DIR" && npm install --omit=dev --no-audit --no-fund ) \
    || log "WARNING: npm install failed — retrying the Electron download below"

# The Electron binary is fetched from GitHub releases by a postinstall step.
# On networks where that download is blocked or reset, npm leaves
# node_modules/electron in place without the binary — and a plain re-run of
# npm install then skips the postinstall, so the tree never heals itself.
# Verify the binary and, if missing, retry the download through a mirror.
ELECTRON_PKG="$APP_DIR/node_modules/electron"
if [ ! -x "$ELECTRON_PKG/dist/electron" ]; then
    log "Electron binary missing (GitHub download failed?) — retrying via mirror"
    export ELECTRON_MIRROR="${ELECTRON_MIRROR:-https://npmmirror.com/mirrors/electron/}"
    if [ -f "$ELECTRON_PKG/install.js" ]; then
        ( cd "$ELECTRON_PKG" && node install.js ) || true
    else
        # npm rolled the tree back on failure — run the whole install again
        # with the mirror active so the postinstall fetches from it.
        ( cd "$APP_DIR" && npm install --omit=dev --no-audit --no-fund ) || true
    fi
    [ -x "$ELECTRON_PKG/dist/electron" ] \
        || die "Electron download failed even via mirror ($ELECTRON_MIRROR) — set ELECTRON_MIRROR to a reachable mirror and re-run"
fi

# ---------------------------------------------------------------------------
# 3. Install whisper.cpp + models into ~/whisper.cpp
#    (the app expects ~/whisper.cpp/build/bin and ~/whisper.cpp/models)
# ---------------------------------------------------------------------------
if [ -d "$SRC_DIR/whisper/build" ] || [ -d "$SRC_DIR/whisper/models" ]; then
    log "Installing whisper.cpp to $WHISPER_DIR"
    mkdir -p "$WHISPER_DIR"
    cp -a "$SRC_DIR/whisper/." "$WHISPER_DIR/"
    [ -f "$WHISPER_DIR/build/bin/whisper-cli" ]    && chmod +x "$WHISPER_DIR/build/bin/whisper-cli"
    [ -f "$WHISPER_DIR/build/bin/whisper-stream" ] && chmod +x "$WHISPER_DIR/build/bin/whisper-stream"
else
    log "WARNING: no whisper payload in archive — transcription will not work until ~/whisper.cpp is populated"
fi

# ---------------------------------------------------------------------------
# 3a. SDL2 — required by whisper-stream (live transcription). The shipped
#     binaries are static except for SDL2, which is dynamically linked, so
#     install it on this machine if it is missing.
# ---------------------------------------------------------------------------
if [ -f "$WHISPER_DIR/build/bin/whisper-stream" ]; then
    if ldconfig -p 2>/dev/null | grep -qi 'libSDL2'; then
        log "SDL2 already present"
    else
        pm="$(detect_pm)"
        if [ -n "$pm" ]; then
            log "Installing SDL2 (needed for live transcription; sudo required)"
            case "$pm" in
                apt)    sudo apt-get update && sudo apt-get install -y libsdl2-2.0-0 ;;
                dnf)    sudo dnf install -y SDL2 ;;
                pacman) sudo pacman -Sy --noconfirm sdl2 ;;
                zypper) sudo zypper install -y libSDL2-2_0-0 ;;
            esac
        else
            log "WARNING: could not install SDL2 automatically — live transcription needs libSDL2. Install it via your package manager."
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 3b. Vulkan loader — GPU (vulkan) builds of whisper.cpp dynamically link
#     libvulkan.so.1. Install it if this archive is a Vulkan flavor and the
#     loader is missing. (With the loader present but no Vulkan-capable GPU,
#     whisper.cpp falls back to the CPU automatically.)
# ---------------------------------------------------------------------------
if [ -f "$SRC_DIR/whisper/GPU_BACKEND" ] \
   && [ "$(tr -d '[:space:]' < "$SRC_DIR/whisper/GPU_BACKEND")" = vulkan ]; then
    if ldconfig -p 2>/dev/null | grep -q 'libvulkan\.so\.1'; then
        log "Vulkan loader already present"
    else
        pm="$(detect_pm)"
        if [ -n "$pm" ]; then
            log "Installing Vulkan loader (needed by this GPU build; sudo required)"
            case "$pm" in
                apt)    sudo apt-get update && sudo apt-get install -y libvulkan1 ;;
                dnf)    sudo dnf install -y vulkan-loader ;;
                pacman) sudo pacman -Sy --noconfirm vulkan-icd-loader ;;
                zypper) sudo zypper install -y libvulkan1 ;;
            esac
        else
            log "WARNING: could not install the Vulkan loader automatically — this GPU build needs libvulkan.so.1. Install it via your package manager."
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 3c. Ensure speech models are present — download any missing ones.
# ---------------------------------------------------------------------------
HF_BASE="https://huggingface.co/ggerganov/whisper.cpp/resolve/main"
download_model() {  # $1 = UI model name (as selected in ScriptScreen)
    local name="$1" remote="$1" dest="$WHISPER_DIR/models/ggml-$1.bin"
    [ -f "$dest" ] && { log "Model '$name' already present"; return; }
    # The UI's 'turbo' entry maps to the large-v3-turbo weights.
    [ "$name" = turbo ] && remote="large-v3-turbo"
    log "Downloading model '$name' (ggml-$remote.bin)"
    mkdir -p "$WHISPER_DIR/models"
    if command -v curl >/dev/null 2>&1; then
        curl -fL "$HF_BASE/ggml-$remote.bin" -o "$dest.part" && mv "$dest.part" "$dest"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$dest.part" "$HF_BASE/ggml-$remote.bin" && mv "$dest.part" "$dest"
    else
        rm -f "$dest.part"; log "WARNING: neither curl nor wget available — cannot download '$name'"; return
    fi
}
for m in $MODELS; do download_model "$m"; done

# ---------------------------------------------------------------------------
# 4. Install bundled ffmpeg into ~/whisper.cpp/bin (added to PATH by launcher)
# ---------------------------------------------------------------------------
if [ -f "$SRC_DIR/ffmpeg/ffmpeg" ]; then
    log "Installing bundled ffmpeg to $WHISPER_DIR/bin"
    mkdir -p "$WHISPER_DIR/bin"
    cp -a "$SRC_DIR/ffmpeg/ffmpeg" "$WHISPER_DIR/bin/ffmpeg"
    chmod +x "$WHISPER_DIR/bin/ffmpeg"
elif command -v ffmpeg >/dev/null 2>&1; then
    log "Using system ffmpeg ($(command -v ffmpeg))"
else
    log "WARNING: no bundled ffmpeg and none on PATH — non-WAV transcription will fail"
fi

# ---------------------------------------------------------------------------
# 5. Launcher + desktop entry
# ---------------------------------------------------------------------------
log "Creating launcher $BIN_DIR/scriptscreen"
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/scriptscreen" <<EOF
#!/usr/bin/env bash
# ScriptScreen launcher (generated by install.sh)
export PATH="\$HOME/whisper.cpp/bin:\$PATH"   # prefer bundled ffmpeg
cd "$APP_DIR" || exit 1
exec ./node_modules/.bin/electron . "\$@"
EOF
chmod +x "$BIN_DIR/scriptscreen"

if [ -f "$SRC_DIR/icon.png" ]; then
    mkdir -p "$APP_DIR"
    cp "$SRC_DIR/icon.png" "$APP_DIR/icon.png"
fi
log "Creating desktop entry"
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_DIR/scriptscreen.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=ScriptScreen
Comment=ScriptScreen editor with mind cards
Exec=$BIN_DIR/scriptscreen
Icon=$APP_DIR/icon.png
Terminal=false
Categories=Office;Utility;
EOF
update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo
log "ScriptScreen installed."
echo "    Launch from your application menu, or run:  scriptscreen"
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "    NOTE: $BIN_DIR is not on your PATH. Add this to ~/.bashrc:"
       echo "          export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac
echo "    To uninstall: run ./uninstall.sh from this archive."
