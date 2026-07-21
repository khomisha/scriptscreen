#!/usr/bin/env bash
#
# make-dist.sh — assemble a ScriptScreen distribution archive.
#
# Produces a self-contained archive containing:
#   - the Flutter web build wrapped by the Electron shell (app/)
#   - a prebuilt whisper.cpp (whisper/), taken from dist/vendor/<platform>
#   - a bundled ffmpeg binary (ffmpeg/), taken from dist/vendor/<platform>
#   - per-platform install/uninstall scripts and INSTALL.md
#   - a check-gpu script (linux/windows) so users can test GPU suitability
#
# Speech models (ggml-*.bin) are NOT included by default — they are large, and
# the install script downloads the needed ones on the client machine. Use
# --with-models to bundle whatever models are in the vendor dir (offline installs).
#
# The end user only needs to unpack the archive and run the install script.
#
# Usage:
#   dist/make-dist.sh --platform linux|windows|macos [options]
#
# Options:
#   --platform <p>   Target platform: linux | windows | macos   (required)
#   --version <v>    Override version (default: parsed from pubspec.yaml)
#   --out <dir>      Output directory for the archive (default: dist/out)
#   --debug          Build the Flutter web bundle with --debug instead of --release
#   --skip-build     Reuse the existing build/web instead of running `flutter build web`
#   --skip-vendor    Allow packaging without whisper/ffmpeg vendor payloads (for testing)
#   --with-models    Bundle the ggml-*.bin models from the vendor dir into the
#                    archive (default: exclude them; the installer downloads them)
#   --log <file>     Write the log to a custom path
#                    (default: always logs to dist/out/make-dist-<platform>.log)
#   --no-log         Disable the log file
#   -h, --help       Show this help
#
# The Flutter web bundle is always built with --no-web-resources-cdn so the
# CanvasKit/wasm assets are served locally (the Electron shell has no CDN access).
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PLATFORM=""
VERSION=""
OUT_DIR="$REPO_ROOT/dist/out"
SKIP_BUILD=0
SKIP_VENDOR=0
WITH_MODELS=0
DEBUG_BUILD=0
LOG_FILE=""
WANT_LOG=1

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*"; }

while [ $# -gt 0 ]; do
    case "$1" in
        --platform) PLATFORM="${2:-}"; shift 2;;
        --version)  VERSION="${2:-}"; shift 2;;
        --out)      OUT_DIR="${2:-}"; shift 2;;
        --debug)    DEBUG_BUILD=1; shift;;
        --skip-build)  SKIP_BUILD=1; shift;;
        --skip-vendor) SKIP_VENDOR=1; shift;;
        --with-models) WITH_MODELS=1; shift;;
        --log)
            WANT_LOG=1
            # Optional path argument (anything not starting with '-').
            if [ $# -ge 2 ] && [ "${2#-}" = "$2" ]; then LOG_FILE="$2"; shift 2; else shift; fi
            ;;
        --no-log)  WANT_LOG=0; shift;;
        -h|--help) sed -n '2,36p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
        *) die "unknown argument: $1";;
    esac
done

case "$PLATFORM" in
    linux|windows|macos) ;;
    "") die "missing --platform (linux|windows|macos)";;
    *)  die "invalid --platform: $PLATFORM";;
esac

# Logging (default on): tee all stdout/stderr to a file as well as the
# terminal, so the error survives even if the console window closes on
# failure (e.g. a Git Bash window spawned from Explorer/cmd on Windows).
# One log per run: truncated at the start, --no-log disables it.
if [ "$WANT_LOG" -eq 1 ]; then
    [ -n "$LOG_FILE" ] || LOG_FILE="$OUT_DIR/make-dist-$PLATFORM.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    : > "$LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1
    log "Logging to $LOG_FILE"
fi

# Resolve version from pubspec.yaml (e.g. "1.3.1+1" -> "1.3.1") if not overridden.
if [ -z "$VERSION" ]; then
    VERSION="$(grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/^version:[[:space:]]*//; s/\+.*$//')"
    [ -n "$VERSION" ] || die "could not parse version from pubspec.yaml; pass --version"
fi

log "Packaging ScriptScreen $VERSION for $PLATFORM"

# 1. Build the Flutter web bundle (which also copies the Electron files from web/).
if [ "$SKIP_BUILD" -eq 0 ]; then
    command -v flutter >/dev/null 2>&1 || die "flutter not found on PATH"
    if [ "$DEBUG_BUILD" -eq 1 ]; then
        log "flutter build web --no-web-resources-cdn --debug"
        flutter build web --no-web-resources-cdn --debug
    else
        log "flutter build web --no-web-resources-cdn --release"
        flutter build web --no-web-resources-cdn --release
    fi
else
    log "Skipping flutter build (using existing build/web)"
fi
[ -d build/web ] || die "build/web not found; run without --skip-build"
[ -f build/web/main.js ] || die "build/web/main.js missing; is the Electron shell in web/?"

# 2. Stage the archive contents. GPU-flavored vendor payloads (GPU_BACKEND
#    marker written by the build-whisper scripts for --gpu cuda|vulkan) get
#    "-gpu-<backend>" in the archive name so users can tell the flavors apart.
GPU_SUFFIX=""
GPU_MARKER="$REPO_ROOT/dist/vendor/$PLATFORM/whisper/GPU_BACKEND"
if [ "$SKIP_VENDOR" -eq 0 ] && [ -f "$GPU_MARKER" ]; then
    GPU_SUFFIX="-gpu-$(tr -d '[:space:]' < "$GPU_MARKER")"
    log "GPU vendor payload detected (${GPU_SUFFIX#-gpu-})"
fi
STAGE_NAME="scriptscreen-$VERSION-$PLATFORM$GPU_SUFFIX"
STAGE="$(mktemp -d)/$STAGE_NAME"
mkdir -p "$STAGE"
trap 'rm -rf "$(dirname "$STAGE")"' EXIT

log "Staging app/"
mkdir -p "$STAGE/app"
# Copy the built app but never ship a pre-existing node_modules — the user installs it.
( cd build/web && tar --exclude='./node_modules' -cf - . ) | ( cd "$STAGE/app" && tar -xf - )

# 3. Vendor payloads: whisper.cpp build and ffmpeg (models are excluded by
#    default — the install script downloads them on the client).
VENDOR="$REPO_ROOT/dist/vendor/$PLATFORM"
if [ "$SKIP_VENDOR" -eq 0 ]; then
    [ -d "$VENDOR/whisper" ] || die "missing $VENDOR/whisper (prebuilt whisper.cpp). See dist/vendor/README.md"
    [ -d "$VENDOR/ffmpeg" ]  || die "missing $VENDOR/ffmpeg. See dist/vendor/README.md"
    log "Staging whisper/ and ffmpeg/ from $VENDOR"
    cp -a "$VENDOR/whisper" "$STAGE/whisper"
    cp -a "$VENDOR/ffmpeg"  "$STAGE/ffmpeg"
    if [ "$WITH_MODELS" -eq 0 ]; then
        log "Excluding speech models (installer downloads them; use --with-models to bundle)"
        rm -f "$STAGE/whisper/models/"ggml-*.bin
    fi
else
    log "Skipping vendor payloads (--skip-vendor); archive will NOT be runnable"
    mkdir -p "$STAGE/whisper" "$STAGE/ffmpeg"
fi

# 4. Install/uninstall scripts, docs, icon, metadata.
log "Staging install scripts and docs"
cp "$REPO_ROOT/dist/templates/common/INSTALL.md" "$STAGE/INSTALL.md"
cp "$REPO_ROOT/web/icons/Icon-512.png" "$STAGE/icon.png" 2>/dev/null || true
echo "$VERSION" > "$STAGE/VERSION"

case "$PLATFORM" in
    linux)
        cp "$REPO_ROOT/dist/templates/linux/install.sh"   "$STAGE/install.sh"
        cp "$REPO_ROOT/dist/templates/linux/uninstall.sh" "$STAGE/uninstall.sh"
        cp "$REPO_ROOT/dist/templates/linux/check-gpu.sh" "$STAGE/check-gpu.sh"
        chmod +x "$STAGE/install.sh" "$STAGE/uninstall.sh" "$STAGE/check-gpu.sh"
        ;;
    macos)
        cp "$REPO_ROOT/dist/templates/macos/install.command"   "$STAGE/install.command"
        cp "$REPO_ROOT/dist/templates/macos/uninstall.command" "$STAGE/uninstall.command"
        chmod +x "$STAGE/install.command" "$STAGE/uninstall.command"
        ;;
    windows)
        cp "$REPO_ROOT/dist/templates/windows/install.ps1"   "$STAGE/install.ps1"
        cp "$REPO_ROOT/dist/templates/windows/uninstall.ps1" "$STAGE/uninstall.ps1"
        cp "$REPO_ROOT/dist/templates/windows/check-gpu.ps1" "$STAGE/check-gpu.ps1"
        ;;
esac

# 5. Archive.
mkdir -p "$OUT_DIR"
if [ "$PLATFORM" = "windows" ]; then
    ARCHIVE="$OUT_DIR/$STAGE_NAME.zip"
    rm -f "$ARCHIVE"
    log "Creating $ARCHIVE"
    # zip -> python3/python -> powershell Compress-Archive (Git Bash on Windows
    # has neither zip nor python3, but always has powershell.exe and cygpath).
    if command -v zip >/dev/null 2>&1; then
        ( cd "$(dirname "$STAGE")" && zip -qr "$ARCHIVE" "$STAGE_NAME" )
    elif command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
        PY="$(command -v python3 || command -v python)"
        "$PY" -c "import shutil,sys; shutil.make_archive(sys.argv[1][:-4],'zip',sys.argv[2],sys.argv[3])" "$ARCHIVE" "$(dirname "$STAGE")" "$STAGE_NAME"
    elif command -v powershell.exe >/dev/null 2>&1 && command -v cygpath >/dev/null 2>&1; then
        powershell.exe -NoProfile -Command "Compress-Archive -Path '$(cygpath -w "$STAGE")' -DestinationPath '$(cygpath -w "$ARCHIVE")' -Force"
    else
        die "creating the zip needs one of: zip, python3/python, or powershell.exe"
    fi
else
    ARCHIVE="$OUT_DIR/$STAGE_NAME.tar.gz"
    rm -f "$ARCHIVE"
    log "Creating $ARCHIVE"
    tar -C "$(dirname "$STAGE")" -czf "$ARCHIVE" "$STAGE_NAME"
fi

log "Done: $ARCHIVE"
log "Size: $(du -h "$ARCHIVE" | cut -f1)"
