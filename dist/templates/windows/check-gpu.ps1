<#
    check-gpu.ps1 - is this machine suitable for a GPU-accelerated ScriptScreen
    build (whisper.cpp compiled with CUDA or Vulkan)?

    Run from the unpacked archive BEFORE installing:
        powershell -ExecutionPolicy Bypass -File .\check-gpu.ps1

    Read-only checks, nothing is installed or changed:
      1. NVIDIA GPU + driver present?      -> suitable for a CUDA build
      2. Vulkan runtime present?           -> suitable for a Vulkan build
      3. If the archive's whisper binaries sit next to this script, try to
         actually start one - catches missing runtime DLLs immediately.

    The CPU-only build works on every machine. A GPU build on a machine
    without the matching GPU/driver usually still runs, but on the CPU -
    without any acceleration.
#>
$ErrorActionPreference = 'Continue'

$SrcDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
function Ok($m)   { Write-Host "  [OK] $m" }
function No($m)   { Write-Host "  [--] $m" }
function Warn($m) { Write-Host "  [!!] $m" }

$CudaOk   = $false
$VulkanOk = $false
$BinOk    = $null   # $null = not tested (script not run from the archive)

Write-Host "== GPU suitability check for ScriptScreen (whisper.cpp) =="
Write-Host ""
$Marker = Join-Path $SrcDir 'whisper\GPU_BACKEND'
if (Test-Path $Marker) {
    Write-Host "This archive is a GPU-accelerated build: $((Get-Content $Marker -Raw).Trim())"
    Write-Host ""
}

# ---------------------------------------------------------------------------
# 0. Installed display adapters (informational)
# ---------------------------------------------------------------------------
Write-Host "Display adapters:"
$gpus = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue)
if ($gpus) {
    foreach ($g in $gpus) { Ok "$($g.Name)  (driver $($g.DriverVersion))" }
} else {
    No "could not enumerate display adapters"
}
Write-Host ""

# ---------------------------------------------------------------------------
# 1. CUDA - needs an NVIDIA GPU with its driver installed
# ---------------------------------------------------------------------------
Write-Host "CUDA (NVIDIA):"
$smi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if (-not $smi -and (Test-Path "$env:SystemRoot\System32\nvidia-smi.exe")) {
    $smi = "$env:SystemRoot\System32\nvidia-smi.exe"
}
if ($smi) {
    $info = & $smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>$null
    if ($LASTEXITCODE -eq 0 -and $info) {
        $CudaOk = $true
        foreach ($line in $info) { Ok "$line  (GPU, VRAM, driver)" }
    } else {
        Warn "nvidia-smi exists but failed to run - the NVIDIA driver may be broken"
    }
} elseif (Test-Path "$env:SystemRoot\System32\nvcuda.dll") {
    $CudaOk = $true
    Ok "NVIDIA driver present (nvcuda.dll found)"
} else {
    No "no NVIDIA driver (nvidia-smi / nvcuda.dll not found)"
}
Write-Host ""

# ---------------------------------------------------------------------------
# 2. Vulkan - needs the runtime loader (vulkan-1.dll)
# ---------------------------------------------------------------------------
Write-Host "Vulkan:"
if (Test-Path "$env:SystemRoot\System32\vulkan-1.dll") {
    $VulkanOk = $true
    Ok "Vulkan runtime present (vulkan-1.dll) - GPU drivers normally provide a device"
} else {
    No "no Vulkan runtime (vulkan-1.dll not found)"
}
Write-Host ""

# ---------------------------------------------------------------------------
# 3. Load test of the bundled binary (only when run from the unpacked archive)
# ---------------------------------------------------------------------------
$Bin = Join-Path $SrcDir 'whisper\build\bin\whisper-cli.exe'
if (Test-Path $Bin) {
    Write-Host "Bundled whisper-cli load test:"
    # Suppress the "missing DLL" popup dialog so a failure just returns a code.
    try {
        $sem = Add-Type -Name ErrMode -Namespace ScriptScreenCheck -PassThru -ErrorAction Stop -MemberDefinition `
            '[DllImport("kernel32.dll")] public static extern uint SetErrorMode(uint uMode);'
        [void]$sem::SetErrorMode(0x8003)  # SEM_FAILCRITICALERRORS|NOGPFAULTERRORBOX|NOOPENFILEERRORBOX
    } catch {
        try { [void][ScriptScreenCheck.ErrMode]::SetErrorMode(0x8003) } catch { }
    }
    & $Bin -h > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        $BinOk = $true
        Ok "the bundled whisper-cli.exe starts on this machine"
    } else {
        $BinOk = $false
        Warn "the bundled whisper-cli.exe FAILED to start (exit code $LASTEXITCODE)"
        Warn "a required DLL is probably missing (e.g. the NVIDIA driver for a CUDA build)"
    }
    Write-Host ""
}

# ---------------------------------------------------------------------------
# Verdict
# ---------------------------------------------------------------------------
Write-Host "== Verdict =="
if ($CudaOk)   { Write-Host "  CUDA build:   suitable (NVIDIA GPU + driver detected)" }
else           { Write-Host "  CUDA build:   NOT suitable - NVIDIA driver missing or not working; use the Vulkan or CPU build" }
if ($VulkanOk) { Write-Host "  Vulkan build: suitable (Vulkan runtime detected)" }
else           { Write-Host "  Vulkan build: NOT suitable - no Vulkan runtime; use the CPU build" }
Write-Host "  CPU build:    works everywhere (slower on long recordings)"
if ($BinOk -eq $true)  { Write-Host "  This archive's binaries start on this machine." }
if ($BinOk -eq $false) { Write-Host "  WARNING: this archive's binaries do NOT start here - pick a different build." }
Write-Host ""
Write-Host "Rule of thumb: GPU transcription needs about the model size + 1 GB of"
Write-Host "free VRAM (small ~0.5 GB, medium ~1.5 GB, large-v3 ~3 GB)."

if ($BinOk -eq $false) { exit 1 } else { exit 0 }
