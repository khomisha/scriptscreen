#!/usr/bin/env bash
#
# check-gpu.sh — is this machine suitable for a GPU-accelerated ScriptScreen
# build (whisper.cpp compiled with CUDA or Vulkan)?
#
# Run it from the unpacked archive BEFORE installing:
#   ./check-gpu.sh
#
# Read-only checks, nothing is installed or changed:
#   1. NVIDIA GPU + driver present?      -> suitable for a CUDA build
#   2. Vulkan runtime + device present?  -> suitable for a Vulkan build
#   3. If the archive's whisper binaries sit next to this script, try to
#      actually start one — catches missing runtime libraries immediately.
#
# The CPU-only build works on every machine. A GPU build on a machine without
# the matching GPU/driver usually still runs, but on the CPU — without any
# acceleration.
#
set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ok()   { echo "  [OK] $*"; }
no()   { echo "  [--] $*"; }
warn() { echo "  [!!] $*"; }

CUDA_OK=0
VULKAN_OK=0
BIN_OK=-1   # -1 = not tested (script not run from the archive)

echo "== GPU suitability check for ScriptScreen (whisper.cpp) =="
echo
if [ -f "$DIR/whisper/GPU_BACKEND" ]; then
    echo "This archive is a GPU-accelerated build: $(tr -d '[:space:]' < "$DIR/whisper/GPU_BACKEND")"
    echo
fi

# ---------------------------------------------------------------------------
# 1. CUDA — needs an NVIDIA GPU with its driver installed
# ---------------------------------------------------------------------------
echo "CUDA (NVIDIA):"
if command -v nvidia-smi >/dev/null 2>&1; then
    if info="$(nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>/dev/null)" \
       && [ -n "$info" ]; then
        CUDA_OK=1
        while IFS= read -r line; do ok "$line  (GPU, VRAM, driver)"; done <<<"$info"
    else
        warn "nvidia-smi exists but failed to run — the NVIDIA driver may be broken"
    fi
else
    no "no nvidia-smi (NVIDIA driver not installed)"
fi
echo

# ---------------------------------------------------------------------------
# 2. Vulkan — needs the loader (libvulkan) and at least one Vulkan device
# ---------------------------------------------------------------------------
echo "Vulkan:"
if command -v vulkaninfo >/dev/null 2>&1; then
    devs="$(vulkaninfo --summary 2>/dev/null | grep -i 'deviceName' | sed 's/^[[:space:]]*//' | sort -u)"
    if [ -n "$devs" ]; then
        VULKAN_OK=1
        while IFS= read -r line; do ok "$line"; done <<<"$devs"
    else
        no "vulkaninfo found no Vulkan devices"
    fi
elif ldconfig -p 2>/dev/null | grep -q 'libvulkan\.so\.1'; then
    VULKAN_OK=1
    ok "Vulkan loader (libvulkan.so.1) is installed"
    no "vulkaninfo not found, so devices cannot be listed — install 'vulkan-tools' to double-check"
else
    no "no Vulkan loader (libvulkan.so.1)"
fi
echo

# ---------------------------------------------------------------------------
# 3. Load test of the bundled binary (only when run from the unpacked archive)
# ---------------------------------------------------------------------------
BIN="$DIR/whisper/build/bin/whisper-cli"
if [ -x "$BIN" ]; then
    echo "Bundled whisper-cli load test:"
    if err="$("$BIN" -h 2>&1 >/dev/null)"; then
        BIN_OK=1
        ok "the bundled whisper-cli starts on this machine"
    else
        BIN_OK=0
        warn "the bundled whisper-cli FAILED to start:"
        echo "$err" | head -5 | sed 's/^/       /'
        missing="$(ldd "$BIN" 2>/dev/null | grep 'not found')"
        if [ -n "$missing" ]; then
            warn "missing libraries:"
            echo "$missing" | sed 's/^/       /'
        fi
    fi
    echo
fi

# ---------------------------------------------------------------------------
# Verdict
# ---------------------------------------------------------------------------
echo "== Verdict =="
if [ "$CUDA_OK" -eq 1 ]; then echo "  CUDA build:   suitable (NVIDIA GPU + driver detected)"
else                          echo "  CUDA build:   NOT suitable — NVIDIA driver missing or not working; use the Vulkan or CPU build"
fi
if [ "$VULKAN_OK" -eq 1 ]; then echo "  Vulkan build: suitable (Vulkan runtime detected)"
else                            echo "  Vulkan build: NOT suitable — no Vulkan runtime; use the CPU build"
fi
echo "  CPU build:    works everywhere (slower on long recordings)"
case "$BIN_OK" in
    1)  echo "  This archive's binaries start on this machine.";;
    0)  echo "  WARNING: this archive's binaries do NOT start here — pick a different build.";;
esac
echo
echo "Rule of thumb: GPU transcription needs about the model size + 1 GB of"
echo "free VRAM (small ~0.5 GB, medium ~1.5 GB, large-v3 ~3 GB)."

[ "$BIN_OK" -ne 0 ]   # exit 1 only if the bundled binary failed to start
