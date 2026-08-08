#!/usr/bin/env bash
#
# build-whisper.sh — build whisper.cpp (+ SDL2 for live transcription) and
# provide ffmpeg, then stage everything into dist/vendor/<platform>/ ready
# for make-dist.sh.
#
# Works on Linux and macOS (auto-detected). For Windows use build-whisper.ps1.
#
# It produces the layout make-dist.sh expects, cached per GPU flavor so
# several flavors coexist — an app-only release never rebuilds whisper:
#   dist/vendor/<platform>/whisper-<flavor>/build/bin/whisper-cli    (flavor: cpu|vulkan|cuda)
#   dist/vendor/<platform>/whisper-<flavor>/build/bin/whisper-stream
#   dist/vendor/<platform>/whisper-<flavor>/models/   (empty by default)
#   dist/vendor/<platform>/ffmpeg/ffmpeg
# A legacy single-slot dist/vendor/<platform>/whisper payload is migrated to
# its flavored name automatically on the next run.
#
# Speech models are NOT bundled by default — they are large, and the install
# scripts download the needed ones on the client machine. Pass --models to
# pre-bundle models anyway (e.g. for offline installs).
#
# whisper.cpp is built with BUILD_SHARED_LIBS=OFF and WHISPER_SDL2=ON, so the
# only remaining dynamic dependency is SDL2. The per-platform install scripts
# install SDL2 on the client machine (see requirement 3).
#
# Usage:
#   dist/scripts/build-whisper.sh [options]
#
# Options:
#   --models "<a> <b>"   Space-separated models to download AND bundle into the
#                        vendor payload (default: none — the installer downloads
#                        models on the client). Names match
#                        whisper.cpp/models/download-ggml-model.sh,
#                        e.g. tiny base small medium large-v3 large-v3-turbo.
#   --src <dir>          Where to clone/build whisper.cpp (default: build/whisper.cpp).
#   --ffmpeg <mode>      download | build | skip | <path>   (default: download).
#                        download = fetch a static LGPL ffmpeg build;
#                        build    = compile ffmpeg from source (LGPL config);
#                        <path>   = copy an existing ffmpeg binary.
#   --gpu <backend>      cuda | vulkan | metal | none  (default: metal on macOS,
#                        none on Linux). GPU is optional; 'none' = widest CPU build.
#                        vulkan: build deps (Vulkan headers/loader + glslc) are
#                        installed automatically on Linux; no GPU is needed at
#                        build time. cuda: requires the CUDA Toolkit (nvcc) to
#                        be installed beforehand. cuda/vulkan write a GPU_BACKEND
#                        marker into the vendor payload, and make-dist.sh then
#                        names the archive scriptscreen-<version>-<platform>-gpu-<backend>.
#                        'cpu' is accepted as an alias for 'none'.
#   --jobs <n>           Parallel build jobs (default: all cores).
#   --log [file]         Also write all output to a log file
#                        (default: dist/out/build-whisper-<platform>.log).
#   -h, --help           Show this help.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*"; }

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------
case "$(uname -s)" in
    Linux)  PLATFORM="linux";  NCPU="$(nproc)";;
    Darwin) PLATFORM="macos";  NCPU="$(sysctl -n hw.ncpu)";;
    *) die "unsupported OS $(uname -s); use build-whisper.ps1 on Windows";;
esac

# ---------------------------------------------------------------------------
# Defaults + argument parsing
# ---------------------------------------------------------------------------
MODELS=""   # none by default — the install scripts download models on the client
SRC_DIR="$REPO_ROOT/build/whisper.cpp"
FFMPEG_MODE="download"
GPU="$([ "$PLATFORM" = macos ] && echo metal || echo none)"
JOBS="$NCPU"
WANT_LOG=0
LOG_FILE=""
WHISPER_REPO="https://github.com/ggml-org/whisper.cpp"

while [ $# -gt 0 ]; do
    case "$1" in
        --models)  MODELS="${2:-}"; shift 2;;
        --src)     SRC_DIR="${2:-}"; shift 2;;
        --ffmpeg)  FFMPEG_MODE="${2:-}"; shift 2;;
        --gpu)     GPU="${2:-}"; shift 2;;
        --jobs)    JOBS="${2:-}"; shift 2;;
        --log)
            WANT_LOG=1
            if [ $# -ge 2 ] && [ "${2#-}" = "$2" ]; then LOG_FILE="$2"; shift 2; else shift; fi
            ;;
        -h|--help) sed -n '2,52p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
        *) die "unknown argument: $1";;
    esac
done

if [ "$GPU" = "cpu" ]; then GPU="none"; fi

VENDOR="$REPO_ROOT/dist/vendor/$PLATFORM"
case "$GPU" in
    cuda|vulkan) FLAVOR="$GPU";;
    *)           FLAVOR="cpu";;
esac
WHISPER_VENDOR="$VENDOR/whisper-$FLAVOR"

# Optional logging: tee everything to a file as well as the terminal.
if [ "$WANT_LOG" -eq 1 ]; then
    [ -n "$LOG_FILE" ] || LOG_FILE="$REPO_ROOT/dist/out/build-whisper-$PLATFORM.log"
    mkdir -p "$(dirname "$LOG_FILE")"
    exec > >(tee -a "$LOG_FILE") 2>&1
    log "Logging to $LOG_FILE"
fi

log "Building whisper.cpp for $PLATFORM (models: ${MODELS:-none}, gpu: $GPU, ffmpeg: $FFMPEG_MODE)"

# ---------------------------------------------------------------------------
# Toolchain check + SDL2 (build-time headers, required for whisper-stream)
# ---------------------------------------------------------------------------
need() { command -v "$1" >/dev/null 2>&1 || die "'$1' not found — install it and re-run"; }
need git
need cmake

ensure_build_deps() {
    if [ "$PLATFORM" = macos ]; then
        command -v brew >/dev/null 2>&1 || die "Homebrew required to install SDL2 build deps; install from https://brew.sh"
        brew list sdl2 >/dev/null 2>&1 || { log "Installing SDL2 (brew)"; brew install sdl2; }
        return
    fi
    # Linux: install SDL2 dev headers via the detected package manager.
    if pkg-config --exists sdl2 2>/dev/null; then return; fi
    log "Installing SDL2 development headers (sudo may be required)"
    if   command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y build-essential cmake libsdl2-dev
    elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y gcc-c++ make cmake SDL2-devel
    elif command -v pacman  >/dev/null 2>&1; then sudo pacman -Sy --noconfirm base-devel cmake sdl2
    elif command -v zypper  >/dev/null 2>&1; then sudo zypper install -y gcc-c++ make cmake libSDL2-devel
    else die "could not detect a package manager to install SDL2 dev headers"; fi
}
ensure_build_deps

# Vulkan build deps: headers + loader + the glslc shader compiler + the
# SPIRV-Headers CMake package (find_package'd by ggml-vulkan). No GPU is
# needed at build time — shaders are precompiled to SPIR-V by glslc.
have_spirv_headers() {
    pkg-config --exists SPIRV-Headers 2>/dev/null && return 0
    find /usr/share/cmake* /usr/lib/cmake /usr/lib64/cmake -maxdepth 3 \
        -name 'SPIRV-HeadersConfig.cmake' 2>/dev/null | grep -q .
}
ensure_vulkan_deps() {
    if pkg-config --exists vulkan 2>/dev/null && command -v glslc >/dev/null 2>&1 && have_spirv_headers; then return; fi
    [ "$PLATFORM" = linux ] || die "--gpu vulkan needs the Vulkan SDK on $PLATFORM; on macOS use the default Metal backend"
    log "Installing Vulkan build dependencies (sudo may be required)"
    if   command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y libvulkan-dev glslc spirv-headers
    elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y vulkan-headers vulkan-loader-devel glslc spirv-headers-devel
    elif command -v pacman  >/dev/null 2>&1; then sudo pacman -Sy --noconfirm vulkan-headers vulkan-icd-loader shaderc spirv-headers
    elif command -v zypper  >/dev/null 2>&1; then sudo zypper install -y vulkan-devel shaderc spirv-headers
    else die "could not detect a package manager to install Vulkan build deps"; fi
}

case "$GPU" in
    vulkan) ensure_vulkan_deps;;
    cuda)   command -v nvcc >/dev/null 2>&1 \
                || die "--gpu cuda requires the CUDA Toolkit (nvcc not found). Install it from https://developer.nvidia.com/cuda-downloads or use --gpu vulkan (works on NVIDIA/AMD/Intel, no toolkit needed)";;
esac

# ---------------------------------------------------------------------------
# Clone + build whisper.cpp (static libs + SDL2)
# ---------------------------------------------------------------------------
if [ -d "$SRC_DIR/.git" ]; then
    log "Updating existing whisper.cpp checkout in $SRC_DIR"
    git -C "$SRC_DIR" pull --ff-only || log "  (pull skipped; using current checkout)"
else
    log "Cloning whisper.cpp into $SRC_DIR"
    mkdir -p "$(dirname "$SRC_DIR")"
    git clone --depth 1 "$WHISPER_REPO" "$SRC_DIR"
fi

# Always pass both backend flags explicitly (ON or OFF): CMake caches them in
# an existing build dir, so a previous --gpu run would otherwise leak into
# this one via CMakeCache.txt.
CMAKE_GPU_FLAGS=(-DGGML_CUDA=OFF -DGGML_VULKAN=OFF)
case "$GPU" in
    # Explicit CUDA architectures: 'native' detection fails on a build machine
    # without an NVIDIA GPU, and a distribution build must cover users' cards
    # anyway (Pascal .. Ada/Hopper).
    cuda)   CMAKE_GPU_FLAGS=(-DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="61;70;75;80;86;89;90" -DGGML_VULKAN=OFF);;
    vulkan) CMAKE_GPU_FLAGS=(-DGGML_VULKAN=ON -DGGML_CUDA=OFF);;
    metal)  [ "$PLATFORM" = macos ] || die "--gpu metal is macOS-only"; ;;  # Metal is default-on for Apple Silicon
    none)   ;;
    *) die "invalid --gpu: $GPU (cuda|vulkan|metal|none)";;
esac

log "Configuring (BUILD_SHARED_LIBS=OFF, WHISPER_SDL2=ON)"
cmake -S "$SRC_DIR" -B "$SRC_DIR/build" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DWHISPER_SDL2=ON \
    "${CMAKE_GPU_FLAGS[@]}"

log "Building whisper.cpp (-j$JOBS)"
cmake --build "$SRC_DIR/build" --config Release -j"$JOBS"

BIN="$SRC_DIR/build/bin"
[ -f "$BIN/whisper-cli" ]    || die "whisper-cli not built (looked in $BIN)"
[ -f "$BIN/whisper-stream" ] || die "whisper-stream not built — is SDL2 installed?"

# ---------------------------------------------------------------------------
# Download models (only if explicitly requested via --models; normally the
# install scripts download them on the client machine instead)
# ---------------------------------------------------------------------------
for m in $MODELS; do
    log "Downloading model: $m"
    ( cd "$SRC_DIR" && ./models/download-ggml-model.sh "$m" )
done
# The app expects the 'turbo' entry as ggml-turbo.bin.
if [ -f "$SRC_DIR/models/ggml-large-v3-turbo.bin" ] && [ ! -f "$SRC_DIR/models/ggml-turbo.bin" ]; then
    cp "$SRC_DIR/models/ggml-large-v3-turbo.bin" "$SRC_DIR/models/ggml-turbo.bin"
fi

# ---------------------------------------------------------------------------
# Stage whisper/ into dist/vendor/<platform>/whisper-<flavor> — flavors are
# cached side by side so make-dist.sh can package all of them without a
# whisper rebuild when only the app changed.
# ---------------------------------------------------------------------------
# Migrate a legacy single-slot dist/vendor/<platform>/whisper payload: keep it
# under its flavored name if that flavor is not cached yet, otherwise drop it
# (it is superseded by this build or by an existing flavored payload).
if [ -d "$VENDOR/whisper" ]; then
    LEGACY_FLAVOR="cpu"
    [ ! -f "$VENDOR/whisper/GPU_BACKEND" ] || LEGACY_FLAVOR="$(tr -d '[:space:]' < "$VENDOR/whisper/GPU_BACKEND")"
    if [ "$LEGACY_FLAVOR" != "$FLAVOR" ] && [ ! -d "$VENDOR/whisper-$LEGACY_FLAVOR" ]; then
        log "Migrating legacy vendor payload -> dist/vendor/$PLATFORM/whisper-$LEGACY_FLAVOR"
        mv "$VENDOR/whisper" "$VENDOR/whisper-$LEGACY_FLAVOR"
    else
        log "Removing superseded legacy vendor payload dist/vendor/$PLATFORM/whisper"
        rm -rf "$VENDOR/whisper"
    fi
fi

log "Staging whisper -> $WHISPER_VENDOR"
rm -rf "$WHISPER_VENDOR"
mkdir -p "$WHISPER_VENDOR/build/bin" "$WHISPER_VENDOR/models"
cp "$BIN/whisper-cli" "$BIN/whisper-stream" "$WHISPER_VENDOR/build/bin/"
# Ship any shared libs the binaries still need (e.g. libSDL2 if not fully static).
find "$BIN" -maxdepth 1 \( -name '*.so' -o -name '*.so.*' -o -name '*.dylib' \) \
    -exec cp -a {} "$WHISPER_VENDOR/build/bin/" \; 2>/dev/null || true
if [ -n "$MODELS" ]; then
    cp "$SRC_DIR"/models/ggml-*.bin "$WHISPER_VENDOR/models/"
else
    log "No models bundled — the installer downloads them on the client"
fi
# Mark GPU-flavored payloads so make-dist.sh names the archive accordingly
# (…-gpu-cuda / …-gpu-vulkan) and check-gpu.sh can tell the user the flavor.
case "$GPU" in
    cuda|vulkan) echo "$GPU" > "$WHISPER_VENDOR/GPU_BACKEND";;
esac

# ---------------------------------------------------------------------------
# ffmpeg — build or load (requirement 2). Ship a static LGPL binary.
# ---------------------------------------------------------------------------
stage_ffmpeg_binary() {  # $1 = path to an ffmpeg executable
    mkdir -p "$VENDOR/ffmpeg"
    cp -a "$1" "$VENDOR/ffmpeg/ffmpeg"
    chmod +x "$VENDOR/ffmpeg/ffmpeg"
    if "$VENDOR/ffmpeg/ffmpeg" -version 2>/dev/null | grep -q 'enable-gpl'; then
        log "WARNING: staged ffmpeg is a GPL build — prefer an LGPL build for redistribution"
    fi
    log "Staged ffmpeg -> $VENDOR/ffmpeg/ffmpeg"
}

download_ffmpeg() {
    need curl
    local url tmp
    tmp="$(mktemp -d)"
    if [ "$PLATFORM" = linux ]; then
        url="https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-lgpl.tar.xz"
        log "Downloading LGPL ffmpeg: $url"
        curl -fL "$url" -o "$tmp/ff.tar.xz"
        tar -C "$tmp" -xf "$tmp/ff.tar.xz"
        stage_ffmpeg_binary "$(find "$tmp" -name ffmpeg -type f | head -1)"
    else
        # macOS: no widely-published static LGPL prebuilt. Fall back to building.
        log "No prebuilt LGPL ffmpeg for macOS — building from source instead"
        build_ffmpeg
    fi
    rm -rf "$tmp"
}

build_ffmpeg() {
    need curl; need make
    local tmp ver
    tmp="$(mktemp -d)"; ver="6.1.1"
    log "Building ffmpeg $ver from source (LGPL config)"
    curl -fL "https://ffmpeg.org/releases/ffmpeg-$ver.tar.xz" -o "$tmp/ff.tar.xz"
    tar -C "$tmp" -xf "$tmp/ff.tar.xz"
    ( cd "$tmp/ffmpeg-$ver" && \
        ./configure --disable-gpl --disable-nonfree --enable-static --disable-shared \
                    --disable-doc --disable-network && \
        make -j"$JOBS" )
    stage_ffmpeg_binary "$tmp/ffmpeg-$ver/ffmpeg"
    rm -rf "$tmp"
}

case "$FFMPEG_MODE" in
    download) download_ffmpeg;;
    build)    build_ffmpeg;;
    skip)     log "Skipping ffmpeg (--ffmpeg skip)";;
    *)
        [ -f "$FFMPEG_MODE" ] || die "--ffmpeg: '$FFMPEG_MODE' is not a mode (download|build|skip) or an existing file"
        stage_ffmpeg_binary "$FFMPEG_MODE"
        ;;
esac

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo
log "whisper.cpp vendor payload ready: dist/vendor/$PLATFORM/whisper-$FLAVOR/ (cached flavors: $(cd "$VENDOR" && ls -d whisper-* 2>/dev/null | sed 's/whisper-//' | paste -sd' ' -))"
log "Binaries still dynamically link SDL2 — the installer installs it on the client."
log "Next: dist/make-dist.sh --platform $PLATFORM   (packages every cached flavor; --gpu <flavor> for just one)"
