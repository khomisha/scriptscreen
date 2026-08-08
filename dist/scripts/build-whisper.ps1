<#
    build-whisper.ps1 - build whisper.cpp (+ SDL2 for live transcription) and
    provide ffmpeg, then stage everything into dist\vendor\windows\ ready
    for make-dist.sh.

    Produces the layout make-dist.sh expects, cached per GPU flavor so several
    flavors coexist - an app-only release never rebuilds whisper:
      dist\vendor\windows\whisper-<flavor>\build\bin\whisper-cli.exe    (flavor: cpu|vulkan|cuda)
      dist\vendor\windows\whisper-<flavor>\build\bin\whisper-stream.exe
      dist\vendor\windows\whisper-<flavor>\build\bin\*.dll   (SDL2.dll + any runtime DLLs)
      dist\vendor\windows\whisper-<flavor>\models\           (empty by default)
      dist\vendor\windows\ffmpeg\ffmpeg.exe
    A legacy single-slot dist\vendor\windows\whisper payload is migrated to its
    flavored name automatically on the next run.

    Speech models are NOT bundled by default - they are large, and install.ps1
    downloads the needed ones on the client machine. Pass -Models to pre-bundle
    models anyway (e.g. for offline installs).

    On Windows the default whisper.cpp build links shared libraries, so SDL2.dll
    (and ggml*.dll / whisper.dll) are shipped inside the archive next to the
    .exe files - the client does not install SDL2 separately.

    Run from the "x64 Native Tools Command Prompt for VS 2022" (so MSVC is on
    PATH), e.g.:
      powershell -ExecutionPolicy Bypass -File dist\scripts\build-whisper.ps1 `
        -Vcpkg C:\path\to\vcpkg

    Parameters:
      -Models  "small large-v3-turbo"   Models to download and bundle (default: none).
      -Src     <dir>                     whisper.cpp checkout (default: build\whisper.cpp).
      -Vcpkg   <dir>                     vcpkg root providing SDL2 (required unless
                                         -SkipSdl2). e.g. C:\vcpkg
      -Ffmpeg  download|skip|<path>      Provide ffmpeg.exe (default: download LGPL).
      -Gpu     cuda|vulkan|none          GPU backend (default: none = widest CPU
                                         build; cuda needs the CUDA Toolkit,
                                         vulkan needs the Vulkan SDK).
                                         cuda/vulkan write a GPU_BACKEND marker into
                                         the vendor payload, and make-dist.sh then
                                         names the archive ...-windows-gpu-<backend>.
                                         'cpu' is accepted as an alias for 'none'.
      -SkipSdl2                          Build whisper-cli only (no live transcription).
      -Log     <file>                    Log file path
                                         (default: dist\out\build-whisper-windows.log).
      -NoLog                             Do not write a log file.
#>
[CmdletBinding()]
param(
    [string]$Models = "",
    [string]$Src    = "",
    [string]$Vcpkg  = "",
    [string]$Ffmpeg = "download",
    [ValidateSet('cuda','vulkan','none','cpu')]
    [string]$Gpu    = "none",
    [switch]$SkipSdl2,
    [string]$Log    = "",
    [switch]$NoLog
)
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $RepoRoot
$Platform = 'windows'
$Vendor   = Join-Path $RepoRoot "dist\vendor\$Platform"
if (-not $Src) { $Src = Join-Path $RepoRoot 'build\whisper.cpp' }

# --- logging (on by default; -Log overrides the path, -NoLog disables) -----
$LogPath = $null
if (-not $NoLog) {
    if ([string]::IsNullOrWhiteSpace($Log)) { $Log = Join-Path $RepoRoot 'dist\out\build-whisper-windows.log' }
    $LogPath = $Log
    New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) | Out-Null
    Start-Transcript -Path $LogPath -Append | Out-Null
}

function Log($m) { Write-Host "==> $m" }
# Write-Host, not Write-Error: with $ErrorActionPreference = 'Stop' the latter
# throws immediately and the exit/Stop-Transcript below would never run.
function Die($m) { Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }
function Have($c) { return [bool](Get-Command $c -ErrorAction SilentlyContinue) }

try {
    if ($Gpu -eq 'cpu') { $Gpu = 'none' }   # 'cpu' = alias for 'none'
    $ModelList = @($Models -split '\s+' | Where-Object { $_ })
    Log "Building whisper.cpp for windows (models: $(if ($ModelList) { $Models } else { 'none' }), gpu: $Gpu, ffmpeg: $Ffmpeg, sdl2: $([bool](-not $SkipSdl2)))"

    if (-not (Have 'git'))   { Die "git not found on PATH" }
    if (-not (Have 'cmake')) { Die "cmake not found on PATH (install VS 2022 'Desktop development with C++')" }
    switch ($Gpu) {
        'cuda'   { if (-not (Have 'nvcc'))  { Die "-Gpu cuda requires the CUDA Toolkit (nvcc not found). Install it from https://developer.nvidia.com/cuda-downloads or use -Gpu vulkan (works on NVIDIA/AMD/Intel, no toolkit needed)." } }
        'vulkan' { if (-not (Have 'glslc')) { Die "-Gpu vulkan requires the Vulkan SDK (glslc not found). Install it from https://vulkan.lunarg.com/sdk/home and re-open the shell." } }
    }

    # --- SDL2 via vcpkg ----------------------------------------------------
    $toolchain = $null
    if (-not $SkipSdl2) {
        if (-not $Vcpkg) { Die "SDL2 is required for whisper-stream. Pass -Vcpkg C:\path\to\vcpkg (or -SkipSdl2)." }
        $toolchain = Join-Path $Vcpkg 'scripts\buildsystems\vcpkg.cmake'
        if (-not (Test-Path $toolchain)) { Die "vcpkg toolchain not found at $toolchain" }
        $vcpkgExe = Join-Path $Vcpkg 'vcpkg.exe'
        if (-not (Test-Path $vcpkgExe)) { Die "vcpkg.exe not found in $Vcpkg - run bootstrap-vcpkg.bat first" }
        Log "Ensuring SDL2 is installed via vcpkg"
        & $vcpkgExe install sdl2:x64-windows
        if ($LASTEXITCODE -ne 0) { Die "vcpkg install sdl2 failed" }
    }

    # --- clone + build -----------------------------------------------------
    if (Test-Path (Join-Path $Src '.git')) {
        Log "Updating whisper.cpp checkout in $Src"
        git -C $Src pull --ff-only
    } else {
        Log "Cloning whisper.cpp into $Src"
        New-Item -ItemType Directory -Force -Path (Split-Path $Src) | Out-Null
        git clone --depth 1 https://github.com/ggml-org/whisper.cpp $Src
    }

    $cmakeArgs = @('-S', $Src, '-B', (Join-Path $Src 'build'))
    if (-not $SkipSdl2) {
        $cmakeArgs += @('-DWHISPER_SDL2=ON', "-DCMAKE_TOOLCHAIN_FILE=$toolchain")
    }
    # Always pass both backend flags explicitly (ON or OFF): CMake caches them
    # in an existing build dir, so a previous -Gpu run would otherwise leak
    # into this one via CMakeCache.txt.
    switch ($Gpu) {
        'cuda'   { $cmakeArgs += @('-DGGML_CUDA=ON',  '-DGGML_VULKAN=OFF', '-DCMAKE_CUDA_ARCHITECTURES=61;70;75;80;86;89;90') }
        'vulkan' { $cmakeArgs += @('-DGGML_VULKAN=ON', '-DGGML_CUDA=OFF') }
        'none'   { $cmakeArgs += @('-DGGML_CUDA=OFF', '-DGGML_VULKAN=OFF') }
    }
    Log "Configuring whisper.cpp"
    cmake @cmakeArgs
    if ($LASTEXITCODE -ne 0) { Die "cmake configure failed" }
    Log "Building whisper.cpp (Release)"
    cmake --build (Join-Path $Src 'build') --config Release -j
    if ($LASTEXITCODE -ne 0) { Die "cmake build failed" }

    # MSVC multi-config puts binaries under build\bin\Release
    $binOut = Join-Path $Src 'build\bin\Release'
    if (-not (Test-Path $binOut)) { $binOut = Join-Path $Src 'build\bin' }
    if (-not (Test-Path (Join-Path $binOut 'whisper-cli.exe'))) { Die "whisper-cli.exe not built (looked in $binOut)" }

    # --- models (only if explicitly requested via -Models; normally the
    #     installer downloads them on the client machine instead) -----------
    foreach ($m in $ModelList) {
        Log "Downloading model: $m"
        Push-Location $Src
        try { & cmd /c "models\download-ggml-model.cmd $m" } finally { Pop-Location }
    }
    $turbo = Join-Path $Src 'models\ggml-large-v3-turbo.bin'
    $turboDst = Join-Path $Src 'models\ggml-turbo.bin'
    if ((Test-Path $turbo) -and -not (Test-Path $turboDst)) { Copy-Item $turbo $turboDst }

    # --- stage whisper\ (cached per GPU flavor, side by side) --------------
    $Flavor = if ($Gpu -eq 'cuda' -or $Gpu -eq 'vulkan') { $Gpu } else { 'cpu' }
    $wDst = Join-Path $Vendor "whisper-$Flavor"
    # Migrate a legacy single-slot whisper\ payload: keep it under its flavored
    # name if that flavor is not cached yet, otherwise drop it (superseded).
    $legacy = Join-Path $Vendor 'whisper'
    if (Test-Path $legacy) {
        $legacyMarker = Join-Path $legacy 'GPU_BACKEND'
        $legacyFlavor = if (Test-Path $legacyMarker) { (Get-Content $legacyMarker -Raw).Trim() } else { 'cpu' }
        $legacyDst = Join-Path $Vendor "whisper-$legacyFlavor"
        if (($legacyFlavor -ne $Flavor) -and -not (Test-Path $legacyDst)) {
            Log "Migrating legacy vendor payload -> whisper-$legacyFlavor"
            Move-Item $legacy $legacyDst
        } else {
            Log "Removing superseded legacy vendor payload whisper\"
            Remove-Item -Recurse -Force $legacy
        }
    }
    Log "Staging whisper -> $wDst"
    if (Test-Path $wDst) { Remove-Item -Recurse -Force $wDst }
    New-Item -ItemType Directory -Force -Path (Join-Path $wDst 'build\bin') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $wDst 'models')    | Out-Null
    # .exe + all runtime DLLs (ggml*.dll, whisper.dll) flatten into build\bin
    Copy-Item (Join-Path $binOut '*.exe') (Join-Path $wDst 'build\bin') -Force
    Copy-Item (Join-Path $binOut '*.dll') (Join-Path $wDst 'build\bin') -Force -ErrorAction SilentlyContinue
    if (-not $SkipSdl2) {
        $sdlDll = Join-Path $Vcpkg 'installed\x64-windows\bin\SDL2.dll'
        if (Test-Path $sdlDll) { Copy-Item $sdlDll (Join-Path $wDst 'build\bin') -Force }
        else { Log "WARNING: SDL2.dll not found in vcpkg output - copy it into whisper\build\bin manually" }
    }
    if ($ModelList) {
        Copy-Item (Join-Path $Src 'models\ggml-*.bin') (Join-Path $wDst 'models') -Force
    } else {
        Log "No models bundled - install.ps1 downloads them on the client"
    }
    # Mark GPU-flavored payloads so make-dist.sh names the archive accordingly
    # (...-gpu-cuda / ...-gpu-vulkan) and check-gpu.ps1 can tell the user the flavor.
    if ($Gpu -ne 'none') {
        Set-Content -Path (Join-Path $wDst 'GPU_BACKEND') -Value $Gpu -NoNewline -Encoding ASCII
    }

    # --- ffmpeg (requirement 2) -------------------------------------------
    switch -Regex ($Ffmpeg) {
        '^skip$' { Log "Skipping ffmpeg (-Ffmpeg skip)" }
        '^download$' {
            $tmp = Join-Path $env:TEMP ("ff_" + [guid]::NewGuid())
            New-Item -ItemType Directory -Force -Path $tmp | Out-Null
            $url = 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-lgpl.zip'
            Log "Downloading LGPL ffmpeg: $url"
            $zip = Join-Path $tmp 'ff.zip'
            Invoke-WebRequest -Uri $url -OutFile $zip
            Expand-Archive -Path $zip -DestinationPath $tmp -Force
            $exe = Get-ChildItem -Path $tmp -Recurse -Filter 'ffmpeg.exe' | Select-Object -First 1
            if (-not $exe) { Die "ffmpeg.exe not found in downloaded archive" }
            New-Item -ItemType Directory -Force -Path (Join-Path $Vendor 'ffmpeg') | Out-Null
            Copy-Item $exe.FullName (Join-Path $Vendor 'ffmpeg\ffmpeg.exe') -Force
            Remove-Item -Recurse -Force $tmp
            Log "Staged ffmpeg -> $Vendor\ffmpeg\ffmpeg.exe"
        }
        default {
            if (-not (Test-Path $Ffmpeg)) { Die "-Ffmpeg: '$Ffmpeg' is not a mode (download|skip) or an existing file" }
            New-Item -ItemType Directory -Force -Path (Join-Path $Vendor 'ffmpeg') | Out-Null
            Copy-Item $Ffmpeg (Join-Path $Vendor 'ffmpeg\ffmpeg.exe') -Force
            Log "Staged ffmpeg -> $Vendor\ffmpeg\ffmpeg.exe"
        }
    }

    Write-Host ""
    Log "whisper.cpp vendor payload ready: dist\vendor\windows\whisper-$Flavor\"
    Log "SDL2.dll and runtime DLLs are bundled next to the .exe (no client SDL2 install needed)."
    Log "Next: bash dist/make-dist.sh --platform windows   (run from Git Bash - it is a bash script, PowerShell/cmd cannot run it; packages every cached flavor, --gpu <flavor> for just one)"
    if ($LogPath) { Log "Log written to $LogPath" }
}
finally {
    if ($LogPath) { try { Stop-Transcript | Out-Null } catch {} }
}
