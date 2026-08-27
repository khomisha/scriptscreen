#!/usr/bin/env bash
#
# make-dist.sh — assemble a ScriptScreen distribution archive.
#
# Produces a self-contained archive containing:
#   - the Flutter web build wrapped by the Electron shell (app/)
#   - a prebuilt whisper.cpp (whisper/), taken from dist/vendor/<platform>
#   - a bundled ffmpeg binary (ffmpeg/), taken from dist/vendor/<platform>
#   - per-platform install/uninstall scripts and the install guide in English
#     and Russian, as .md and .pdf (regenerate the PDFs with
#     dist/scripts/make-install-pdf.sh after editing a guide)
#   - a check-gpu script (linux/windows) so users can test GPU suitability
#
# Speech models (ggml-*.bin) are NOT included by default — they are large, and
# the install script downloads the needed ones on the client machine. Use
# --with-models to bundle whatever models are in the vendor dir (offline installs).
#
# The end user only needs to unpack the archive and run the install script.
#
# Whisper payloads are cached per GPU flavor under
# dist/vendor/<platform>/whisper-<flavor> (flavor: cpu | vulkan | cuda), as
# staged by the build-whisper scripts. By default one archive is produced per
# cached flavor, so releasing an app-only change never rebuilds whisper —
# combine with --skip-build to also reuse the Flutter bundle. The legacy
# single-slot dist/vendor/<platform>/whisper layout is still supported (its
# flavor is read from the GPU_BACKEND marker).
#
# Usage:
#   dist/make-dist.sh --platform linux|windows|macos [options]
#
# Options:
#   --platform <p>   Target platform: linux | windows | macos   (required)
#   --version <v>    Override version (default: parsed from pubspec.yaml)
#   --out <dir>      Output directory for the archive (default: dist/out)
#   --gpu <flavor>   Package only this cached whisper flavor: cpu | vulkan | cuda
#                    (default: one archive per flavor cached in the vendor dir)
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
GPU_FLAVOR=""
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
        --gpu)      GPU_FLAVOR="${2:-}"; shift 2;;
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
        -h|--help) sed -n '2,48p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
        *) die "unknown argument: $1";;
    esac
done

case "$PLATFORM" in
    linux|windows|macos) ;;
    "") die "missing --platform (linux|windows|macos)";;
    *)  die "invalid --platform: $PLATFORM";;
esac

case "$GPU_FLAVOR" in
    "") ;;
    none) GPU_FLAVOR="cpu";;   # build-whisper.sh calls the CPU flavor 'none'
    cpu|vulkan|cuda) ;;
    *) die "invalid --gpu: $GPU_FLAVOR (cpu|vulkan|cuda)";;
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

# 2. Resolve which cached whisper payloads (flavors) to package.
#    New layout: dist/vendor/<platform>/whisper-<flavor> (cpu|vulkan|cuda), as
#    staged by the build-whisper scripts — flavors stay cached side by side, so
#    an app-only change never needs a whisper rebuild.
#    Legacy layout: a single dist/vendor/<platform>/whisper dir (flavor read
#    from its GPU_BACKEND marker) — still supported.
VENDOR="$REPO_ROOT/dist/vendor/$PLATFORM"

flavor_of() {  # $1 = whisper payload dir -> cpu|vulkan|cuda
    if [ -f "$1/GPU_BACKEND" ]; then tr -d '[:space:]' < "$1/GPU_BACKEND"; else echo cpu; fi
}

WHISPER_DIRS=( )
if [ "$SKIP_VENDOR" -eq 0 ]; then
    [ -d "$VENDOR/ffmpeg" ] || die "missing $VENDOR/ffmpeg. See dist/vendor/README.md"
    if [ -n "$GPU_FLAVOR" ]; then
        if [ -d "$VENDOR/whisper-$GPU_FLAVOR" ]; then
            WHISPER_DIRS=( "$VENDOR/whisper-$GPU_FLAVOR" )
        elif [ -d "$VENDOR/whisper" ] && [ "$(flavor_of "$VENDOR/whisper")" = "$GPU_FLAVOR" ]; then
            WHISPER_DIRS=( "$VENDOR/whisper" )
        else
            die "no cached whisper payload for flavor '$GPU_FLAVOR' — build it first: dist/scripts/build-whisper.sh --gpu $GPU_FLAVOR"
        fi
    else
        for d in "$VENDOR"/whisper-*; do
            if [ -d "$d" ]; then WHISPER_DIRS+=( "$d" ); fi
        done
        if [ "${#WHISPER_DIRS[@]}" -eq 0 ]; then
            [ -d "$VENDOR/whisper" ] || die "missing $VENDOR/whisper (prebuilt whisper.cpp). See dist/vendor/README.md"
            WHISPER_DIRS=( "$VENDOR/whisper" )
        elif [ -d "$VENDOR/whisper" ]; then
            log "Ignoring legacy $VENDOR/whisper — flavored whisper-* payloads take precedence (the next build-whisper.sh run migrates it)"
        fi
    fi
fi

# 3. Stage the app/ once — it is identical for every flavor.
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

log "Staging app/"
mkdir -p "$TMP_ROOT/app"
# Copy the built app but never ship a pre-existing node_modules — the user installs it.
( cd build/web && tar --exclude='./node_modules' -cf - . ) | ( cd "$TMP_ROOT/app" && tar -xf - )

mkdir -p "$OUT_DIR"

# 4. Package one archive per whisper payload. GPU-flavored payloads get
#    "-gpu-<backend>" in the archive name so users can tell the flavors apart.
package_one() {  # $1 = whisper payload dir, or "" with --skip-vendor
    local wdir="$1" gpu_suffix="" flavor stage_name stage archive py
    if [ -n "$wdir" ]; then
        flavor="$(flavor_of "$wdir")"
        [ "$flavor" = cpu ] || gpu_suffix="-gpu-$flavor"
    fi
    stage_name="scriptscreen-$VERSION-$PLATFORM$gpu_suffix"
    stage="$TMP_ROOT/$stage_name"
    rm -rf "$stage"
    mkdir -p "$stage"
    cp -a "$TMP_ROOT/app" "$stage/app"

    if [ -n "$wdir" ]; then
        log "Staging whisper/ (from ${wdir#"$REPO_ROOT"/}) and ffmpeg/"
        cp -a "$wdir" "$stage/whisper"
        cp -a "$VENDOR/ffmpeg" "$stage/ffmpeg"
        if [ "$WITH_MODELS" -eq 0 ]; then
            log "Excluding speech models (installer downloads them; use --with-models to bundle)"
            rm -f "$stage/whisper/models/"ggml-*.bin
        fi
    else
        log "Skipping vendor payloads (--skip-vendor); archive will NOT be runnable"
        mkdir -p "$stage/whisper" "$stage/ffmpeg"
    fi

    # Install/uninstall scripts, docs, icon, metadata.
    cp "$REPO_ROOT/dist/templates/common/INSTALL.md"     "$stage/INSTALL.md"
    cp "$REPO_ROOT/dist/templates/common/INSTALL.ru.md"  "$stage/INSTALL.ru.md"
    cp "$REPO_ROOT/dist/templates/common/INSTALL.pdf"    "$stage/INSTALL.pdf"
    cp "$REPO_ROOT/dist/templates/common/INSTALL.ru.pdf" "$stage/INSTALL.ru.pdf"
    cp "$REPO_ROOT/web/icons/Icon-512.png" "$stage/icon.png" 2>/dev/null || true
    echo "$VERSION" > "$stage/VERSION"

    case "$PLATFORM" in
        linux)
            cp "$REPO_ROOT/dist/templates/linux/install.sh"   "$stage/install.sh"
            cp "$REPO_ROOT/dist/templates/linux/uninstall.sh" "$stage/uninstall.sh"
            cp "$REPO_ROOT/dist/templates/linux/check-gpu.sh" "$stage/check-gpu.sh"
            chmod +x "$stage/install.sh" "$stage/uninstall.sh" "$stage/check-gpu.sh"
            ;;
        macos)
            cp "$REPO_ROOT/dist/templates/macos/install.command"   "$stage/install.command"
            cp "$REPO_ROOT/dist/templates/macos/uninstall.command" "$stage/uninstall.command"
            chmod +x "$stage/install.command" "$stage/uninstall.command"
            ;;
        windows)
            cp "$REPO_ROOT/dist/templates/windows/install.ps1"   "$stage/install.ps1"
            cp "$REPO_ROOT/dist/templates/windows/uninstall.ps1" "$stage/uninstall.ps1"
            cp "$REPO_ROOT/dist/templates/windows/check-gpu.ps1" "$stage/check-gpu.ps1"
            ;;
    esac

    if [ "$PLATFORM" = "windows" ]; then
        archive="$OUT_DIR/$stage_name.zip"
        rm -f "$archive"
        log "Creating $archive"
        if command -v powershell.exe >/dev/null 2>&1 && command -v cygpath >/dev/null 2>&1; then
            powershell.exe -NoProfile -Command "Compress-Archive -Path '$(cygpath -w "$stage")' -DestinationPath '$(cygpath -w "$archive")' -Force"
        else
            die "creating the zip needs powershell.exe"
        fi
    else
        archive="$OUT_DIR/$stage_name.tar.gz"
        rm -f "$archive"
        log "Creating $archive"
        tar -C "$TMP_ROOT" -czf "$archive" "$stage_name"
    fi

    rm -rf "$stage"
    log "Done: $archive"
    log "Size: $(du -h "$archive" | cut -f1)"
}

if [ "$SKIP_VENDOR" -eq 1 ]; then
    package_one ""
else
    for d in "${WHISPER_DIRS[@]}"; do
        package_one "$d"
    done
fi
